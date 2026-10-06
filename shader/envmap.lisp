;;; envmap
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;; All rights reserved.

(setq envmap-shader

(make-shader envmap :keyword :surface
      (
	((Ka float) 1)
        ((Ks float) 1)
        ((roughness float) 0.02)
        ((intensity float) 0.5)
        ((angle float) 0.0)
        ((map-name string) "")
       )
  (enter ((temp point)
	  ((direction point) (normalize N))
	  ((Nf point) (faceforward (normalize N) I))
	  ((NI point) (normalize I))
	  ((rad float) (radians angle))
	  ((ev color) (make-color 0 0 0)))
    ;; rotate direction for u-angle
    (setvar temp direction)
    (setxcomp direction (- (* (xcomp temp) (cos rad))
			   (* (zcomp temp) (sin rad))))
    (setzcomp direction (+ (* (xcomp temp) (sin rad))
			   (* (zcomp temp) (cos rad))))
    ;; Do environment mapping
    (if (string/= map-name "")
	(setvar ev (environment map-name direction))
        (setvar ev 0))
    (setvar Oi Os)
    (setvar Ci (* Os Cs (+ (* Ka (ambient))
			   (* Ks (+ (* ev intensity) (specular Nf (- NI) roughness))))))
)))

(compile-shader envmap-shader)
(append-shader envmap-shader)
