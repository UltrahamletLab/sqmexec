;;; rotatetex.lisp — fundza "RSL - Rotating Texture Space" の移植
;;;
;;; テクスチャ空間 (s,t) を pivot まわりに回してから見本を引く。
;;; texname 指定時は texture() を読み、空なら回転チェッカー (資産不要の既定)。
;;; s,t が本物なのは UV 付きメッシュ (assets/quad.obj) — SDF は球面写像に落ちる
;;; (txtplastic の教訓)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の rotatetex_params[] と一致必須):
;;;   Ka=0 Kd=1 angle=2 pivot-s=3 pivot-t=4 checks=5 texname=6 c1=7 c2=8
(setq rotatetex-shader
(make-shader rotatetex :keyword :surface
  (((Ka float) 0.30)
   ((Kd float) 0.90)
   ((angle float) 30.0)
   ((pivot-s float) 0.5)
   ((pivot-t float) 0.5)
   ((checks float) 8.0)
   ((texname string) "")
   ((c1 color) (make-color 0.92 0.90 0.85))
   ((c2 color) (make-color 0.15 0.25 0.55)))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((s0 float) 0) ((t0 float) 0)
          ((ca float) 0) ((sa float) 0)
          ((sr float) 0) ((tr float) 0)
          ((w float) 0)
          ((surf color) (make-color 0 0 0)))
    ;; pivot まわりの 2D 回転 (原典の rotate() ヘルパを cos/sin で直書き)
    (setvar s0 (- s pivot-s))
    (setvar t0 (- t pivot-t))
    (setvar ca (cos (radians angle)))
    (setvar sa (sin (radians angle)))
    (setvar sr (+ pivot-s (- (* ca s0) (* sa t0))))
    (setvar tr (+ pivot-t (+ (* sa s0) (* ca t0))))
    (if (string/= texname "")
        (setvar surf (texture texname sr tr))
        (progn
          (setvar w (mod (+ (floor (* sr checks)) (floor (* tr checks))) 2))
          (setvar w (* w w))
          (setvar surf (mix c1 c2 w))))
    (setvar Oi Os)
    (setvar Ci (* Oi surf (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))))
)
(compile-shader rotatetex-shader)
(append-shader rotatetex-shader)
