;;; distantlight
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq shadowlight-shader

(make-shader shadowlight :keyword :light
      (
	((intensity float) 1)
        ((light-color color) (make-color 1 1 1))
        ((from point) (make-point 1 1 -1))
        ((to point) (make-point 0 0 0))
       )
  (enter ()
    (solar ((- to from) 0)
      (setvar Cl (* intensity light-color (- 1 (shadow P)))))
  )))

(compile-shader shadowlight-shader)
(append-shader shadowlight-shader)
