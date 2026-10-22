;;; background — 前景の無い画素を単色で埋める imager シェーダー
;;;
;;; 移植元: BMRT background.sl
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;;   imager background (color bgcolor = 1, background = 1)
;;;   {
;;;       Ci += (1-alpha) * (bgcolor * background);
;;;       Oi = 1;
;;;       alpha = 1;
;;;   }
;;;
;;; `:imager` は 2026-08-09 に新設したクラスで、**トーンマップ前の画素ごと**に
;;; 1回呼ばれる (sqm 側 dr_imager_pixel)。読み替えは:
;;;   Ci    = 画素の色 (rw)        Oi = 不透明度 (rw)
;;;   alpha = 被覆率 0..1 (rw)     P  = ラスタ座標 (x, y, 0)
;;;   u, v  = 正規化ラスタ座標 0..1
;;; Oi / alpha への書き戻しは現状 sqm が使わない (PNG は 3ch)。原典の意図を残す
;;; ためにそのまま書いている。
;;;
;;; ⚠ **シーンでは (background 0 0 0) にすること**。sqm はレイが外れた時点で
;;; シーンの背景色を Ci に書き込み済みなので、原典どおり `+=` するとその上に
;;; 足し算になる。原典の前提 (前景の無い画素は黒) に合わせて初めて置き換えになる。

(setq background-shader

(make-shader background :keyword :imager
      (
       ((bgcolor    color) (make-color 1 1 1))   ; 背景色
       ((background color) (make-color 1 1 1))   ; 倍率 (原典どおり色)
       )

  (enter ()
    (setvar Ci (+ Ci (* (- 1 alpha) (* bgcolor background))))
    (setvar Oi (make-color 1 1 1))
    (setvar alpha 1))))

(compile-shader background-shader)
(append-shader background-shader)
