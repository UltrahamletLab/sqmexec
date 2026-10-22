;;; plastic
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq plastic-shader

(make-shader plastic :keyword :surface
      (
	((Ks float) 0.5)
        ((Kd float) 0.5)
        ((Ka float) 1)
        ((roughness float) 0.01)
        ((specular-color color) (make-color 1 1 1))
      )
  (enter (((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I))))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
		        (* specular-color Ks (specular Nf Ir roughness)))))
   )))

(compile-shader plastic-shader)
(append-shader plastic-shader)
