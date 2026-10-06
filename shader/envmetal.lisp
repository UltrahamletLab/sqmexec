;;; envmetal
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;; All rights reserved.

(setq envmetal-shader

(make-shader envmetal :keyword :surface
      (
       ((Ka float) 1)
       ((Ks float) 1)
       ((roughness float) 0.02)
       ((intensity float) 0.5)
       ((angle float) 0.0)
       ((map-name string) "")
       )
  (enter ((temp point)
	  ((direction point) (reflect I (faceforward (normalize N) I)))
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
    ;; Do environment mapping — always call environment()
    ;; (sqm provides procedural sky; map-name unused)
    (setvar ev (environment map-name direction))
    (setvar Oi Os)
    (setvar Ci (* Os Cs (+ (* Ka (ambient))
			   (* Ks (+ (* ev intensity) (specular Nf (- NI) roughness))))))
)))

(compile-shader envmetal-shader)
(append-shader envmetal-shader)
