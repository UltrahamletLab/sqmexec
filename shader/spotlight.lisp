;;; spotlight
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


;;; 2026-08-09: BMRT spotlight.sl と比較 — 式は同一。ただし sqm の illuminate は
;;;   L を単位化するため **1/(L·L) が常に 1 = 逆二乗が死んでいた** (pointlight と同根)。
;;;   falloff (末尾追加, **既定 0 = 既存シーンの絵を変えない** — hand_spotlight 等が
;;;   現役のため。sentinel 解決で arealight/pointlight だけ既定 2) で opt-in 復活。
;;;   (falloff 2) と書けば距離減衰つきスポットになる (intensity は距離²のオーダー)。

(setq spotlight-shader

(make-shader spotlight :keyword :light
      (
	((intensity float) 1)
        ((light-color color) (make-color 1 1 1))
        ((from point) (make-point 1 1 -1))
        ((to point) (make-point 0 0 0))
        ((cone-angle float) (radians 30))
        ((cone-delta-angle float) (radians 5))
        ((beam-distribution float) 2)
        ((falloff float) 0)
       )
  (enter (((A point) (/ (- to from) (length (- to from))))
	  ((cos-outside float) (cos cone-angle))
	  ((cos-inside float) (cos (- cone-angle cone-delta-angle)))
	  ((atten float) 0)
	  ((dist float) 0)
	  ((cos-angle float) 0))
    (illuminate (from A cone-angle)
      (setvar cos-angle (/ (dot L A) (length L)))
      (setvar atten (/ (pow cos-angle beam-distribution) (dot L L)))
      (setvar atten (* atten (smoothstep cos-outside cos-inside cos-angle)))
      (if (> falloff 0.001)
          (progn
            (setvar dist (max (length (- P from)) 0.0001))
            (setvar atten (/ atten (pow dist falloff)))))
      (setvar Cl (* atten intensity light-color)))
)))

(compile-shader spotlight-shader)
(append-shader spotlight-shader)
