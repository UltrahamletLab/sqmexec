;;; spotted
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq spotted-shader

(make-shader spotted :keyword :surface
      (
       ((Ka float) 1)
       ((Kd float) 1)
       ((spotted-scale float) 7)
       )
  (enter (((Nf point) (faceforward (normalize N) I)))
    (setvar Ci (* Cs (noise (* spotted-scale Pg))))
    (setvar Oi Os)
    (setvar Ci (* Os Ci (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))

)))

(compile-shader spotted-shader)
(append-shader spotted-shader)
