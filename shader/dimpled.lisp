;;; dimpled
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq dimpled-shader

(make-shader dimpled :keyword :bump
      (
	((reverse float) 0)
        ((s-frequency float) 12)
        ((t-frequency float) 7)
      )
  (enter ((Nh point)
	  ((radius float) 0.35)
	  ((hole-center float) 0.5)
	  ((smod float) (- (mod (* s s-frequency) 1) hole-center))
	  ((tmod float) (- (mod (* t t-frequency) 1) hole-center))
	  ((length float) (sqrt (+ (* smod smod) (* tmod tmod)))))
    ;; The reverse is Blistered
    (if (= reverse 0)
	(progn
	  (setvar smod (- smod))
	  (setvar tmod (- tmod))))
    ;; Is this pit region?
    (if (<= length radius)
	(progn
	  (setvar Nh (* (normalize (+ (* dPdu smod) (* dPdv tmod))) length))
	  (setvar Nh (normalize (+ Nh (* (normalize N) (- radius length)))))
	  (setvar N Nh)))
    ;; normalize
    (setvar N (normalize N))
)))

(compile-shader dimpled-shader)
(append-shader dimpled-shader)
