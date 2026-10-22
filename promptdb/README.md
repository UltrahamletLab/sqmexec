# promptdb — プロンプト一覧をキーワードで高速検索するローカルサーバ

`positive: ... / negative: ... / ---` 形式のテキスト (約 7 万件) を SQLite の
全文検索 (FTS5) に取り込み、ブラウザと JSON API から数ミリ秒で引けるようにする。
**Python 3 標準ライブラリだけで動く** (追加インストール不要)。

## 使い方

```powershell
# 1. DB を作る (元テキスト → prompts.db。重複は初出だけ残す。13 秒ほど)
python promptdb\build_db.py C:\Users\hakub\Desktop\70000.txt promptdb\prompts.db

# 2. サーバを起動
python promptdb\server.py
```

→ http://127.0.0.1:8700/ を開く。入力した瞬間に結果が出る。

他の PC からも使うなら `--host 0.0.0.0`、ポートは `--port`。

## 検索構文

| 書き方 | 意味 |
|---|---|
| `clown portrait` | 両方を含む (AND) |
| `"evil clown"` | 連続した語句 |
| `clown OR jester` | どちらか |
| `clown -makeup` | makeup を含まない |
| `cyber*` | 前方一致 (cyberpunk, cybernetic ...) |

語尾の違い (clown / clowns, painting / painted) は porter ステミングで同一視する。
否定だけの検索 (`-clown` のみ) は未対応。

## API (すべて GET、JSON、CORS 許可)

| エンドポイント | 内容 |
|---|---|
| `/api/search?q=…&limit=50&offset=0&order=rank` | 検索。`order` は `rank` (関連度) / `id` / `random`。`limit` は最大 500 |
| `/api/random?n=10&q=…` | ランダムに n 件 (q は省略可) |
| `/api/prompt/<id>` | 1 件取得 |
| `/api/stats` | 件数など |
| `/api/export?q=…&format=txt` | 該当全件をダウンロード。`format` は `txt` / `csv` / `json` |

レスポンス例:

```json
{"query":"pierrot","fts":"\"pierrot\"","total":4,"limit":2,"offset":0,"order":"rank","ms":2.1,
 "hits":[{"id":61513,"prompt":"award winning digital art of ...","html":"award winning digital art of a attractive male <mark>pierrot</mark> ..."}]}
```

`html` はハイライト用 (エスケープ済み)、`prompt` は生テキスト。

## 速度の目安 (61,746 件、この PC)

| クエリ | ヒット | DB 時間 |
|---|---|---|
| `clown portrait` | 59 | 2 ms |
| `cyber*` | 4,056 | 8 ms |
| `greg rutkowski` | 23,987 | 45 ms |

ヒットが多いほど総数カウントと関連度ソートで時間がかかるが、十分対話的。

## ファイル

- `build_db.py` — テキスト → `prompts.db` (再実行すると作り直す)
- `server.py` — HTTP サーバ + Web UI (単一ファイル)
- `prompts.db` — 生成物 (約 59 MB)。git には入れない。元テキストから再生成できる

## 元データを更新したいとき

`build_db.py` を再実行するだけ。サーバは読み取り専用で DB を開くので、
再生成中は一度サーバを止める。
