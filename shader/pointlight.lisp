;;; pointlight
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


;;; 2026-08-09: BMRT pointlight.sl と比較 — 式は同一だが、sqm の illuminate は
;;;   L を単位化して渡すため **1/(L·L) が常に 1 = 逆二乗が死んでいた**
;;;   (arealight 移植で確定した罠)。距離を length(P - from) から復元し、
;;;   falloff (末尾追加, 既定 2 = 原典の逆二乗) で復活させた。
;;;   ・このシェーダーが呼ばれるのは **(dr-shader pointlight) と明示した時だけ**
;;;     (標準ライトは dr_light_eval が素通しして C 側 light_dir で処理) →
;;;     既存シーンへの影響ゼロ。逆二乗なので intensity は距離²のオーダーで与える。
;;;   ・(falloff 0) で減衰なし = 標準ライトと同じスケール。

(setq pointlight-shader

(make-shader pointlight :keyword :light
      (
	((intensity float) 1)
        ((light-color color) (make-color 1 1 1))
        ((from point) (make-point 0 0 0))
        ((falloff float) 2))     ; 距離減衰の指数 (2=原典の逆二乗 / 0=減衰なし)
  (enter (((dist float) 0))
    (illuminate (from)
      (setvar Cl (/ (* intensity light-color) (dot L L)))
      (if (> falloff 0.001)
          (progn
            (setvar dist (max (length (- P from)) 0.0001))
            (setvar Cl (/ Cl (pow dist falloff))))))
)))

(compile-shader pointlight-shader)
(append-shader pointlight-shader)
