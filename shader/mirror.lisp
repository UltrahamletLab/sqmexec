;;; mirror
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq mirror-shader

(make-shader mirror :keyword :surface
      (
	((Kr float) 1.0)
        ((map-name string) "")
       )
  (enter (((direction point) (reflect I (faceforward (normalize N) I)))
	  ((intersected float) 0))
    (setvar Oi Os)
    (setvar Ci (* Kr (trace P direction intersected)))
    ;; If ray didn't intersect any objects,
    ;; Do environment mapping
    (if (false? intersected)
	(if (string/= map-name "")
	    (setvar Ci (environment map-name direction))
	    (setvar Ci 0)))
)))

(compile-shader mirror-shader)
(append-shader mirror-shader)
