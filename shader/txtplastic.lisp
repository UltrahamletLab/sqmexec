;;; txtplastic
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq txtplastic-shader

(make-shader txtplastic :keyword :surface
      (
	((Ks float) 0.5)
        ((Kd float) 0.5)
        ((Ka float) 1)
        ((roughness float) 0.01)
        ((specular-color color) 1)
        ((map-name string) "")
      )
  (enter (((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I))))
    (if (string/= map-name "")
	(setvar Ci (texture map-name))
	(setvar Ci Cs))
    (setvar Oi Os)
    (setvar Ci (* Os
                  (+ (* Ci (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                     (* specular-color Ks (specular Nf Ir roughness)))))
)))

(compile-shader txtplastic-shader)
(append-shader txtplastic-shader)
