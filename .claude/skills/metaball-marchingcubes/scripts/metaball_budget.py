#!/usr/bin/env python3
"""three.js MarchingCubes のメタボール設計の予算計算。

場の値 (addBall):  val(d) = strength / d² − subtract   (val > 0 のときだけ足す)
表面 (isosurface): val = isolation  ⇒  r_iso = sqrt(strength / (isolation + subtract))

判定するもの:
  破れ   … 球の中心の最大変位 + 揺らぎ + r_iso が 0.5 から 0.45 を越えないか
  分離   … 球を正 n 角形に置いたとき、隣り合う 2 球の中点での場の和が isolation を下回るか
  融合   … 中心に寄せたとき (orbit = merge-orbit) の中心の値が isolation を十分越えるか

例:
  python metaball_budget.py --strength 1.8 --subtract 12 --iso 60 \
      --orbit 0.27 --wobble 0.02 --lift 0.06 --strength-mod 0.08 --n 3
"""
import argparse
import math
import sys


def val(strength, subtract, d):
    v = strength / (1e-6 + d * d) - subtract
    return v if v > 0 else 0.0


def field_at(point, centers, strength, subtract):
    return sum(val(strength, subtract, math.dist(point, c)) for c in centers)


def polygon(n, R):
    return [(0.5 + R * math.cos(2 * math.pi * i / n), 0.5, 0.5 + R * math.sin(2 * math.pi * i / n))
            for i in range(n)]


def main():
    # Windows のコンソール (cp932) でも日本語と記号を落とさない
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--strength", type=float, required=True, help="addBall の strength")
    ap.add_argument("--subtract", type=float, default=12.0, help="addBall の subtract (既定 12)")
    ap.add_argument("--iso", type=float, default=60.0, help="mc.isolation (既定 60)")
    ap.add_argument("--n", type=int, default=3, help="正 n 角形に置く球の数")
    ap.add_argument("--orbit", type=float, required=True, help="分離時の外接半径 (場の単位 0..1)")
    ap.add_argument("--merge-orbit", type=float, default=0.05, help="融合時の外接半径")
    ap.add_argument("--wobble", type=float, default=0.0, help="半径方向の揺らぎの振幅")
    ap.add_argument("--lift", type=float, default=0.0, help="上下動の振幅")
    ap.add_argument("--strength-mod", type=float, default=0.0, help="strength の変調率 (0.08 = ±8%)")
    ap.add_argument("--margin", type=float, default=0.47, help="中心 0.5 から許す最大到達距離 (既定 0.47 = 端から 3% の余白)")
    ap.add_argument("--sep-margin", type=float, default=0.85, help="分離判定: 名目の中点の和 ≤ isolation × この値 (既定 0.85)")
    a = ap.parse_args()

    s_max = a.strength * (1 + a.strength_mod)
    s_min = a.strength * (1 - a.strength_mod)
    r_iso = math.sqrt(a.strength / (a.iso + a.subtract))
    r_iso_max = math.sqrt(s_max / (a.iso + a.subtract))
    r_zero = math.sqrt(a.strength / a.subtract)

    print(f"球の表面半径 r_iso = {r_iso:.3f}  (strength 最大時 {r_iso_max:.3f}, 寄与がゼロになる距離 {r_zero:.3f})")

    # ── 破れ ──
    reach_xz = a.orbit + a.wobble + r_iso_max
    reach_y = a.lift + r_iso_max
    reach = max(reach_xz, reach_y)
    ok_tear = reach <= a.margin
    print(f"最大到達 (0.5 からの距離): 水平 {reach_xz:.3f} / 垂直 {reach_y:.3f}  許容 {a.margin:.2f}"
          f"  → {'OK' if ok_tear else 'NG: 場の端で面が切れる'}")
    if not ok_tear:
        over = reach - a.margin
        print(f"   対処: orbit を {over:.3f} 減らす、または strength を "
              f"{(a.iso + a.subtract) * (r_iso_max - over) ** 2 / (1 + a.strength_mod):.2f} 以下にして scale で補う")

    # ── 分離 (隣り合う 2 球の中点、strength 最大・ウォブルで寄った最悪ケース) ──
    R_worst = a.orbit - a.wobble
    centers = polygon(a.n, R_worst)
    mid = tuple((p + q) / 2 for p, q in zip(centers[0], centers[1 % a.n]))
    f_mid = field_at(mid, centers, s_max, a.subtract)
    f_mid_nominal = field_at(mid, polygon(a.n, a.orbit), a.strength, a.subtract)
    # 揺らぎ・変調は球ごとに位相が違うので全部が同時に最悪にはならない。判定は名目値 + 余白で行い、
    # 「全部重なった場合」は参考に出す (isolation を越えていたら瞬間的に繋がる可能性がある)
    ok_sep = f_mid_nominal <= a.iso * a.sep_margin
    print(f"分離時の隣接中点の場: 名目 {f_mid_nominal:.1f} (許容 {a.iso * a.sep_margin:.1f}) / 揺らぎが全部重なると {f_mid:.1f}"
          f"  → {'OK: 分かれる' if ok_sep else 'NG: 繋がったまま or 際どい'}")
    if ok_sep and f_mid >= a.iso:
        print("   注意: 揺らぎが重なった瞬間は一時的に繋がりうる (気になるなら wobble / strength-mod を下げる)")
    if not ok_sep:
        d_need = math.sqrt(s_max / (a.subtract + a.iso / 2))
        R_need = 2 * d_need / (2 * math.sin(math.pi / a.n)) if a.n > 1 else d_need
        print(f"   2 球だけなら中点距離 {d_need:.3f} が要る (正 {a.n} 角形なら外接半径 >= {R_need + a.wobble:.3f}、"
              f"第 3 球以降の寄与でさらに少し広げる)")

    # ── 融合 ──
    f_center = field_at((0.5, 0.5, 0.5), polygon(a.n, a.merge_orbit), s_min, a.subtract)
    print(f"融合時 (外接半径 {a.merge_orbit}) の中心の場: {f_center:.0f}  → "
          f"{'OK: 1 塊' if f_center > a.iso * 2 else 'NG: 融合が弱い (merge-orbit を縮める)'}")

    print("判定:", "すべて OK" if ok_tear and ok_sep else "要調整")
    return 0 if ok_tear and ok_sep else 1


if __name__ == "__main__":
    raise SystemExit(main())
