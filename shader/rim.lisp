;;; rim
;;;
;;; Copyright (C) 1993, Toshiaki Arimura
;;;  all rights reserved.


(setq rim-shader

(make-shader rim :keyword :surface
      (((Kd float) 1)
       ((rim_width float) 0.5))
  (enter (((Nf point) (faceforward (normalize N) I)) 
          ((II point) (normalize (- I)))
          ((dotval float) (- 1 (dot II Nf))))
;
  (setvar Oi (smoothstep (- 1 rim_width) 1.0 dotval))
  (setvar Ci (* Oi Cs))))
)

(compile-shader rim-shader)
(append-shader rim-shader)
