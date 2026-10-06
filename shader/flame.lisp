;;; flame
;;;
;;; Copyright (C) 1993, Toshiaki Arimura
;;;  all rights reserved.
(setq flame-shader

(make-shader flame :keyword :surface
      (((Kfb float) 1)
       ((freq float) 6.0)
       ((spacename string) "world")
       ((top color) (make-color 1.0 0.0 0.0))
       ((lower color) (make-color 0.9 0.9 0.0)))
    (enter (((surfcolor color) (mix top lower t))
    ((PP point) 0))
    (setvar PP (* (transform spacename P) freq))
    ;(setvar PP (transform spacename P))
    ;(if (> t (noise (* freq PP))) (setvar Oi Os) (setvar Oi 0)) 
    (if (> t (noise PP)) (setvar Oi Os) (setvar Oi 0)) 
    (setvar Ci (* Oi Cs surfcolor Kfb))))
)

(compile-shader flame-shader)
(append-shader flame-shader)
