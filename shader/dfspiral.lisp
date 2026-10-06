;;; dfspiral — 螺旋の畝 / ターバン (blob deform の DSL 模様)
;;;
;;; **解析パターン (Σ coef·Π sin) が構造的に到達できない領域**の実例。
;;; 一般形が厳密に囲めるのは「引数が t について線形」な sin だけだが、
;;; 角度 θ = atan2(z,x) は線形でない。円筒座標を使う模様は DSL でしか書けない。
;;;
;;;   g = sin( lobes·θ + pitch·y + phase ) · gate(r)
;;;
;;; **罠が2つある。どちらも踏むと表面が壊れる。**
;;;
;;; ① θ の分岐: atan2 は ±π で不連続。lobes が**整数**なら sin(n(θ+2π)) = sin(nθ) で
;;;    継ぎ目が消える。非整数を入れると縦に裂け目が走る (跳びは中点包囲を跨げない)。
;;; ② 軸の特異点: |∇θ| = 1/r なので r→0 で勾配が発散する。どんな L を申告しても
;;;    軸の近傍では足りず、そこだけ貫通する。r で smoothstep ゲートして殺す。
;;;
;;; Lipschitz: |∇g| ≈ lobes/rmin + pitch + ゲートの傾き(≈1.5/rmin)。
;;;   lobes 5 / pitch 10 / rmin 0.15 なら ≈ 33 + 10 + 10 = 53 → 80 程度を申告。
;;;   **必ず L 掃引で裏を取ること** (倍にして絵が変わらなくなるまで上げる)。
;;;
;;; 使い方 (シーン):
;;;   (deform (mode dsl)(shader dfspiral)(amp 0.22)(lipschitz 80)
;;;           (param lobes 5)(param pitch 10)(param rmin 0.15))

(setq dfspiral-shader

(make-shader dfspiral :keyword :displacement
      (((lobes float) 5.0)     ; 螺旋の本数。**整数にすること** (非整数は継ぎ目が裂ける)
       ((pitch float) 10.0)    ; y 方向のねじれ (0 で縦縞・大きいほど寝た螺旋)
       ((phase float) 0.0)
       ((rmin  float) 0.15))   ; この半径より内側は変位をフェードで殺す (軸の特異点対策)

  (enter (((r  float) 0.0)
          ((th float) 0.0)
          ((gt float) 0.0))

    (setvar r (sqrt (+ (* (xcomp P) (xcomp P)) (* (zcomp P) (zcomp P)))))
    (setvar th (atan2 (zcomp P) (xcomp P)))

    ;; 軸まわりのゲート: r < rmin で 0、2·rmin で 1 の smoothstep
    (setvar gt (clamp (/ (- r rmin) rmin) 0.0 1.0))
    (setvar gt (* (* gt gt) (- 3.0 (* 2.0 gt))))

    (setvar disp (* (sin (+ (+ (* lobes th) (* pitch (ycomp P))) phase)) gt))
)))

(compile-shader dfspiral-shader)
(append-shader dfspiral-shader)
