;;; thunder
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq thunder-shader

(make-shader thunder :keyword :surface
      (
	((Ks float) 0.5)
        ((Kd float) 0.5)
        ((Ka float) 1)
        ((roughness float) 0.01)
        ((reverse float) 0)
        ((thunder-turbulence float) 1)
        ((specular-color color) (make-color 1 1 1))
        ((thunder-color color) (make-color 0 0 0))
       )
  (enter (((tn float) 0)
	  ((octaves float) 6)
	  ((offset float) 0)
	  ((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I))))
    ;; Make turbulence noise
    (setvar tn (+ (xcomp Pg) (* (turbulence Pg octaves) thunder-turbulence)))
    (if (>= tn 0.0)
	(setvar offset (- tn (floor tn)))
	(setvar offset (- tn (- -1.0 (floor (abs tn))))))
    (if (>= offset 0.5)
	(setvar tn (* 2.0 (- 1.0 offset)))
	(setvar tn (* 2.0 offset)))
    (if (< tn 0.9)
	(if (= reverse 0)
	    (setvar Ci (mix Cs thunder-color tn))
	    (setvar Ci (mix thunder-color Cs tn)))
	(setvar Ci (* Cs tn)))
    (setvar Oi Os)
    (setvar Ci (* Os (+ (* Ci (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
		        (* specular-color Ks (specular Nf Ir roughness)))))
)))

(compile-shader thunder-shader)
(append-shader thunder-shader)
