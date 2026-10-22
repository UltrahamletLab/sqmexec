;;; constant
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq constant-shader

(make-shader constant :keyword :surface
      ()
  (enter ()
    (setvar Oi Os)
    (setvar Ci (* Os Cs))
)))

(compile-shader constant-shader)
(append-shader constant-shader)
