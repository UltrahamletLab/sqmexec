;;; paintedplastic.lisp — BMRT paintedplastic.sl port.
;;; A plastic material whose base color is optionally multiplied by a 2D texture.
;;; UV comes from mesh vt (or sqm's fallback mapping for non-UV geometry).

(setq paintedplastic-shader
(make-shader paintedplastic :keyword :surface
  (((Ka float) 1.0)
   ((Kd float) 0.5)
   ((Ks float) 0.5)
   ((roughness float) 0.1)
   ((specularcolor color) (make-color 1 1 1))
   ((texturename string) ""))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((paint color) (make-color 1 1 1)))
    (setvar paint Cs)
    (if (string/= texturename "")
        (setvar paint (* paint (texture texturename))))
    (setvar Oi Os)
    (setvar Ci (* Oi
                  (+ (* paint (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                     (* specularcolor Ks (specular Nf Ir roughness))))))))

(compile-shader paintedplastic-shader)
(append-shader paintedplastic-shader)
