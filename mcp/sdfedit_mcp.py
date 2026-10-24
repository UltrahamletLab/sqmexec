#!/usr/bin/env python3
"""sdfmodeler MCP サーバ (stdio, 標準ライブラリのみ)。

Blender MCP と同じ構成: AI クライアント ⇄ このサーバ ⇄ serve.py (/__bridge__/*) ⇄
ブラウザで開いている sdfmodeler。エディタを開いたままプロンプトから操作できる。

前提: .\\serve.ps1 でエディタを起動し、ブラウザで開いておく。
環境変数 SDFEDIT_URL で接続先を変更 (既定 http://localhost:8642)。
"""
import base64
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE = os.environ.get("SDFEDIT_URL", "http://localhost:8642").rstrip("/")


def http(method, path, body=None, ctype="application/json", timeout=120):
    data = body if isinstance(body, bytes) else (
        json.dumps(body).encode("utf-8") if body is not None else None)
    req = urllib.request.Request(BASE + path, data=data, method=method,
                                 headers={"Content-Type": ctype})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read(), r.headers.get("Content-Type", "")
    except urllib.error.HTTPError as e:
        return e.read(), e.headers.get("Content-Type", "")
    except urllib.error.URLError as e:
        raise RuntimeError(f"serve.py に接続できません ({BASE}): {e.reason}。.\\serve.ps1 を起動してください")


def bridge(cmd, args=None, timeout=60):
    raw, _ = http("POST", "/__bridge__/cmd",
                  {"cmd": cmd, "args": args or {}, "timeout": timeout}, timeout=timeout + 10)
    res = json.loads(raw)
    if not res.get("ok"):
        raise RuntimeError(res.get("error", "failed"))
    return res


def text(s):
    return [{"type": "text", "text": s}]


def image(png_bytes):
    return [{"type": "image", "data": base64.b64encode(png_bytes).decode(), "mimeType": "image/png"}]


def t_status(a):
    raw, _ = http("GET", "/__bridge__/status")
    return text(raw.decode())


def t_get_scene(a):
    return text(bridge("get_scene")["ssq"])


def t_set_scene(a):
    r = bridge("set_scene", {"ssq": a["ssq"]})
    return text("OK: " + r.get("status", ""))


def t_get_doc(a):
    return text(json.dumps(bridge("get_doc")["doc"], ensure_ascii=False, indent=1))


def t_undo(a):
    bridge("undo")
    return text("undo")


def t_redo(a):
    bridge("redo")
    return text("redo")


def t_screenshot(a):
    return image(base64.b64decode(bridge("screenshot", timeout=90)["png_base64"]))


def t_render(a):
    ssq = bridge("get_scene")["ssq"]
    q = "hq" if a.get("quality") == "hq" else "draft"
    qs = urllib.parse.urlencode({"w": int(a.get("width", 640)), "h": int(a.get("height", 420)), "q": q})
    raw, ct = http("POST", "/__render__?" + qs, ssq.encode("utf-8"), "text/plain", timeout=600)
    if "image" not in ct:
        try:
            msg = json.loads(raw).get("error", "")
        except ValueError:
            msg = raw.decode(errors="replace")[:500]
        raise RuntimeError(msg)
    return image(raw)


def t_list_examples(a):
    raw, _ = http("GET", "/__examples__")
    return text("\n".join(json.loads(raw)))


def t_load_example(a):
    name = os.path.basename(a["name"])
    if not name.endswith(".ssq"):
        name += ".ssq"
    raw, _ = http("GET", "/examples/" + urllib.parse.quote(name))
    r = bridge("set_scene", {"ssq": raw.decode("utf-8")})
    return text(f"loaded {name}: " + r.get("status", ""))


def t_save_example(a):
    ssq = bridge("get_scene")["ssq"]
    raw, _ = http("POST", "/__save__?name=" + urllib.parse.quote(a["name"]), ssq.encode("utf-8"), "text/plain")
    return text(raw.decode())


def t_eval(a):
    return text(json.dumps(bridge("eval", {"code": a["code"]})["value"], ensure_ascii=False))


def S(props, req=()):
    return {"type": "object", "properties": props, "required": list(req)}


STR = {"type": "string"}
TOOLS = [
    ("sdfedit_status", "エディタ(ブラウザ)の接続状態を確認", S({}), t_status),
    ("sdfedit_get_scene", "現在のシーンを .ssq テキストで取得 (カメラ含む)。編集前に必ず読む", S({}), t_get_scene),
    ("sdfedit_set_scene", "シーン全体を .ssq テキストで置き換える (undo 可)。get_scene の結果を編集して渡す。失敗時はエラー", S({"ssq": STR}, ["ssq"]), t_set_scene),
    ("sdfedit_get_doc", "エディタ内部のドキュメント JSON (ノードツリー・id) を取得", S({}), t_get_doc),
    ("sdfedit_screenshot", "エディタのビューポートを PNG で取得 (結果の目視確認用)", S({}), t_screenshot),
    ("sdfedit_render", "sqm で本レンダして PNG を返す (シェーダ/影込み)", S({
        "quality": {"type": "string", "enum": ["draft", "hq"]},
        "width": {"type": "integer"}, "height": {"type": "integer"}}), t_render),
    ("sdfedit_undo", "エディタで undo", S({}), t_undo),
    ("sdfedit_redo", "エディタで redo", S({}), t_redo),
    ("sdfedit_list_examples", "examples/ の保存済みシーン一覧", S({}), t_list_examples),
    ("sdfedit_load_example", "examples/<name>.ssq を開く", S({"name": STR}, ["name"]), t_load_example),
    ("sdfedit_save_example", "現在のシーンを examples/<name>.ssq に保存", S({"name": STR}, ["name"]), t_save_example),
    ("sdfedit_eval", "ブラウザ内で JS を実行 (上級者向け。api.doc / api.viewer / api.mutated() 等が使える。値は return で返す)", S({"code": STR}, ["code"]), t_eval),
]
BY_NAME = {t[0]: t for t in TOOLS}


def handle(msg):
    m, mid, p = msg.get("method"), msg.get("id"), msg.get("params") or {}
    if m == "initialize":
        return {"protocolVersion": p.get("protocolVersion", "2024-11-05"),
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "sdfedit", "version": "0.1.0"}}
    if m == "ping":
        return {}
    if m == "tools/list":
        return {"tools": [{"name": n, "description": d, "inputSchema": s} for n, d, s, _ in TOOLS]}
    if m == "tools/call":
        t = BY_NAME.get(p.get("name"))
        if not t:
            raise KeyError("unknown tool")
        try:
            return {"content": t[3](p.get("arguments") or {})}
        except Exception as e:
            return {"content": text(f"ERROR: {e}"), "isError": True}
    if mid is None:
        return None   # notification
    raise KeyError("method not found: " + str(m))


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except ValueError:
            continue
        try:
            res = handle(msg)
            if msg.get("id") is None or res is None:
                continue
            out = {"jsonrpc": "2.0", "id": msg["id"], "result": res}
        except Exception as e:
            if msg.get("id") is None:
                continue
            out = {"jsonrpc": "2.0", "id": msg["id"], "error": {"code": -32601, "message": str(e)}}
        sys.stdout.write(json.dumps(out) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
