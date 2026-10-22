;;; mandelbrot.lisp — マンデルブロ集合を表面に描く (2026-08-03)
;;;
;;; DSL ループ拡張の実戦例第2弾: escape-time 法をそのまま書く。
;;;   c = center + (ワールド座標2軸)/zoom,  z ← z²+c を iters 回、
;;;   |z|²>4 で (break)。脱出回数 → 3色グラデーション、集合内部は in-color。
;;; axis 0 = xy 平面 (壁向け) / 1 = xz 平面 (床向け)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の mandelbrot_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 iters=4 zoom=5 center-re=6 center-im=7
;;;   axis=8 in-color=9 col1=10 col2=11 col3=12

(setq mandelbrot-shader
(make-shader mandelbrot :keyword :surface
  (((Ka float) 0.30)
   ((Kd float) 0.85)
   ((Ks float) 0.15)
   ((roughness float) 0.15)
   ((iters float) 64.0)
   ((zoom float) 1.0)          ; 大きいほど拡大 (複素平面の縮尺 = 1/zoom)
   ((center-re float) -0.6)    ; ワールド原点が写る複素平面の点
   ((center-im float) 0.0)
   ((axis float) 0.0)          ; 0: (x,y)→(re,im) 壁 / 1: (x,z) 床
   ((in-color color) (make-color 0.02 0.02 0.05))
   ((col1 color) (make-color 0.05 0.10 0.35))
   ((col2 color) (make-color 0.95 0.55 0.10))
   ((col3 color) (make-color 1.00 0.98 0.85)))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((cre float) 0) ((cim float) 0)
          ((zr float) 0) ((zi float) 0) ((zr2 float) 0)
          ((j float) 0) ((esc float) 0) ((inside float) 0)
          ((tt float) 0)
          ((surf color) (make-color 0 0 0)))
    ;; ワールド座標 → 複素平面 (ローカル名 cre/cim — ci は出力 Ci と大小非区別で衝突)
    (setvar cre (+ center-re (/ (xcomp Pg) zoom)))
    (if (> axis 0.5)
        (setvar cim (+ center-im (/ (zcomp Pg) zoom)))
        (setvar cim (+ center-im (/ (ycomp Pg) zoom))))
    ;; escape-time: z ← z² + c
    (setvar esc iters)
    (repeat (j iters)
      (setvar zr2 (- (* zr zr) (* zi zi)))
      (setvar zi (+ (* 2 zr zi) cim))
      (setvar zr (+ zr2 cre))
      (if (> (+ (* zr zr) (* zi zi)) 4)
          (progn (setvar esc j) (break))))
    ;; 彩色: 脱出回数の平方根圧縮 → col1→col2→col3 の2段グラデーション
    (setvar inside (step iters esc))            ; esc==iters → 集合内部
    (setvar tt (sqrt (/ esc iters)))
    (setvar surf (mix (mix col1 col2 (smoothstep 0.0 0.55 tt))
                      col3 (smoothstep 0.55 1.0 tt)))
    (setvar surf (mix surf in-color inside))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* surf (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* Ks (specular Nf Ir roughness))))))))
(compile-shader mandelbrot-shader)
(append-shader mandelbrot-shader)
