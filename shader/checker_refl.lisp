;;; checker_refl
;;; Checker shader with ray-traced reflections.

(setq checker-refl-shader

(make-shader checker_refl :keyword :surface
      (((Kd        float)  1.0)
       ((Ka        float)  1.0)
       ((Kr        float)  0.4)   ; 反射率
       ((frequency float)  7.0)
       ((black-color color) (make-color 0 0 0)))

  (enter (
    ((Nf          point) (faceforward (normalize N) I))
    ((smod        float) (mod (* s frequency) 1))
    ((tmod        float) (mod (* t frequency) 1))
    ((base-color  color) (make-color 0 0 0))
    ((R           point) (reflect I Nf))
    ((intersected float) 0.0)
    ((refl        color) (make-color 0 0 0)))

    ;; checker パターン
    (if (< smod 0.5)
      (if (< tmod 0.5) (setvar base-color Cs) (setvar base-color black-color))
      (if (< tmod 0.5) (setvar base-color black-color) (setvar base-color Cs)))

    ;; 反射トレース
    (setvar refl (* Kr (trace P R intersected)))

    (setvar Oi Os)
    (setvar Ci (* Oi
                  (+ (* base-color (+ (* Ka (ambient))
                                      (* Kd (diffuse Nf))))
                     refl))))))

(compile-shader checker-refl-shader)
(append-shader checker-refl-shader)
