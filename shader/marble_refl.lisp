;;; marble_refl
;;; Marble surface shader with ray-traced reflections.
;;; Based on the standard marble shader, adding a Kr reflection term.

(setq marble-refl-shader

(make-shader marble_refl :keyword :surface
      (((Ks             float)  0.5)
       ((Kd             float)  0.5)
       ((Ka             float)  0.3)
       ((Kr             float)  0.35)   ; 反射率
       ((roughness      float)  0.012)
       ((texture-scale  float)  1.0)
       ((magnify        float)  1)
       ((marble-color   color)  (make-color 0 0 0))
       ((specular-color color)  (make-color 1 1 1)))

  (enter (
    ((PP           point) 0)
    ((turbulence   float) 0)
    ((octaves      float) 7)
    ((Nf           point) (faceforward (normalize N) I))
    ((Ir           point) (normalize (- I)))
    ((R            point) (reflect I Nf))
    ((intersected  float) 0.0)
    ((refl         color) (make-color 0 0 0))
    ((base-color   color) (make-color 0 0 0)))

    ;; turbulence ノイズで大理石模様 (P=ワールド座標で一貫したパターン)
    (setvar PP (* P texture-scale))
    (setvar turbulence (turbulence PP octaves))
    (if (true? magnify)
      (setvar turbulence (clamp (- (* 4 turbulence) 3) 0 1)))

    (if (< turbulence 0.9)
      (setvar base-color (mix Cs marble-color turbulence))
      (setvar base-color (* Cs turbulence)))

    ;; 反射トレース
    (setvar refl (* Kr (trace P R intersected)))

    (setvar Oi Os)
    (setvar Ci (* Oi
                  (+ (* base-color
                        (+ (* Ka (ambient))
                           (* Kd (diffuse Nf))))
                     (* specular-color Ks (specular Nf Ir roughness))
                     refl))))))

(compile-shader marble-refl-shader)
(append-shader marble-refl-shader)
