/* MCP ブリッジ: serve.py の /__bridge__/poll をロングポールし、mcp_server.py から
   届いたコマンドをエディタ (app.js が渡す api) に対して実行して結果を返す。
   ローカル専用。eval は任意コード実行なので公開網には出さないこと。 */

async function blobToBase64(blob) {
  const buf = new Uint8Array(await blob.arrayBuffer());
  let s = '';
  for (let i = 0; i < buf.length; i += 0x8000) s += String.fromCharCode(...buf.subarray(i, i + 0x8000));
  return btoa(s);
}

export function startBridge(api) {
  const handlers = {
    get_scene: async () => ({ ssq: api.getScene() }),
    set_scene: async ({ ssq }) => {
      if (typeof ssq !== 'string' || !ssq.trim()) throw new Error('ssq が空です');
      if (!api.setScene(ssq)) throw new Error('読み込み失敗: ' + api.getStatus().text);
      return { status: api.getStatus().text };
    },
    get_doc: async () => ({ doc: JSON.parse(api.getDocJson()) }),
    undo: async () => { api.undo(); return {}; },
    redo: async () => { api.redo(); return {}; },
    get_status: async () => api.getStatus(),
    screenshot: async () => {
      const blob = await api.screenshot();
      return { png_base64: await blobToBase64(blob) };
    },
    eval: async ({ code }) => {
      const r = await (new Function('api', 'return (async () => {' + code + '\n})()'))(api);
      return { value: r === undefined ? null : JSON.parse(JSON.stringify(r)) };
    },
  };

  async function loop() {
    for (;;) {
      let cmd = {};
      try {
        const res = await fetch('/__bridge__/poll');
        cmd = await res.json();
      } catch {
        await new Promise(r => setTimeout(r, 2000));
        continue;
      }
      if (!cmd.id) continue;
      let result;
      try {
        const h = handlers[cmd.cmd];
        if (!h) throw new Error('unknown command: ' + cmd.cmd);
        result = { ok: true, ...(await h(cmd.args || {})) };
      } catch (e) {
        result = { ok: false, error: String(e && e.message || e) };
      }
      try {
        await fetch('/__bridge__/result', {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ id: cmd.id, result }),
        });
      } catch { /* 次のポールで継続 */ }
    }
  }
  loop();
}
