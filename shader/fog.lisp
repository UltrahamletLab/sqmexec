;;; fog — 指数フォグ (atmosphere 用 :volume)
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;; All rights reserved.
;;;
;;; 2026-08-09: BMRT fog.sl と比較 — 式は同一 (1-exp(-|I|/distance)) で本版を残す。
;;;   配線 (fog_vparams) も距離 (length I = カメラ距離) も既に正しい。
;;;   原典末尾の `Oi = mix(Oi, 1, d)` は移植しない — sqm の atmosphere_shade は
;;;   Ci しか読み戻さず (Oi は α 用で PNG 3ch に消費者が無い)、死コードになるため。
;;;   線形版 depthcue との使い分けは docs/2026-08-09_depthcue_比較と修理.md。


(setq fog-shader

(make-shader fog :keyword :volume
      (
	((distance float) 1)
        ((background color) 0)
      )
  (enter (((d float) (- 1 (exp (/ (- (length I)) distance)))))
  (setvar Ci (mix Ci background d))
)))

(compile-shader fog-shader)
(append-shader fog-shader)
