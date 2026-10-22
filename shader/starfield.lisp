;;; starfield
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq starfield-shader

(make-shader starfield :keyword :surface
      (
       ((frequency float) 8)
       ((intensity float) 3)
       ((pswidth float) 0.4)
       )
  (enter (
         ((PP point) (make-point 0 0 0))
         ((val float) 0)
         )
        (setvar PP (* frequency P))
        (setvar val (smoothstep (- 1 pswidth) 1 (noise PP)))
        (setvar Oi Os)
        (setvar Ci (* intensity val val Cs))
)))

(compile-shader starfield-shader)
(append-shader starfield-shader)
