;;; nebulashow.lisp — fundza "RSL - Nebula Point Clouds" nebula_show の移植
;;;
;;; geo_show (法線=-I の等輝度) に「法線のノイズ揺らぎ」を足した版。
;;; fakeN = normalize(-I) + noise(P·freq)·amp — 揺らいだ法線が3色ポイント
;;; ライトを不均一に拾い、点群にガス状のむらが出る (原典 wobble())。
;;; ベクトルノイズはスカラー noise ×3 (オフセット違い) で代用 (pnoisep 未実装)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の nebulashow_params[] と一致必須):
;;;   Kd=0 wobble-amp=1 wobble-freq=2
(setq nebulashow-shader
(make-shader nebulashow :keyword :surface
  (((Kd float) 1.0)
   ((wobble-amp float) 1.8)
   ((wobble-freq float) 4.0))
  (enter (((fakeN point) (make-point 0 0 0))
          ((pp point) (make-point 0 0 0))
          ((nx float) 0) ((ny float) 0) ((nz float) 0))
    (setvar pp (* wobble-freq Pg))
    (setvar nx (noise pp))
    (setvar ny (noise (+ pp (make-point 71.7 13.3 5.9))))
    (setvar nz (noise (+ pp (make-point 27.1 91.3 47.7))))
    (setvar fakeN (+ (normalize (- I))
                     (* wobble-amp (make-point (- (* 2 nx) 1)
                                               (- (* 2 ny) 1)
                                               (- (* 2 nz) 1)))))
    (setvar fakeN (normalize fakeN))
    (setvar Oi Os)
    (setvar Ci (* Oi Cs Kd (diffuse fakeN)))))
)
(compile-shader nebulashow-shader)
(append-shader nebulashow-shader)
