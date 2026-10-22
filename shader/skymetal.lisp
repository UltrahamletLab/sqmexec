;;; skymetal.lisp — SIGGRAPH 1991 Course 21 "Sig91_skymetal" の移植
;;;
;;; 空/地面の2半球グラデーションを反射方向で混ぜるだけの古典クロム。
;;; 実トレース無しで「空を映す金属」に見える (RenderManShader/Sig91_skymetal.sl)。
;;; 原典の up パラメータは sqm のワールド +y に固定 (ycomp(reflect) = costheta)。
;;; if が color を返す構文は避け、step で両半球を blend する (aniso の教訓)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の skymetal_params[] と一致必須):
;;;   Ka=0 Ks=1 Kr=2 roughness=3 sky-zenith=4 sky-horiz=5 land-horiz=6 land-zenith=7

(setq skymetal-shader
(make-shader skymetal :keyword :surface
  (((Ka float) 1.0)
   ((Ks float) 1.0)
   ((Kr float) 0.2)
   ((roughness float) 0.1)
   ((sky-zenith  color) (make-color 0.125 0.162 0.5))
   ((sky-horiz   color) (make-color 0.4 0.45 0.8))
   ((land-horiz  color) (make-color 0.0281 0.0287 0.0220))
   ((land-zenith color) (make-color 0 0 0)))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((rdir point) (normalize (reflect I (faceforward (normalize N) I))))
    ((ct float) 0) ((ctu float) 0) ((ctd float) 0) ((sel float) 0)
    ((refl color) (make-color 0 0 0)))
    (setvar ct (ycomp rdir))
    (setvar ctu (clamp ct 0 1))
    (setvar ctd (clamp (- 0 ct) 0 1))
    ;; costheta>=0 → mix(sky-horiz, sky-zenith, ct) / 負 → mix(land-horiz, land-zenith, -ct)
    (setvar sel (step 0 ct))
    (setvar refl (mix (mix land-horiz land-zenith ctd)
                      (mix sky-horiz sky-zenith ctu) sel))
    (setvar Oi Os)
    (setvar Ci (* Oi Cs (+ (* Kr refl)
                           (* (- 1 Kr)
                              (+ (* Ka (ambient))
                                 (* Ks (specular Nf Ir roughness))))))))))
(compile-shader skymetal-shader)
(append-shader skymetal-shader)
