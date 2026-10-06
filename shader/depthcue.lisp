;;; depthcue — 距離で背景色へ線形フェード (:volume / atmosphere 用)
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;; All rights reserved.
;;;
;;; 2026-08-09 改訂: BMRT depthcue.sl と比較 — **式は完全に同一** (線形ランプ
;;;   mix(Ci, background, clamp((d-min)/(max-min), 0, 1))
;;; だったため 1993 年版を残し、sqm で死んでいた2点だけ直した:
;;;   ① 距離を (depth P)=|P| → **(length I)** に。1993 年の DR は P がカメラ空間で
;;;      |P|=視距離だったが、sqm の P はワールド → |P| は「原点からの距離」になって
;;;      いた。atmosphere 経路は |I|=カメラ→端点距離を保証する (fog.lisp と同じ)。
;;;   ② shade_dr.cpp の volume_param_table に未登録で (param ..) が一切効かなかった
;;;      → depthcue_vparams を追加 (mindistance=0 maxdistance=1 background=2)。
;;;
;;; fog (指数: 1-exp(-d/dist), 漸近) との違い = **maxdistance で完全に背景色に達する**
;;; 線形ランプ。「この距離から先は見えない」という視程の演出はこちら。
;;;
;;; 使い方 (シーン):
;;;   (atmosphere (shader depthcue)
;;;               (param mindistance 3) (param maxdistance 12)
;;;               (param background 0.05 0.055 0.07))
;;;   ※ background はシーンの (background ..) と同色にすると空に溶ける。

(setq depthcue-shader

(make-shader depthcue :keyword :volume
      (
	((mindistance float) 0)
        ((maxdistance float) 1)
        ((background color) 0))
  (enter (((d float) (clamp (/ (- (length I) mindistance)
                               (- maxdistance mindistance)) 0 1)))
    (setvar Ci (mix Ci background d))
)))

(compile-shader depthcue-shader)
(append-shader depthcue-shader)
