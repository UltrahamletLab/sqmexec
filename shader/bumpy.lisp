;;; bumpy
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq bumpy-shader

(make-shader bumpy :keyword :bump
      (
	((bumpy-scale float) 7)
       )
  (enter (((Nb point) (normalize N)))
    ;; Make simple bump by noise
    (setvar N (normalize (+ Nb (noise (* bumpy-scale Pg) point))))
)))

(compile-shader bumpy-shader)
(append-shader bumpy-shader)
