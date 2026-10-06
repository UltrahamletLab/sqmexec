;;; shiny
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq shiny-shader

(make-shader shiny :keyword :surface
      (
	((Ka float) 0.3)
        ((Ks float) 0.8)
        ((Kr float) 1.0)
        ((roughness float) 0.01)
        ((map-name string) "")
       )
  (enter (((direction point) (reflect I (faceforward (normalize N) I)))
	  ((Nf point) (faceforward (normalize N) I))
	  ((NI point) (normalize I))
	  ((tr color) (make-color 0 0 0))
	  ((ev color) (make-color 0 0 0))
	  ((intersected float) 0))
    ;; Reflection trace
    (setvar tr (* Kr (trace P direction intersected)))
    ;; If ray didn't intersect any objects,
    ;; Do environment mapping
    (if (false? intersected)
	(if (string/= map-name "")
	    (setvar ev (environment map-name direction))
	    (setvar ev 0)))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* Ka (ambient))
		        (* Ks (+ (+ tr ev) (specular Nf (- NI) roughness))))))
)))

(compile-shader shiny-shader)
(append-shader shiny-shader)

