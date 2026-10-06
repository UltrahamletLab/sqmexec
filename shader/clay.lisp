;;; clay — 素焼きの粘土 (Oren-Nayar 拡散)
;;;
;;; 移植元: BMRT clay.sl + material.h の MaterialClay
;;;         + locillum.h の LocIllumOrenNayar
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;;   Ci = Cs * (Ka*ambient() + Kd*OrenNayar(Nf, -I, roughness))
;;;   Oren-Nayar: 微細な凹凸を持つ拡散面。Lambert より陰影の落ち込みが平坦で、
;;;   視線と光が同じ側に傾くと明るくなる (満月が縁まで明るいのと同じ理屈)。
;;;     σ² = roughness²
;;;     A = 1 − 0.5σ²/(σ²+0.33)     B = 0.45σ²/(σ²+0.09)
;;;     C = Σ Cl·cosθi·(A + B·max(0,cosφ)·sin(α)·tan(β))
;;;         α = max(θi,θr), β = min(θi,θr), cosφ = 接平面内の V と L の向きの一致
;;;   roughness 0 で A=1, B=0 → **Lambert に厳密に一致** (検証に使える)。
;;;
;;; ── sqm 版の違い ────────────────────────────────────────────────
;;; ・illuminance は (lightcount)/(lightsel) で回す (illuminance 系3例目)。
;;;   lightsource("__nondiffuse") 相当は無いので落とした。
;;; ・縮退 (V∥N や L∥N で normalize(0)) はガード不要 — その時 β=0 → tan(β)=0 で
;;;   B 項ごと消えるため、normalize フックの既定値 (0,0,1) が混入しても寄与ゼロ。
;;; ・視線も光も掠め角のとき tan(β) が跳ねるのは**原典どおり** (忠実に残した)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の clay_params[] と一致必須):
;;;   Ka=0 Kd=1 roughness=2
;;;
;;; 使い方 (シーン):
;;;   (surface (color 0.62 0.44 0.32) (ka 0.2) (kd 0.7) (ks 0) (phong 0)
;;;            (shader clay) (param roughness 0.5))
;;;   ※ (phong 0) にすること (phong>0 は roughness を 1/phong で上書きする)。

(setq clay-shader

(make-shader clay :keyword :surface
      (
       ((Ka        float) 1.0)
       ((Kd        float) 0.7)
       ((roughness float) 0.1)
       )

  (enter (((Nf    point) (faceforward (normalize N) I))
          ((Vd    point) (normalize (- I)))
          ((sig2  float) (* roughness roughness))
          ((oa    float) 0.0) ((ob float) 0.0)
          ((vn    float) 0.0) ((thr float) 0.0)
          ((Vperp point) (make-point 0 0 1))
          ((nl    float) 0.0) ((j float) 0.0) ((g float) 0.0)
          ((LN    point) (make-point 0 0 1))
          ((cti   float) 0.0) ((cpd float) 0.0)
          ((thi   float) 0.0) ((al float) 0.0) ((be float) 0.0)
          ((dsum  color) (make-color 0 0 0)))

    (setvar oa (- 1.0 (/ (* 0.5 sig2) (+ sig2 0.33))))
    (setvar ob (/ (* 0.45 sig2) (+ sig2 0.09)))
    (setvar vn (dot Vd Nf))
    (setvar thr (acos (clamp vn -1.0 1.0)))
    (setvar Vperp (normalize (- Vd (* Nf vn))))

    ;; ── illuminance: 光源ごとに Oren-Nayar を積む ──────────────────
    (setvar nl (lightcount))
    (repeat (j nl)
      (setvar g (lightsel j))            ; L (面→光源, 単位)・Cl (可視度込み)
      (setvar LN (normalize L))
      (setvar cti (dot LN Nf))
      (setvar cpd (dot Vperp (normalize (- LN (* Nf cti)))))
      (setvar thi (acos (clamp cti -1.0 1.0)))
      (setvar al (max thi thr))
      (setvar be (min thi thr))
      (setvar dsum (+ dsum (* Cl (* (max cti 0.0)
                                    (+ oa (* ob (* (max cpd 0.0)
                                                   (* (sin al) (tan be))))))))))

    (setvar Oi Os)
    (setvar Ci (* Oi (* Cs (+ (* Ka (ambient)) (* Kd dsum)))))
)))

(compile-shader clay-shader)
(append-shader clay-shader)
