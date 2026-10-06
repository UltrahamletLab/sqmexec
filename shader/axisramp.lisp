;;; axisramp — 1軸に沿った smoothstep 2枚のランプ (変位シェーダー)
;;;
;;; 目的: **距離場のパラメータを位置に応じて動かす**。
;;;   sqm の SDF ノードに `(displace (shader axisramp) ..)` を掛けると、
;;;   engine は `d_child - amp*h(P)` を評価する。子が平面なら「切り込み位置が
;;;   軸に沿って滑らかに変わる平面」になり、子が球なら「片側だけ膨らんだ球」になる。
;;;
;;; これは tdhooper "Head" の眉稜の書き方そのもの (docs/2026-07-29 の理由③):
;;;   peak = -p.y - .165;
;;;   peak += smoothstep(.0,  .2,  p.x) * .01;
;;;   peak -= smoothstep(.12, .29, p.x) * .025;
;;; を engine の符号 (d -= amp*h) に合わせて h に写すと
;;;   amp = 0.025, h = 1.0*smoothstep(.12,.29,x) + (-0.4)*smoothstep(.0,.2,x)
;;; となる (a-* が引き締める側、b-* が緩める側)。
;;;
;;; h の値域は [-(|b-amt|), a-amt] 程度。engine 側の慣習どおり amp で実寸に直す。
;;;
;;; 使い方 (シーン, SDF ノードを包む単項オプ):
;;;   (displace (shader axisramp) (amp 0.025) (lipschitz 11.82)
;;;             (param axis 0) (param a0 0.12) (param a1 0.29) (param a-amt 1.0)
;;;             (param b0 0.0)  (param b1 0.2)  (param b-amt -0.4)
;;;     (plane (center 0 0 0) (normal 0 -1 0) (offset 0.165)))
;;;
;;;   ※ P は **そのノードのローカル座標** (囲む translate/rotate/mirror を通した後)。
;;;   ※ lipschitz は |∇h| の上界をシーンが申告する。この式なら厳密に
;;;       |a-amt|*1.5/(a1-a0) + |b-amt|*1.5/(b1-b0)
;;;     (smoothstep の最大勾配は 1.5/幅)。小さすぎると球面追跡が穴を開ける。
;;;   ※ 上位に `(scale ..)` があると局所座標の尺度が変わる → その分 lipschitz を上げる。

(setq axisramp-shader

(make-shader axisramp :keyword :displacement
      (((axis  float) 0.0)      ; 0=x 1=y 2=z (どの座標でランプするか)
       ((a0    float) 0.0)      ; ランプA の立ち上がり開始
       ((a1    float) 1.0)      ; ランプA の立ち上がり終了
       ((a-amt float) 1.0)      ; ランプA の重み (符号つき)
       ((b0    float) 0.0)      ; ランプB の立ち上がり開始
       ((b1    float) 1.0)      ; ランプB の立ち上がり終了
       ((b-amt float) 0.0))     ; ランプB の重み (符号つき。0 なら1枚だけ)

  (enter (((q float) 0.0)
          ((h float) 0.0))

    ;; ランプする座標を選ぶ (DSL に配列添字が無いので if で分岐)
    (setvar q (xcomp P))
    (if (> axis 0.5) (setvar q (ycomp P)))
    (if (> axis 1.5) (setvar q (zcomp P)))

    (setvar h (+ (* a-amt (smoothstep a0 a1 q))
                 (* b-amt (smoothstep b0 b1 q))))
    (setvar disp h)
)))

(compile-shader axisramp-shader)
(append-shader axisramp-shader)
