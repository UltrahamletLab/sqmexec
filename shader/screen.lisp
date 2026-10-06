;;; screen — 金属メッシュ (格子スクリーン)。穴は Oi=0 のカットアウト。
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.
;;;
;;; 2026-08-09: BMRT screen_aa.sl の移植依頼で精査 —
;;;   ・1993 版と screen_aa は同じ格子 (screen_aa は帯がサイクル境界中心で
;;;     位相が density/2 ずれるだけ)。差分は**微分ベースの AA** のみ。
;;;   ・sqm に微分は無いので、AA は **(param fuzz 0.02)** の opt-in で導入
;;;     (screen_aa 流の中心合わせ帯 + smoothstep 縁。既定 0 = 1993 版とビット一致)。
;;;     fuzz の縁は Oi が 0..1 の中間値になる = sqm では屈折ブレンド → 複数枚
;;;     重ねるときは -D を上げる (Oi 半透明の既知の作法)。
;;;   ・param テーブルが shade_dr.cpp に無く ka/kd/ks/(param ..) が全部不通だった
;;;     → screen_params を配線 (孤児配線の修理は roughmetal に続き2件目)。
;;;
;;; パラメータ定義順 (shade_dr.cpp screen_params[] と一致必須):
;;;   Ks=0 Kd=1 Ka=2 roughness=3 density=4 frequency=5 specular-color=6 fuzz=7

(setq screen-shader

(make-shader screen :keyword :surface
      (
	((Ks float) 0.5)
        ((Kd float) 0.5)
        ((Ka float) 1)
        ((roughness float) 0.01)
        ((density float) 0.25)
        ((frequency float) 20)
        ((specular-color color) (make-color 1 1 1))
        ((fuzz float) 0))          ; >0 で screen_aa 流の縁ぼかし (st 比)
  (enter (((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I)))
          ((ssm float) 0.0) ((ttm float) 0.0)
          ((gwf float) 0.0) ((w float) 0.0) ((h float) 0.0))
    (if (< fuzz 0.0001)
        ;; ── 従来 (1993): ハードステップの帯 ──
        (if (or (< (mod (* s frequency) 1) density)
	        (< (mod (* t frequency) 1) density))
	    (setvar Oi 1)
	    (setvar Oi 0))
        ;; ── screen_aa 流: サイクル境界中心の帯 + smoothstep 縁 ──
        (progn
          (setvar ssm (mod (* s frequency) 1))
          (setvar ttm (mod (* t frequency) 1))
          (setvar gwf (* density 0.5))
          (setvar w (- (smoothstep (- gwf fuzz) (+ gwf fuzz) ssm)
                       (smoothstep (- (- 1 gwf) fuzz) (+ (- 1 gwf) fuzz) ssm)))
          (setvar h (- (smoothstep (- gwf fuzz) (+ gwf fuzz) ttm)
                       (smoothstep (- (- 1 gwf) fuzz) (+ (- 1 gwf) fuzz) ttm)))
          (setvar Oi (- 1 (* w h)))))
    (setvar Ci (* Oi (+ (* Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
		        (* specular-color Ks (specular Nf Ir roughness)))))
)))

(compile-shader screen-shader)
(append-shader screen-shader)
