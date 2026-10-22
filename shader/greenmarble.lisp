;;; greenmarble — 緑大理石 (単体, タイル無し)
;;;
;;; 移植元: BMRT greenmarble.sl (noises.h)
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;; gmarbtile_polish (2026-08-09 移植) の大理石コアと同一の式 —
;;; tilepattern/タイル毎オフセット/目地/Kr trace を除いた部分集合:
;;;   ① 下地: turbulence 5oct → smoothstep(0.1,0.35) で dark/light ブレンド
;;;   ② 鉱脈: ドメインワープ (ベクトル fBm 6oct + 定数オフセット) →
;;;      3oct: turbsum += (1-turbsum)·pow(smoothstep(.8,1,1-|snoise|), sharpness)/freq (freq×2)
;;;      + 低周波 snoise でパッチ状に間引き
;;;   ③ plastic 照明 (specularcolor つき)
;;;
;;; パラメータ定義順 (shade_dr.cpp greenmarble_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 specularcolor=4
;;;   darkcolor=5 lightcolor=6 veincolor=7 veinfreq=8 sharpness=9 txtscale=10

(setq greenmarble-shader

(make-shader greenmarble :keyword :surface
      (
       ((Ka            float) 0.1)
       ((Kd            float) 0.6)
       ((Ks            float) 0.4)
       ((roughness     float) 0.1)
       ((specularcolor color) (make-color 1 1 1))
       ((darkcolor     color) (make-color 0.01 0.12 0.004))
       ((lightcolor    color) (make-color 0.06 0.18 0.02))
       ((veincolor     color) (make-color 0.47 0.57 0.03))
       ((veinfreq      float) 1.0)
       ((sharpness     float) 25.0)
       ((txtscale      float) 1.0)
       )

  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((pp  point) (make-point 0 0 0))
          ((q   point) (make-point 0 0 0))
          ((famp float) 0.0) ((facc float) 0.0) ((j float) 0.0)
          ((wx float) 0.0) ((wy float) 0.0) ((wz float) 0.0)
          ((Ct  color) (make-color 0 0 0))
          ((frq float) 0.0) ((tb float) 0.0) ((tsum float) 0.0)
          ((gate float) 0.0))

    (setvar pp (* (transform "shader" Pg) txtscale))

    ;; ① 下地
    (setvar famp 1.0) (setvar facc 0.0) (setvar q pp)
    (repeat (j 5)
      (setvar facc (+ facc (* famp (abs (- (* 2.0 (noise q)) 1.0)))))
      (setvar famp (* famp 0.5))
      (setvar q (* q 2.0)))
    (setvar Ct (mix darkcolor lightcolor (smoothstep 0.1 0.35 (* 0.5 facc))))

    ;; ② 鉱脈 (ドメインワープ → 閾値化 snoise ×3oct)
    (setvar famp 0.5) (setvar wx 0.0) (setvar wy 0.0) (setvar wz 0.0) (setvar q pp)
    (repeat (j 6)
      (setvar wx (+ wx (* famp (- (* 2.0 (noise q)) 1.0))))
      (setvar wy (+ wy (* famp (- (* 2.0 (noise (+ q (make-point 17.3 0 0)))) 1.0))))
      (setvar wz (+ wz (* famp (- (* 2.0 (noise (+ q (make-point 0 31.7 0)))) 1.0))))
      (setvar famp (* famp 0.5))
      (setvar q (* q 2.0)))
    (setvar pp (+ pp (+ (make-point 35.2 -21.9 6.25) (make-point wx wy wz))))
    (setvar pp (* pp veinfreq))
    (setvar tsum 0.0) (setvar frq 1.0)
    (repeat (j 3)
      (setvar tb (abs (- (* 2.0 (noise (* pp frq))) 1.0)))
      (setvar tb (/ (pow (smoothstep 0.8 1.0 (- 1.0 tb)) sharpness) frq))
      (setvar tsum (+ tsum (* (- 1.0 tsum) tb)))
      (setvar frq (* frq 2.0)))
    (setvar gate (smoothstep -0.1 0.05
                             (- (* 2.0 (noise (* (+ pp (make-point -4.4 8.34 27.1)) 2.0))) 1.0)))
    (setvar Ct (mix Ct veincolor (* tsum gate)))

    ;; ③ plastic 照明
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* specularcolor Ks (specular Nf Ir roughness)))))
)))

(compile-shader greenmarble-shader)
(append-shader greenmarble-shader)
