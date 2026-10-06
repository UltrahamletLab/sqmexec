;;; ramp
;;;
;;; Copyright (C) 1993, Toshiaki Arimura
;;;  all rights reserved.
(setq ramp-shader

(make-shader ramp :keyword :surface
      (((Kfb float) 1)
       ((spacename string) "world")
       ((top color) (make-color 1.0 0.0 0.0))
       ((lower color) (make-color 0.9 0.9 0.0)))
       (enter (((surfcolor color) (mix top lower t)))
    (setvar Ci (* Oi Cs surfcolor Kfb))))
)

(compile-shader ramp-shader)
(append-shader ramp-shader)
