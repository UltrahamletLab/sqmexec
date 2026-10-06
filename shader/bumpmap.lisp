;;; bumpmap
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq bumpmap-shader

(make-shader bumpmap :keyword :bump
       (
	((map-name string) "")
        ;; ⚠ **末尾に足すこと** — 途中に挿すと index がずれて
        ;;   shade_dr.cpp の bumpmap_bparams と食い違う (2026-08-05 追加)
        ((amount   float)  1.0)
        ;; 差分幅 (テクセル)。JPEG の高さマップはブロックノイズを微分が
        ;; 増幅するので、粗い起伏だけ欲しいときは広げる (8 = JPEG ブロック幅)
        ((step     float)  2.0)
        )
  (enter (((Nb point) (normalize N)))
    (if (string/= map-name "")
	;; Make simple bump by bump map
	(setvar N (bump map-name)))
)))

(compile-shader bumpmap-shader)
(append-shader bumpmap-shader)
