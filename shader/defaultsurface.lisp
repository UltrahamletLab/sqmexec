;;; defaultsurface — ライトを見ない facing-ratio シェーディング
;;;
;;; 移植元: BMRT defaultsurface.sl
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;;   d  = normalize(I) . normalize(N)
;;;   Ci = Cs * (Ka + Kd * d*d);  Oi = Os;  Ci *= Oi
;;;
;;; RenderMan でサーフェスシェーダー未指定時に使われるフォールバック。
;;; d を**二乗**するので I と N の符号 (表裏) に依らず、視線に正対する面ほど
;;; 明るい「ヘッドライト照明」になる。ライト・影・ambient() を一切見ないため、
;;; 照明が壊れているのかシェーダーが壊れているのかの**切り分け用**に便利
;;; (これで正常に見えればジオメトリと法線は健全 = 問題は照明側)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の defaultsurface_params[] と一致必須):
;;;   Kd=0 Ka=1   ※原典の宣言順が Kd, Ka の順であることに注意
;;;
;;; 使い方 (シーン):
;;;   (surface (color 0.7 0.7 0.7) (shader defaultsurface))

(setq defaultsurface-shader

(make-shader defaultsurface :keyword :surface
      (
       ((Kd float) 0.8)
       ((Ka float) 0.2)
       )

  (enter (((d float) (dot (normalize I) (normalize N))))
    (setvar Oi Os)
    (setvar Ci (* Oi (* Cs (+ Ka (* Kd (* d d))))))
)))

(compile-shader defaultsurface-shader)
(append-shader defaultsurface-shader)
