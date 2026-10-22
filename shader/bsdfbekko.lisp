;;; bsdfbekko — べっ甲/琥珀: 厚み斑のあるコート吸収 (PT -Q 材質, 2026-08-02)
;;;
;;; bsdflayer (Beer-Lambert のクリアコート) の thickness を vfbm で斑に変調。
;;;   thick(P) = thick-base·(0.25 + mottle-amp·vfbm(Pg·mottle-scale, 3))
;;;   Cl = base × coat^(thick/cosθ)
;;; 薄い所は明るく透け、厚い所は沈む — 実物のべっ甲の透け方。
;;; さらに掠め角で全体が 1/cosθ で濃くなる (層の物理)。
;;;
;;; |I|=0 の退避: cosθ=1 (垂直入射扱い) — 斑は残り角度依存だけ消える。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfbekko)
;;;            (param base-color 0.95 0.78 0.42)
;;;            (param coat-color 0.55 0.22 0.05)
;;;            (param thick-base 1.1) (param mottle-scale 2.2)
;;;            (param mottle-amp 1.7) (param rough 0.12) (param metallic 0.25))

(setq bsdfbekko-shader

(make-shader bsdfbekko :keyword :volume
      (((base-color   color) (make-color 0.95 0.78 0.42))
       ((coat-color   color) (make-color 0.55 0.22 0.05))
       ((thick-base   float) 1.1)
       ((mottle-scale float) 2.2)
       ((mottle-amp   float) 1.7)
       ((rough        float) 0.12)
       ((metallic     float) 0.25))

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((mm float) 0.0) ((th float) 0.0) ((pl float) 0.0)
          ((ar float) 0.0) ((ag float) 0.0) ((ab float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    (setvar cv (clamp cv 0.08 1.0))
    (setvar cv (+ 1.0 (* vd (- cv 1.0))))     ; |I|=0 → 垂直入射扱い

    ;; 厚み斑 (fBm)。薄い所 0.25×〜厚い所 (0.25+amp)×
    (setvar mm (vfbm (* Pg mottle-scale) 3))
    (setvar th (* thick-base (+ 0.25 (* mottle-amp mm))))

    (setvar pl (/ th cv))
    (setvar ar (pow (clamp (comp coat-color 0) 0.001 1.0) pl))
    (setvar ag (pow (clamp (comp coat-color 1) 0.001 1.0) pl))
    (setvar ab (pow (clamp (comp coat-color 2) 0.001 1.0) pl))
    (setvar Cl (make-color (* (comp base-color 0) ar)
                           (* (comp base-color 1) ag)
                           (* (comp base-color 2) ab)))
    (setvar Oi (make-color rough metallic 0.0))
)))

(compile-shader bsdfbekko-shader)
(append-shader bsdfbekko-shader)
