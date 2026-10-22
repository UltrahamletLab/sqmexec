;;; matte
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq matte-shader

(make-shader matte :keyword :surface
      (
       ((Ka float) 1)
       ((Kd float) 1)
       )
  (enter (((Nf point) (faceforward (normalize N) I)))
    (setvar Oi Os)
    (setvar Ci (* Os Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))
)))

(compile-shader matte-shader)
(append-shader matte-shader)
