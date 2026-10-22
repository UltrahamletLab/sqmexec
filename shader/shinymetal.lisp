;;; shinymetal
;;; Shiny metal surface shader — no diffuse, sharp specular + ray-traced reflection.
;;;
;;; Converted from:
;;;   shinymetal.sl + material.h (BMRT)
;;;   (c) 1990-2000 Exluna, Inc. / Larry Gritz
;;;
;;; DR addition: Kr * trace(P, R) for ray-traced reflections

(setq shinymetal-shader

(make-shader shinymetal :keyword :surface
      (((Ka        float)  1.0)
       ((Ks        float)  1.0)
       ((Kr        float)  0.6)   ; 反射率
       ((roughness float)  0.1))

  (enter (
    ((Nf          point) (faceforward (normalize N) I))
    ((Ir          point) (normalize (- I)))
    ((R           point) (reflect I Nf))        ; 反射方向
    ((intersected float) 0.0)
    ((refl        color) (make-color 0 0 0)))

    ;; 反射トレース
    (setvar refl (* Kr (trace P R intersected)))

    (setvar Oi Os)
    (setvar Ci (* Os Cs
                   (+ (* Ka (ambient))
                      (* Ks (specular Nf Ir roughness))
                      refl))))))

(compile-shader shinymetal-shader)
(append-shader shinymetal-shader)
