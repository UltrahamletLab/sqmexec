;;; anisotropy
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq anisotropy-shader

(make-shader anisotropy :keyword :surface
      (
	((Ka float) 1)
        ((Ks float) 1)
        ((weight float) 0.7)
        ((u-direction float) 0.15)
        ((v-direction float) 0.5)
       )
  (enter (((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I)))
	  ((spec1 color) (make-color 1 1 1))
	  ((spec2 color) (make-color 0 0 0)))
    (setcomp spec1 0 weight)
    (setcomp spec1 1 u-direction)
    (setcomp spec1 2 v-direction)
    (setvar Oi Os)
    (setvar Ci (* Os
		 Cs
		 (+ (* Ka (ambient))
		    (* Ks (links Nf Ir spec1 spec2)))))
)))

(compile-shader anisotropy-shader)
(append-shader anisotropy-shader)
