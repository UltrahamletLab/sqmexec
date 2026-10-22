# 場の値を直接読んで確かめる

スクリーンショットは rAF ループに上書きされるので、融合・分離の判定は
`mc.field` (Float32Array、長さ resolution³) を読む。index は
`z * size² + y * size + x` (各軸 0..size−1、場の座標 0..1 を `(size−1)` 倍)。

ページ側で `window.__sl = { mc, updateBalls }` のように公開しておき、
ブラウザのコンソール (または Claude の javascript_tool) で:

```js
const mc = window.__sl.mc, n = mc.size;
const at = (x, y, z) => mc.field[Math.round(z*(n-1))*n*n + Math.round(y*(n-1))*n + Math.round(x*(n-1))];
// t 秒時点の場を作って、中心と隣接球の中点を読む (軌道の式はページと同じものを書く)
const probe = (t) => {
  window.__sl.updateBalls(t);
  const r = 0.05 + 0.22 * (0.5 - 0.5 * Math.cos(t * 0.55)), spin = t * 0.45, mids = [];
  for (let i = 0; i < 3; i++) {
    const a0 = spin + i * 2 * Math.PI / 3, a1 = spin + (i + 1) * 2 * Math.PI / 3;
    mids.push(+at(0.5 + r * (Math.cos(a0) + Math.cos(a1)) / 2, 0.5,
                  0.5 + r * (Math.sin(a0) + Math.sin(a1)) / 2).toFixed(1));
  }
  return { t, r: +r.toFixed(3), center: +at(0.5, 0.5, 0.5).toFixed(1), mids, iso: mc.isolation };
};
[probe(0), probe(Math.PI / 0.55)]   // 融合期と分離期
```

読み方:

| 時期 | 見る値 | 期待 |
|---|---|---|
| 融合期 | center | isolation の数十倍 (数百〜数千)。小さいと融合が弱い |
| 分離期 | mids の最大 | isolation 未満。60 に対して 58 のような際どい値は揺らぎで繋がるので余裕を取る |

`updateBalls(t)` を呼んだ直後に同じ式の中で読むこと。別の呼び出しに分けると
rAF ループが場を次フレームの t で作り直してしまう。

## 固定時刻で絵も見たいとき

rAF を止めずに「この瞬間」を撮る方法は無いので、ページに
`?t=5.7` のような固定時刻モードか、`?record=1` の固定タイムステップモードを付ける。
sqm/web/slshader/metaball_duo.html は後者の例で、各フレームを PNG として
同一オリジンの record_server.py に POST し、ffmpeg で mp4 にする。
