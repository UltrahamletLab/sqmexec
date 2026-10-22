;;; metal
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq metal-shader

(make-shader metal :keyword :surface
      (
	((Ka float) 1)
        ((Ks float) 1)
        ((roughness float) 0.25)
       )
  (enter (((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I))))
    (setvar Oi Os)
    (setvar Ci (* Os
		  Cs
		  (+ (* Ka (ambient)) (* Ks (specular Nf Ir roughness)))))
)))

(compile-shader metal-shader)
(append-shader metal-shader)
