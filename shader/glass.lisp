;;; glass — レイトレース反射つきガラス
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.
;;;
;;; 2026-08-09: BMRT glass.sl (MaterialGlass) と比較し、**良い部分だけ** opt-in で導入:
;;;   ・fresnel (末尾追加 param, 既定 0 = 従来とビット一致):
;;;       1 で反射を Schlick フレネル重みに — F0 は eta から導出 (((η−1)/(η+1))²)。
;;;       正面 ~4% / 掠め ~100% の実ガラスの応答。**眠っていた eta に初めて仕事がつく**。
;;;   ・sharpness (末尾追加 param, 既定 -1 = 従来の specular):
;;;       0..1 で LocIllumGlossy (閾値化ハイライト — 原典が「ガラス/液体のための
;;;       スペキュラー」と書いたもの。ceramic と同じ式) に切り替え。
;;; 導入しなかったもの (理由):
;;;   ・シェーダー自前の屈折 trace — **既知の二重屈折+IOR不一致の罠** (下記コメント)。
;;;     エンジン屈折 (scene kt/roi) 一本化を維持。
;;;   ・transmitcolor — per-channel Oi の tintglass が既に担当。
;;;   ・reflblur/refrblur/env* — pbrenv/SQM_GLOSSY で代替 (trace拡張_見送り参照)。
;;;   ・raylevel()>0 で kr=0 の高速化 — sqm は DR_TRACE_MAX_DEPTH が同じ役割。
;;;
;;; パラメータ定義順 (shade_dr.cpp glass_params[] と一致必須):
;;;   Ks=0 Kd=1 Ka=2 Kr=3 Kt=4 eta=5 roughness=6 specular-color=7
;;;   fresnel=8 sharpness=9   ← 2026-08-09 末尾追加 (既存シーンは既定で不変)

(setq glass-shader

(make-shader glass :keyword :surface
      (
	((Ks float) 0.7)
        ((Kd float) 0.7)
        ((Ka float) 1)
        ((Kr float) 0.5)
        ((Kt float) 0.7)
        ((eta float) 1.333)
        ((roughness float) 0.01)
        ((specular-color color) (make-color 1 1 1))
        ((fresnel float) 0)       ; 1 = 反射に Schlick フレネル重み (F0 は eta から)
        ((sharpness float) -1)    ; 0..1 = LocIllumGlossy / 負 = 従来の specular
       )
  (enter (((Nf point) (faceforward  (normalize N) I))
	  ((Ir point) (normalize (- I)))
	  ((r-direction point) (reflect I Nf))
          ((krw float) 1.0)
          ((F0 float) 0.0)
          ((wg float) 0.0) ((expo float) 0.0)
          ((nl float) 0.0) ((j float) 0.0) ((g float) 0.0) ((nh float) 0.0)
          ((H point) (make-point 0 0 1))
          ((spec color) (make-color 0 0 0)))
    (setvar Oi Os)
    ;; ── ハイライト: 既定は従来の specular / sharpness>=0 で LocIllumGlossy ──
    (if (< sharpness 0.0)
        (setvar spec (specular Nf Ir roughness))
        (progn
          (setvar wg (* 0.18 (- 1.0 sharpness)))
          (setvar expo (/ 10.0 (max roughness 0.0001)))
          (setvar nl (lightcount))
          (repeat (j nl)
            (setvar g (lightsel j))
            (setvar H (normalize (+ (normalize L) Ir)))
            (setvar nh (max (dot Nf H) 0.0))
            (setvar spec (+ spec (* Cl (smoothstep (- 0.72 wg) (+ 0.72 wg)
                                                   (pow nh expo))))))))
    (setvar Ci (+ (* Oi Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
		 (* specular-color Ks spec)))
    ;; ── 反射: fresnel=1 で Schlick 重み (F0 = ((η−1)/(η+1))²) ──
    (if (> fresnel 0.5)
        (progn
          (setvar F0 (pow (/ (- eta 1.0) (+ eta 1.0)) 2.0))
          (setvar krw (+ F0 (* (- 1.0 F0)
                               (pow (- 1.0 (clamp (dot Nf Ir) 0.0 1.0)) 5.0))))))
    (setvar Ci (+ Ci (* (* Kr krw) (trace P r-direction))))
    ;; 屈折(透過)はエンジン側 shade_dr.c の透過ブロックが scene roi/kt で処理する。
    ;; ここで Kt*trace(t-direction) を足すと二重屈折＋IOR不一致(eta≠roi)になるため廃止。
    ;; Kt パラメータは index 維持のため定義は残す(本体では未使用)。
)))

(compile-shader glass-shader)
(append-shader glass-shader)
