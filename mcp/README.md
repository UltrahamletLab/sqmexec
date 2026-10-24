# sdfedit MCP — プロンプトから sdfmodeler を操作する

Blender MCP と同じ構成: `AI クライアント ⇄ sdfedit_mcp.py ⇄ serve.py (/__bridge__/*) ⇄ ブラウザの sdfmodeler`

## 使い方

1. `.\serve.ps1` でエディタを起動し、ブラウザで開いたままにする (接続は自動)
2. MCP クライアントに登録 (Copilot CLI / Claude Code 共通の形式):

```json
{
  "mcpServers": {
    "sdfedit": {
      "command": "python",
      "args": ["C:\\Users\\hakub\\sqmexec\\mcp\\sdfedit_mcp.py"],
      "env": { "SDFEDIT_URL": "http://localhost:8642" }
    }
  }
}
```
Claude Code: `claude mcp add sdfedit -- python C:\Users\hakub\sqmexec\mcp\sdfedit_mcp.py`

## ツール

| ツール | 内容 |
|---|---|
| `sdfedit_status` | ブラウザ接続確認 |
| `sdfedit_get_scene` / `sdfedit_set_scene` | シーンを .ssq テキストで取得 / 置換 (undo 可) |
| `sdfedit_get_doc` | 内部ドキュメント JSON (ノード id 付き) |
| `sdfedit_screenshot` | ビューポートの PNG |
| `sdfedit_render` | sqm 本レンダ (draft / hq) |
| `sdfedit_undo` / `sdfedit_redo` | 取り消し / やり直し |
| `sdfedit_list_examples` / `load_example` / `save_example` | examples/ の入出力 |
| `sdfedit_eval` | ブラウザ内 JS 実行 (上級者向け) |

典型フロー: `get_scene` → .ssq を編集 → `set_scene` → `screenshot` で確認 → `render`。

⚠ ローカル専用。`eval` と `/__bridge__/*` は認証が無いので、公開網には出さないこと。
