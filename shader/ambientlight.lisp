;;; ambientlight
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq ambientlight-shader

(make-shader ambientlight :keyword :light
	(
	((intensity float) 0.2)
        ((light-color color) (make-color 1 1 1))
	)
(enter ()
    (setvar Cl (* intensity light-color))
)))

(compile-shader ambientlight-shader)
(append-shader ambientlight-shader)
