;;; fakesky_volume
;;; Sky gradient as a :volume atmosphere shader.
;;; No geometry required — works by blending Ci toward sky color
;;; based on the ray direction (I).
;;;
;;; Place as (atmosphere fakesky_volume ...) in camera block.
;;; No sphere needed. No shadow interference.

(setq fakesky-volume-shader

(make-shader fakesky_volume :keyword :volume
      (((up       point) (make-point 0 1 0))
       ((skycolor color) (make-color 0.40 0.60 1.0))
       ((strength float) 1.0))

  (enter (
    ((dir   point) (normalize I))
    ((d     float) (dot up dir))
    ;; max(0, d) via abs
    ((dc    float) (* 0.5 (+ d (abs d))))
    ;; sky brightness: 0.5 at horizon, 1.0 at zenith
    ((sky   color) (* (* strength 1.8) skycolor (+ 0.5 (* 0.5 dc)))))

  ;; Where Oi is near 0 (sky background, no surface hit),
  ;; replace Ci with sky gradient.
  ;; (1-Oi) = sky portion, Oi*Ci = surface portion
  (setvar Ci (+ (* Oi Ci) (* (- 1.0 Oi) sky)))
  (setvar Oi 1.0))))

(compile-shader fakesky-volume-shader)
(append-shader fakesky-volume-shader)
