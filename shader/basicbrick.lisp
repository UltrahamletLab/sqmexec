;;; basicbrick
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq basicbrick-shader

(make-shader basicbrick :keyword :surface
      (
	((Ks float) 0.6)
        ((Kd float) 0.4)
        ((Ka float) 1)
        
       )
  (enter (((NN point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I)))
	  ((PP point) Pg)
          ((float x) 0)
          ((float y) 0)
	  ((tilewidth   float) 0)
          ((tileheight  float) 0)
          ((rowstagger      float) 0)
          ((rowstaggervary  float) 0)
          ((jaggedfreq  float) 0)
          ((jaggedamp      float) 0)
          ((column  float) 0)
          ((row     float) 0)
          ((xtile  float) 0)
          ((ytile  float) 0))
    ;;
    (setvar PP (+ PP (noise PP)))

    (setvar y (ycomp PP))
    (setvar z (zcomp PP))
    (setvar r (sqrt (+ (* y y) (* z z))))

    (setvar r (* r ring-scale))
    (setvar r (+ r (abs (noise r))))
    (setvar r (- r (floor r)))  ; = (mod r 1)

    (setvar r (- (smoothstep 0 0.8 r) (smoothstep 0.83 1 r)))
    (setvar Ci (mix light-basicbrick dark-basicbrick r))

    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* Ci (+ (* Ka (ambient)) (* Kd (diffuse NN))))
		        (* (+ (* 0.3 r) 0.7) Ks (specular NN Ir roughness)))))
)))

(compile-shader basicbrick-shader)
(append-shader basicbrick-shader)
