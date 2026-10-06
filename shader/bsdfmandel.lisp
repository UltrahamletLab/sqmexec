;;; bsdfmandel — マンデルブロを PT 材質にする (DSLループ×bsdfブリッジ, 2026-08-03)
;;;
;;; classic 版 mandelbrot.lisp との違い: こちらは「その点の BSDF パラメータ」を
;;; 返すだけで、ライティングは -Q が NEE+MIS で積分する。ループで
;;;   ・escape-time (脱出回数) → アルベドの3色パレット
;;;   ・軌道トラップ min|z| → フィラメント内部の濃淡 (min は算術で合成)
;;;   ・境界近傍バンド → **発光** (ネオンのふち。部屋をバウンス光で照らす)
;;;   ・集合内部 → 低roughness+metallic の「磨いた黒曜石」(部屋を映す)
;;; を1本で出す。roughness/metallic/emission が1枚の面の上で連続に変わる
;;; PT ならではの標本。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color 1 1 1) (ka 0) (kd 1) (ks 0) (phong 0)
;;;            (bsdf bsdfmandel)
;;;            (param iters 96) (param zoom 1.1) (param center-re -0.6)
;;;            (param center-im 1.2) (param axis 0) (param glow 5.0))
;;;   ※ 発光は geometry emitter 登録ではない (BSDF ヒット寄与のみ) —
;;;     部屋の底明るさ用に別の弱いランプを置くとノイズが減る

(setq bsdfmandel-shader
(make-shader bsdfmandel :keyword :volume
  (((iters float) 96.0)
   ((zoom float) 1.0)
   ((center-re float) -0.6)
   ((center-im float) 0.0)
   ((axis float) 0.0)            ; 0: (x,y) 壁 / 1: (x,z) 床
   ((glow float) 5.0)            ; 境界バンドの発光強度
   ((glow-color color) (make-color 1.00 0.42 0.10))
   ((col1 color) (make-color 0.04 0.08 0.30))
   ((col2 color) (make-color 0.80 0.35 0.10))
   ((col3 color) (make-color 1.00 0.95 0.80))
   ((in-color color) (make-color 0.02 0.02 0.03))
   ((rough-out float) 0.55)
   ((rough-in float) 0.10)
   ((metal-in float) 0.75))
  (enter (((cre float) 0) ((cim float) 0)
          ((zr float) 0) ((zi float) 0) ((zr2 float) 0)
          ((j float) 0) ((esc float) 0) ((inside float) 0)
          ((mn float) 1000) ((r2 float) 0)
          ((tt float) 0) ((band float) 0) ((rg float) 0) ((mt float) 0)
          ((alb color) (make-color 0 0 0)))
    (setvar cre (+ center-re (/ (xcomp Pg) zoom)))
    (if (> axis 0.5)
        (setvar cim (+ center-im (/ (zcomp Pg) zoom)))
        (setvar cim (+ center-im (/ (ycomp Pg) zoom))))
    (setvar esc iters)
    (repeat (j iters)
      (setvar zr2 (- (* zr zr) (* zi zi)))
      (setvar zi (+ (* 2 zr zi) cim))
      (setvar zr (+ zr2 cre))
      (setvar r2 (+ (* zr zr) (* zi zi)))
      ;; 軌道トラップ: min(mn, r2) を算術で (min フックは壊れている)
      (setvar mn (* 0.5 (- (+ mn r2) (abs (- mn r2)))))
      (if (> r2 4)
          (progn (setvar esc j) (break))))
    (setvar inside (step iters esc))
    (setvar tt (sqrt (/ esc iters)))
    ;; アルベド: 3色パレット × 軌道トラップの濃淡 (集合内部は in-color)
    (setvar alb (mix (mix col1 col2 (smoothstep 0.0 0.55 tt))
                     col3 (smoothstep 0.55 1.0 tt)))
    (setvar alb (* alb (+ 0.45 (* 0.55 (clamp (* 1.6 mn) 0 1)))))
    (setvar Cl (mix alb in-color inside))
    ;; 発光: 境界に近い (脱出が遅い) ほど強いネオンバンド。内部は光らない
    (setvar band (* (pow tt 6) (- 1 inside)))
    (setvar Ci (* glow-color (* glow band)))
    ;; 材質: 外=マット, 内=磨いた黒曜石 (低rough+metallic)
    (setvar rg (+ (* rough-out (- 1 inside)) (* rough-in inside)))
    (setvar mt (* metal-in inside))
    (setvar Oi (make-color rg mt 0.0)))))
(compile-shader bsdfmandel-shader)
(append-shader bsdfmandel-shader)
