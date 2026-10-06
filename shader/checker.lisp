;;; checker
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq checker-shader

(make-shader checker :keyword :surface
      (
	((Kd float) 1)
        ((Ka float) 1)
        ((frequency float) 7)
        ((black-color color) (make-color 0 0 0))
      )
  (enter (((smod float) (mod (* s frequency) 1))
	  ((tmod float) (mod (* t frequency) 1)))
    (if (< smod 0.5)
	(if (< tmod 0.5) (setvar Ci Cs) (setvar Ci black-color))
	(if (< tmod 0.5) (setvar Ci black-color) (setvar Ci Cs))
     )
    (setvar Oi Os)
    (setvar Ci (* Oi Ci (+ (* Ka (ambient))
			   (* Kd (diffuse (faceforward (normalize N) I))))))
)))

(compile-shader checker-shader)
(append-shader checker-shader)
