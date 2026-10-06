;;; foresttree — 根張りマングローブの幹 (変位シェーダー)
;;;
;;; C リーフ `forest` (Shadertoy "foggy forest" 移植) の `ft_sdtree()` を
;;; :displacement クラスへ出したもの。**1本の木**ぶん。
;;;
;;; 元の C は
;;;     d = length(x,0,z) - currentR ;  currentR = r + 根張り/フレア/コブ
;;; という「半径が角度と高さで変わる無限円筒」。エンジンの変位は
;;;     d_child - amp*h
;;; なので、子を半径 r の (cylinder ..) にすれば
;;;     length(x,z) - r - amp*h  ==  length(x,z) - (r + amp*h)
;;; と**そのままの形**になる。追加半径を h に入れればよい。
;;;
;;; 構成 (元コードと同じ順序):
;;;   ・角度 atan2(x,z) をノイズで捻り、cos(a*legs) を smoothstep で切って**脚**にする
;;;   ・幹フレア exp(-k*h) と根フレア exp(-k*(h+0.1)) で「下ほど太い」
;;;   ・fBm の2乗を根のコブに足す
;;;   ・最後に微小ノイズで表面を荒らす
;;;
;;; ※ 原典との違い: ノイズが別物。元は GLSL の sin-hash 値ノイズ (ft_hash1/ft_noise3)、
;;;   こちらは sqm 共有ノイズ (vnoise/vfbm)。**見た目は同種だが同一ではない**。
;;; ※ 元コードの `d*0.45` (Lipschitz 保守化) に相当するのは **シーンの (lipschitz ..)**。
;;;   根元の脚は角度依存なので軸の近くで勾配が跳ねる → 小さすぎると穴が開く。
;;;
;;; Lipschitz の目安: 脚の smoothstep が支配。cos(a*legs) の角度勾配は軸から
;;;   距離 rr で legs/rr、smoothstep の最大勾配は 1.5/幅。
;;;   legs=4 / 幅0.5 / rr~0.3 なら 4/0.3*3 = 40 前後。実測で詰めること。
;;;
;;; 使い方 (シーン):
;;;   (displace (shader foresttree) (amp 1.05) (lipschitz 40)
;;;             (param seed 0.37) (param ground-y -1.2) (param legs 4)
;;;     (cylinder (center 0 4 0) (radius 0.30) (height 6)))

(setq foresttree-shader

(make-shader foresttree :keyword :displacement
      (((seed         float) 0.37)   ; 木ごとの種 (角度の捻りとコブに効く)
       ((ground-y     float) 0.0)    ; 地面の高さ (ここからの高さでフレアが decay)
       ((legs         float) 4.0)    ; 主要な根の本数
       ((trunk-flare  float) 2.5)    ; 幹フレアの減衰 exp(-k*h)
       ((root-flare   float) 4.0)    ; 根フレアの減衰
       ((warp1        float) 1.4)    ; 主根の角度の捻り
       ((warp2        float) 1.5)    ; 副根の角度の捻り
       ((base-amt     float) 0.05)   ; 幹の膨らみ
       ((leg-amt      float) 0.35)   ; 主根の張り出し (幹フレア側)
       ((rootleg-amt  float) 0.55)   ; 主根の張り出し (根フレア側)
       ((knot-amt     float) 0.10)   ; 根のコブ
       ((wob          float) 0.02)   ; 表面の荒れ
       ((axis-fade    float) 0.50)   ; 軸からこの距離までで脚を殺す (Lipschitz の要)
       ((norm         float) 1.05))  ; h を [0,1] に収める正規化 (= 各 amt の和)

  (enter (((hh   float) 0.0) ((ang  float) 0.0)
          ((n1   float) 0.0) ((n2   float) 0.0)
          ((am   float) 0.0) ((asb  float) 0.0)
          ((mleg float) 0.0) ((sleg float) 0.0) ((roots float) 0.0)
          ((knot float) 0.0) ((tf   float) 0.0) ((rf float) 0.0)
          ((wb   float) 0.0) ((ext  float) 0.0)
          ((rr   float) 0.0) ((fade float) 0.0)
          ((q1 point) (make-point 0 0 0))
          ((q2 point) (make-point 0 0 0))
          ((q3 point) (make-point 0 0 0)))

    (setvar hh  (- (ycomp P) ground-y))
    (setvar ang (atan2 (xcomp P) (zcomp P)))

    ;; ── 主根: 角度をノイズで捻って cos を切る ──────────────────
    (setvar q1 (+ (* P 1.2) (* seed 5.0)))
    (setvar n1 (- (vnoise q1) 0.5))
    (setvar am (+ ang (* n1 (* 2.0 warp1))))
    (setvar mleg (smoothstep 0.4 0.9 (cos (* am legs))))

    ;; ── 副根 (本数を倍+1にして細かく) ─────────────────────────
    (setvar q2 (+ (* P 2.0) (* seed 13.0)))
    (setvar n2 (- (vnoise q2) 0.5))
    (setvar asb (+ ang (* n2 (* 2.0 warp2))))
    (setvar sleg (smoothstep 0.6 0.9 (cos (* asb (+ (* legs 2.0) 1.0)))))

    ;; roots = max(mleg, sleg*0.6)。**DSL の max フックは壊れているので clamp で**
    (setvar sleg  (* sleg 0.6))
    (setvar roots (+ mleg (clamp (- sleg mleg) 0.0 1.0)))

    ;; ── 根のコブ ──────────────────────────────────────────────
    (setvar q3 (+ (* P 3.0) (* seed 10.0)))
    (setvar knot (pow (vfbm q3 3) 2.0))

    ;; ── フレア (下ほど太い) ───────────────────────────────────
    (setvar tf (exp (* (- 0.0 trunk-flare) (clamp hh 0.0 100.0))))
    (setvar rf (exp (* (- 0.0 root-flare)  (clamp (+ hh 0.1) 0.0 100.0))))

    ;; ── 軸の近くで脚を殺す (**Lipschitz 発散の根治**) ──────────────
    ;;   脚は cos(atan2(x,z)*legs) なので角度の勾配は legs/rr。軸に近づくと
    ;;   発散して球面追跡が貫通する (実測: 根元が黒く破れる)。物理的にも幹の芯に
    ;;   脚は無いので、半径方向にフェードして落とすのが正しい。
    (setvar rr   (length (make-point (xcomp P) 0.0 (zcomp P))))
    (setvar fade (smoothstep 0.0 axis-fade rr))
    (setvar roots (* roots fade))
    (setvar knot  (* knot  fade))

    ;; ── 表面の荒れ ────────────────────────────────────────────
    (setvar wb (* (- (vnoise (* P 2.0)) 0.5) (* 2.0 wob)))

    (setvar ext (+ (* base-amt tf)
                   (* roots (+ (* leg-amt tf) (* rootleg-amt rf)))
                   (* knot (* knot-amt rf))
                   wb))
    (setvar disp (clamp (/ ext norm) 0.0 1.0))
)))

(compile-shader foresttree-shader)
(append-shader foresttree-shader)
