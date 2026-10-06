;;; links
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq links-shader

(make-shader links :keyword :surface
      (
       ((Ks float) 0.5)
       ((Kd float) 0.5)
       ((Ka float) 1)
       ((roughness float) 0.07)
       ((specular-color color) (make-color 1 1 1))
      )
  (enter (((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I)))
	  ((spec1 color) (make-color 1 roughness roughness))
	  ((spec2 color) (make-color 1 roughness roughness)))
    (setvar Oi Os)
    (setvar Ci (* Os (+ (* Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* specular-color Ks (links Nf Ir spec1 spec2)))))
)))

(compile-shader links-shader)
(append-shader links-shader)
