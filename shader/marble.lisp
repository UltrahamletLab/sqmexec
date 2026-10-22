;;; marble
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq marble-shader

(make-shader marble :keyword :surface
      (
	((Ks float) 0.5)
        ((Kd float) 0.5)
        ((Ka float) 1)
        ((roughness float) 0.01)
        ((reverse float) 0)
        ((magnify float) 1)
        ((texture-scale float) 1)
        ((marble-color color) (make-color 0 0 0))
        ((specular-color color) (make-color 1 1 1))
       )
  (enter (((PP point) 0)
	  ((turbulence float) 0)
	  ((octaves float) 7)
	  ((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I))))
    ;; Make turbulence noise
    (setvar PP (* Pg texture-scale))
    (setvar turbulence (turbulence PP octaves))
    ;; magnify?
    (if (true? magnify)
	(setvar turbulence (clamp (- (* 4 turbulence) 3) 0 1)))
    (if (< turbulence 0.9)
	(if (= reverse 0)
	    (setvar Ci (mix Cs marble-color turbulence))
	    (setvar Ci (mix marble-color Cs turbulence)))
	(setvar Ci (* Cs turbulence)))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* Ci (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
		        (* specular-color Ks (specular Nf Ir roughness)))))
)))

(compile-shader marble-shader)
(append-shader marble-shader)
