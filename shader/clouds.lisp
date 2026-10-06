;;; clouds
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  all rights reserved.


(setq clouds-shader

(make-shader clouds :keyword :surface
      (
	((Ka float) 1)
        ((Kd float) 1)
       ((clouds-color color) (make-color 0.5 0.5 0.5))
       )
  (enter (((sum float) 0.0)
	  ((times float) 0)
	  ((freq float) 4.0)
	  ((Nf point) (faceforward (normalize N) I)))
    (while (< times 6)
      (setvar sum (+ sum (* (/ 1.0 freq) (abs (- 0.5 (noise (* freq P)))))))
      (setvar freq (* 2 freq))
      (setvar times (+ times 1)))
    (setvar Ci (mix Cs clouds-color (* sum 4.0)))
    (setvar Oi 1.0)
    (setvar Ci (* Oi Ci (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))
)))

(compile-shader clouds-shader)
(append-shader clouds-shader)
