#!/usr/bin/env python3
"""プロンプト検索サーバ (SQLite FTS5 + 標準ライブラリだけ)。

    python server.py [--db prompts.db] [--host 127.0.0.1] [--port 8700]

ブラウザ: http://127.0.0.1:8700/
API (すべて GET, JSON, CORS 許可):
    /api/search?q=<query>&limit=50&offset=0&order=rank|id|random
    /api/prompt/<id>
    /api/random?n=10[&q=<query>]
    /api/stats
    /api/export?q=<query>&format=txt|csv|json      (該当全件をダウンロード)

クエリ構文 (空白区切りは AND):
    clown portrait        両方を含む
    "evil clown"          連続した語句
    clown OR jester       どちらか
    clown -makeup         makeup を含まない
    cyber*                前方一致
"""
import argparse
import csv
import html
import io
import json
import os
import re
import sqlite3
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
MAX_LIMIT = 500
HL_OPEN, HL_CLOSE = "\x01", "\x02"

# ---------------------------------------------------------------- query parse
_TOKEN_RE = re.compile(r'"([^"]*)"\*?|(\S+)')


def to_fts_query(user_q: str) -> str:
    """ユーザー入力を安全な FTS5 式に変換する。空文字なら空文字を返す。"""
    positives, negatives = [], []
    pending_or = False

    def term(text, prefix=False):
        text = text.replace('"', '""')
        return f'"{text}"' + ("*" if prefix else "")

    for m in _TOKEN_RE.finditer(user_q.strip()):
        phrase, word = m.group(1), m.group(2)
        if word is not None:
            if word.upper() == "OR":
                pending_or = True
                continue
            if word.upper() in ("AND", "NOT"):
                continue
            neg = word.startswith("-") and len(word) > 1
            if neg:
                word = word[1:]
            prefix = word.endswith("*") and len(word) > 1
            if prefix:
                word = word[:-1]
            # 記号を除いて何も残らない語は無視
            if not re.search(r"\w", word):
                continue
            t = term(word, prefix)
        else:
            if not re.search(r"\w", phrase):
                continue
            t = term(phrase)
            neg = False
        if neg:
            negatives.append(t)
            continue
        if pending_or and positives:
            positives[-1] = f"{positives[-1]} OR {t}"
        else:
            positives.append(t)
        pending_or = False

    if not positives:
        return ""  # 否定だけの検索は未対応 (全件走査になる)
    expr = " AND ".join(f"({p})" if " OR " in p else p for p in positives)
    for n in negatives:
        expr = f"({expr}) NOT {n}"
    return expr


# ---------------------------------------------------------------- database
class DB:
    def __init__(self, path):
        self.path = os.path.abspath(path)
        if not os.path.exists(self.path):
            sys.exit(f"DB が無い: {self.path}\n先に build_db.py を実行してください")
        self._local = threading.local()
        con = self.con()
        self.total = con.execute("SELECT count(*) FROM prompts").fetchone()[0]
        self.max_id = con.execute("SELECT max(id) FROM prompts").fetchone()[0] or 0
        self.avg_words = con.execute("SELECT avg(nwords) FROM prompts").fetchone()[0] or 0

    def con(self):
        c = getattr(self._local, "con", None)
        if c is None:
            c = sqlite3.connect(f"file:{self.path}?mode=ro", uri=True, check_same_thread=False)
            c.execute("PRAGMA cache_size = -65536")
            self._local.con = c
        return c

    @staticmethod
    def _row(r):
        pid, prompt, hl = r
        if hl is None:
            hl = prompt
        return {
            "id": pid,
            "prompt": prompt,
            "html": html.escape(hl).replace(HL_OPEN, "<mark>").replace(HL_CLOSE, "</mark>"),
        }

    def search(self, q, limit, offset, order):
        t0 = time.perf_counter()
        con = self.con()
        fts = to_fts_query(q)
        if not fts:
            total = self.total
            ob = {"random": "RANDOM()", "rank": "id", "id": "id"}[order]
            rows = con.execute(
                f"SELECT id, prompt, NULL FROM prompts ORDER BY {ob} LIMIT ? OFFSET ?",
                (limit, offset),
            ).fetchall()
        else:
            total = con.execute(
                "SELECT count(*) FROM prompts_fts WHERE prompts_fts MATCH ?", (fts,)
            ).fetchone()[0]
            ob = {"random": "RANDOM()", "rank": "rank", "id": "rowid"}[order]
            rows = con.execute(
                f"SELECT rowid, prompt, highlight(prompts_fts, 0, ?, ?) "
                f"FROM prompts_fts WHERE prompts_fts MATCH ? ORDER BY {ob} LIMIT ? OFFSET ?",
                (HL_OPEN, HL_CLOSE, fts, limit, offset),
            ).fetchall()
        return {
            "query": q,
            "fts": fts,
            "total": total,
            "limit": limit,
            "offset": offset,
            "order": order,
            "ms": round((time.perf_counter() - t0) * 1000, 2),
            "hits": [self._row(r) for r in rows],
        }

    def iter_all(self, q):
        """export 用: 該当全件を id 順に返す"""
        con = self.con()
        fts = to_fts_query(q)
        if not fts:
            cur = con.execute("SELECT id, prompt FROM prompts ORDER BY id")
        else:
            cur = con.execute(
                "SELECT rowid, prompt FROM prompts_fts WHERE prompts_fts MATCH ? ORDER BY rowid", (fts,)
            )
        yield from cur

    def get(self, pid):
        r = self.con().execute("SELECT id, prompt, NULL FROM prompts WHERE id = ?", (pid,)).fetchone()
        return self._row(r) if r else None

    def stats(self):
        return {
            "prompts": self.total,
            "max_id": self.max_id,
            "avg_words": round(self.avg_words, 1),
            "db_bytes": os.path.getsize(self.path),
            "db": self.path,
        }


# ---------------------------------------------------------------- http
class Handler(BaseHTTPRequestHandler):
    db: DB = None  # main() で設定
    server_version = "promptdb/1.0"

    def log_message(self, fmt, *args):
        if self.server.verbose:
            sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _send(self, code, body, ctype="application/json; charset=utf-8", extra=None):
        if isinstance(body, (dict, list)):
            body = json.dumps(body, ensure_ascii=False).encode("utf-8")
        elif isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def _err(self, code, msg):
        self._send(code, {"error": msg})

    def do_GET(self):
        u = urlparse(self.path)
        qs = {k: v[-1] for k, v in parse_qs(u.query).items()}
        path = u.path.rstrip("/") or "/"
        try:
            if path == "/":
                return self._send(200, INDEX_HTML, "text/html; charset=utf-8")
            if path == "/api/search":
                return self._search(qs)
            if path == "/api/random":
                n = clamp_int(qs.get("n"), 10, 1, MAX_LIMIT)
                return self._send(200, self.db.search(qs.get("q", ""), n, 0, "random"))
            if path.startswith("/api/prompt/"):
                try:
                    pid = int(path.rsplit("/", 1)[1])
                except ValueError:
                    return self._err(400, "id は整数")
                r = self.db.get(pid)
                return self._send(200, r) if r else self._err(404, "not found")
            if path == "/api/stats":
                return self._send(200, self.db.stats())
            if path == "/api/export":
                return self._export(qs)
            return self._err(404, "not found")
        except sqlite3.OperationalError as e:
            return self._err(400, f"検索式エラー: {e}")

    def _search(self, qs):
        q = qs.get("q", "")
        limit = clamp_int(qs.get("limit"), 50, 1, MAX_LIMIT)
        offset = clamp_int(qs.get("offset"), 0, 0, 10**9)
        order = qs.get("order", "rank")
        if order not in ("rank", "id", "random"):
            return self._err(400, "order は rank | id | random")
        self._send(200, self.db.search(q, limit, offset, order))

    def _export(self, qs):
        q = qs.get("q", "")
        fmt = qs.get("format", "txt")
        rows = self.db.iter_all(q)
        name = "prompts_" + (re.sub(r"[^\w]+", "_", q).strip("_") or "all")
        if fmt == "json":
            body = json.dumps([{"id": i, "prompt": p} for i, p in rows], ensure_ascii=False)
            ctype, ext = "application/json; charset=utf-8", "json"
        elif fmt == "csv":
            buf = io.StringIO()
            w = csv.writer(buf, lineterminator="\n")
            w.writerow(["id", "prompt"])
            w.writerows(rows)
            body = "﻿" + buf.getvalue()  # Excel 用 BOM
            ctype, ext = "text/csv; charset=utf-8", "csv"
        elif fmt == "txt":
            body = "\n".join(p for _, p in rows) + "\n"
            ctype, ext = "text/plain; charset=utf-8", "txt"
        else:
            return self._err(400, "format は txt | csv | json")
        self._send(200, body, ctype, {"Content-Disposition": f'attachment; filename="{name}.{ext}"'})


def clamp_int(v, default, lo, hi):
    try:
        n = int(v)
    except (TypeError, ValueError):
        return default
    return max(lo, min(hi, n))


# ---------------------------------------------------------------- UI
INDEX_HTML = r"""<!doctype html>
<html lang="ja"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>promptdb</title>
<style>
:root{--bg:#0f1115;--fg:#e6e6e6;--mut:#8a90a0;--acc:#6ea8fe;--card:#171a21;--bd:#262b36;--mark:#5a4a00}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
header{position:sticky;top:0;background:var(--bg);padding:14px 16px 10px;border-bottom:1px solid var(--bd);z-index:1}
.row{display:flex;gap:8px;align-items:center;max-width:1100px;margin:0 auto;flex-wrap:wrap}
input[type=search]{flex:1;min-width:240px;font-size:17px;padding:10px 14px;border-radius:10px;border:1px solid var(--bd);background:var(--card);color:var(--fg);outline:none}
input[type=search]:focus{border-color:var(--acc)}
select,button{font-size:14px;padding:8px 12px;border-radius:8px;border:1px solid var(--bd);background:var(--card);color:var(--fg);cursor:pointer}
button:hover{border-color:var(--acc)}
.meta{color:var(--mut);font-size:13px;margin-top:6px;max-width:1100px;margin-left:auto;margin-right:auto;display:flex;gap:14px;flex-wrap:wrap}
.meta code{color:var(--fg);background:var(--card);padding:1px 6px;border-radius:5px}
main{max-width:1100px;margin:0 auto;padding:12px 16px 60px}
.hit{background:var(--card);border:1px solid var(--bd);border-radius:10px;padding:10px 14px;margin:8px 0;display:flex;gap:12px;align-items:flex-start}
.hit .id{color:var(--mut);font-size:12px;min-width:52px;padding-top:3px;font-variant-numeric:tabular-nums}
.hit .txt{flex:1;word-break:break-word;white-space:pre-wrap}
.hit button{padding:4px 10px;font-size:12px;flex:none}
mark{background:var(--mark);color:#ffe98a;border-radius:3px;padding:0 2px}
.pager{display:flex;gap:8px;justify-content:center;margin:18px 0;align-items:center;color:var(--mut)}
.help{color:var(--mut);font-size:13px;margin-top:10px;line-height:1.9}
.help b{color:var(--fg);font-weight:600}
.empty{color:var(--mut);text-align:center;padding:40px}
.err{color:#ff8080}
</style></head><body>
<header>
 <div class="row">
  <input id="q" type="search" placeholder="キーワード (例: clown portrait / &quot;evil clown&quot; / clown OR jester / clown -makeup / cyber*)" autofocus autocomplete="off">
  <select id="order"><option value="rank">関連度順</option><option value="id">ID 順</option><option value="random">ランダム</option></select>
  <select id="limit"><option>20</option><option selected>50</option><option>100</option><option>200</option></select>
  <button id="rnd" title="ランダムに表示">&#127922;</button>
  <button id="exp" title="該当全件を txt でダウンロード">&#11015; txt</button>
  <button id="expcsv" title="該当全件を csv でダウンロード">&#11015; csv</button>
 </div>
 <div class="meta"><span id="stat">…</span><span id="fts"></span></div>
</header>
<main>
 <div id="out"></div>
 <div class="pager" id="pager"></div>
 <div class="help">
  <b>構文</b>: 空白区切り = AND ／ <code>"..."</code> = 連続した語句 ／ <code>A OR B</code> ／ <code>-語</code> = 除外 ／ <code>語*</code> = 前方一致。
  語尾の違い (clown / clowns) は自動で同一視します。<br>
  <b>API</b>: <code>/api/search?q=clown&amp;limit=50&amp;offset=0&amp;order=rank</code> ・ <code>/api/random?n=10&amp;q=…</code> ・ <code>/api/prompt/123</code> ・ <code>/api/stats</code> ・ <code>/api/export?q=…&amp;format=txt|csv|json</code>
 </div>
</main>
<script>
const $=s=>document.querySelector(s);
const q=$('#q'),order=$('#order'),limit=$('#limit'),out=$('#out'),pager=$('#pager'),stat=$('#stat'),ftsEl=$('#fts');
let offset=0,total=0,timer=null,abort=null;
let STATS={prompts:0};
function esc(s){return s.replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]))}
function params(){return new URLSearchParams({q:q.value,limit:limit.value,offset:String(offset),order:order.value}).toString()}
async function run(reset){
  if(reset)offset=0;
  if(abort)abort.abort();abort=new AbortController();
  const t0=performance.now();
  let r;
  try{r=await (await fetch('/api/search?'+params(),{signal:abort.signal})).json();}
  catch(e){if(e.name==='AbortError')return;out.innerHTML='<div class="empty err">'+esc(String(e))+'</div>';return}
  if(r.error){out.innerHTML='<div class="empty err">'+esc(r.error)+'</div>';pager.innerHTML='';return}
  total=r.total;
  stat.innerHTML=total.toLocaleString()+' 件 / '+STATS.prompts.toLocaleString()+' 件中 ・ DB '+r.ms+' ms ・ 往復 '+(performance.now()-t0).toFixed(0)+' ms';
  ftsEl.innerHTML=r.fts?'FTS5: <code>'+esc(r.fts)+'</code>':'';
  if(!r.hits.length){out.innerHTML='<div class="empty">該当なし</div>';pager.innerHTML='';return}
  out.innerHTML=r.hits.map(h=>'<div class="hit"><div class="id">#'+h.id+'</div><div class="txt">'+h.html+'</div><button data-p="'+esc(h.prompt)+'">copy</button></div>').join('');
  const n=r.limit,pages=Math.ceil(total/n),cur=Math.floor(offset/n)+1;
  pager.innerHTML=pages>1?'<button id="pv" '+(cur<=1?'disabled':'')+'>&lsaquo; 前</button><span>'+cur+' / '+pages.toLocaleString()+'</span><button id="nx" '+(cur>=pages?'disabled':'')+'>次 &rsaquo;</button>':'';
  const pv=$('#pv'),nx=$('#nx');
  if(pv)pv.addEventListener('click',()=>{offset=Math.max(0,offset-n);run();scrollTo(0,0)});
  if(nx)nx.addEventListener('click',()=>{offset+=n;run();scrollTo(0,0)});
  history.replaceState(null,'','?'+new URLSearchParams({q:q.value}).toString());
}
out.addEventListener('click',e=>{const b=e.target.closest('button[data-p]');if(!b)return;navigator.clipboard.writeText(b.dataset.p);b.textContent='copied';setTimeout(()=>b.textContent='copy',900)});
q.addEventListener('input',()=>{clearTimeout(timer);timer=setTimeout(()=>run(true),150)});
q.addEventListener('keydown',e=>{if(e.key==='Enter'){clearTimeout(timer);run(true)}});
order.addEventListener('change',()=>run(true));limit.addEventListener('change',()=>run(true));
$('#rnd').addEventListener('click',()=>{order.value='random';run(true)});
$('#exp').addEventListener('click',()=>location.href='/api/export?'+new URLSearchParams({q:q.value,format:'txt'}));
$('#expcsv').addEventListener('click',()=>location.href='/api/export?'+new URLSearchParams({q:q.value,format:'csv'}));
fetch('/api/stats').then(r=>r.json()).then(s=>{STATS=s;const u=new URLSearchParams(location.search);if(u.get('q'))q.value=u.get('q');run(true)});
</script></body></html>
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--db", default=os.path.join(HERE, "prompts.db"))
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8700)
    ap.add_argument("-v", "--verbose", action="store_true", help="アクセスログを出す")
    a = ap.parse_args()

    Handler.db = DB(a.db)
    srv = ThreadingHTTPServer((a.host, a.port), Handler)
    srv.daemon_threads = True
    srv.verbose = a.verbose
    print(f"promptdb: {Handler.db.total} prompts  ->  http://{a.host}:{a.port}/   (Ctrl+C で停止)", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
