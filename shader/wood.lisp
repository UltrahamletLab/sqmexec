;;; wood
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq wood-shader

(make-shader wood :keyword :surface
      (
	((Ks float) 0.6)
        ((Kd float) 0.4)
        ((Ka float) 1)
        ((roughness float) 0.05)
        ((ring-scale float) 10)
        ((light-wood color) (make-color 0.3 0.12 0.03))
        ((dark-wood color) (make-color 0.05 0.01 0.005))
        ((vertical float) 0)                       ; 1 = 年輪軸を縦(y)に。既定0=従来(x軸)
        ((ring-offset color) (make-color 0 0 0))   ; 縦木目時の年輪軸位置 (ox, oz, 未使用)
       )
  (enter (((NN point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I)))
	  ((PP point) Pg)
	  ((y float) 0)
	  ((z float) 0)
	  ((r float) 0))
    (setvar PP (+ PP (noise PP)))

    (setvar y (ycomp PP))
    (setvar z (zcomp PP))
    (if (true? vertical)
	(setvar y (- (xcomp PP) (comp ring-offset 0))))
    (if (true? vertical)
	(setvar z (- z (comp ring-offset 1))))
    (setvar r (sqrt (+ (* y y) (* z z))))

    (setvar r (* r ring-scale))
    (setvar r (+ r (abs (noise r))))
    (setvar r (- r (floor r)))  ; = (mod r 1)

    (setvar r (- (smoothstep 0 0.8 r) (smoothstep 0.83 1 r)))
    (setvar Ci (mix light-wood dark-wood r))

    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* Ci (+ (* Ka (ambient)) (* Kd (diffuse NN))))
		        (* (+ (* 0.3 r) 0.7) Ks (specular NN Ir roughness)))))
)))

(compile-shader wood-shader)
(append-shader wood-shader)
