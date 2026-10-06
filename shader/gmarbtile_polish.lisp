;;; gmarbtile_polish — 研磨された緑大理石タイル
;;;
;;; 移植元: BMRT gmarbtile_polish.sl (+ patterns.h tilepattern / noises.h)
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;; 構成 (原典どおり):
;;;   ① tilepattern でタイル格子 (groovy=1 タイル / 0 目地) とタイル番号
;;;   ② タイル番号で模様をオフセット (7·whichs, 15·whicht) → タイル毎に別の石
;;;   ③ 下地: turbulence 5oct → smoothstep(0.1,0.35) で dark/light をブレンド
;;;   ④ 鉱脈: ドメインワープ (+ベクトル fBm 6oct) → 3oct の鋭い鉱脈
;;;        turb = pow(smoothstep(.8,1,1-|snoise|), sharpness)/freq
;;;        turbsum += (1-turbsum)·turb   ← 手前の鉱脈が奥を遮る合成
;;;      さらに低周波 snoise でパッチ状に間引く
;;;   ⑤ 研磨: (Ks·specular + Kr·trace) × groovy — **目地はハイライトも反射も無し**
;;;
;;; ── sqm 版の違い ────────────────────────────────────────────────
;;; ・transform("shader",P) → (transform "shader" Pg)。タイルの切断面は axis で
;;;   選ぶ (0=yz 1=zx 2=xy 既定)。模様は 3D ノイズなので切断面に依らず立体。
;;; ・filtered* の帯域制限は落とした (fuzz = min(0.02, groovewidth/2))。
;;; ・vfBm (ベクトル値 fBm) は w_pnoisep と同じオフセット (+17.3 / +31.7) の
;;;   スカラー fBm 3本で構成。
;;; ・SampleEnvironment → 素の trace × Kr (blur は pbrenv 代替 — trace拡張_見送り)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の gmarbtile_polish_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 Kr=3 roughness=4 specularcolor=5 txtscale=6
;;;   darkcolor=7 lightcolor=8 veincolor=9 groovecolor=10
;;;   veinfreq=11 sharpness=12 tilesize=13 groovewidth=14 axis=15
;;;
;;; 使い方 (シーン):
;;;   (surface (color 1 1 1) (ka 0.5) (kd 0.4) (ks 0.2) (phong 0)
;;;            (shader gmarbtile_polish)
;;;            (param tilesize 0.7) (param txtscale 1.2) (param Kr 0.2)
;;;            (param axis 1))            ; 床なら zx
;;;   ※ (phong 0) 必須。tilesize/txtscale は**ワールド単位**。
;;;   ※ 27回/hit のノイズを引く重いシェーダー。下書きは低解像度で。

(setq gmarbtile_polish-shader

(make-shader gmarbtile_polish :keyword :surface
      (
       ((Ka            float) 0.5)
       ((Kd            float) 0.4)
       ((Ks            float) 0.2)
       ((Kr            float) 0.2)
       ((roughness     float) 0.05)
       ((specularcolor color) (make-color 1 1 1))
       ((txtscale      float) 1.0)
       ((darkcolor     color) (make-color 0.01 0.12 0.004))
       ((lightcolor    color) (make-color 0.06 0.18 0.02))
       ((veincolor     color) (make-color 0.47 0.57 0.03))
       ((groovecolor   color) (make-color 0.02 0.02 0.02))
       ((veinfreq      float) 1.0)
       ((sharpness     float) 25.0)
       ((tilesize      float) 1.0)
       ((groovewidth   float) 0.015)   ; タイルサイズ比
       ((axis          float) 2.0)     ; タイル切断面 0=yz 1=zx 2=xy
       )

  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((q  point) (make-point 0 0 0))
          ((su float) 0.0) ((tv float) 0.0)
          ((fz float) 0.0)
          ((msu float) 0.0) ((mtv float) 0.0)
          ((groovy float) 0.0)
          ((whs float) 0.0) ((wht float) 0.0)
          ((pp  point) (make-point 0 0 0))
          ((famp float) 0.0) ((facc float) 0.0) ((j float) 0.0)
          ((wx float) 0.0) ((wy float) 0.0) ((wz float) 0.0)
          ((Ct  color) (make-color 0 0 0))
          ((frq float) 0.0) ((tb float) 0.0) ((tsum float) 0.0)
          ((gate float) 0.0)
          ((spec color) (make-color 0 0 0))
          ((refl color) (make-color 0 0 0))
          ((rdir point) (make-point 0 0 1))
          ((hitf float) 0.0))

    ;; ── ① タイル格子 (shader 空間 → axis 投影) ─────────────────────
    (setvar q (* (transform "shader" Pg) txtscale))
    (setvar su (xcomp q))
    (setvar tv (ycomp q))
    (if (< axis 0.5) (setvar su (zcomp q)))                       ; axis 0: (z, y)
    (if (and (> axis 0.5) (< axis 1.5)) (setvar tv (zcomp q)))    ; axis 1: (x, z)
    (setvar su (/ su tilesize))
    (setvar tv (/ tv tilesize))
    (setvar fz (min 0.02 (* groovewidth 0.5)))
    (setvar msu (+ su (* groovewidth 0.5)))
    (setvar msu (- msu (floor msu)))
    (setvar mtv (+ tv (* groovewidth 0.5)))
    (setvar mtv (- mtv (floor mtv)))
    (setvar groovy (* (- (smoothstep groovewidth (+ groovewidth fz) msu)
                         (smoothstep (- 1.0 fz) 1.0 msu))
                      (- (smoothstep groovewidth (+ groovewidth fz) mtv)
                         (smoothstep (- 1.0 fz) 1.0 mtv))))
    (setvar whs (floor su))
    (setvar wht (floor tv))

    ;; ── ② タイル毎に模様をオフセット ─────────────────────────────
    (setvar pp (+ q (make-point (* 7.0 whs) (* 15.0 wht) 0.0)))

    ;; ── ③ 下地: turbulence 5oct (lac 2, gain 0.5) ──────────────────
    (setvar famp 1.0)
    (setvar facc 0.0)
    (setvar q pp)
    (repeat (j 5)
      (setvar facc (+ facc (* famp (abs (- (* 2.0 (noise q)) 1.0)))))
      (setvar famp (* famp 0.5))
      (setvar q (* q 2.0)))
    (setvar Ct (mix darkcolor lightcolor (smoothstep 0.1 0.35 (* 0.5 facc))))

    ;; ── ④ 鉱脈: ドメインワープ (ベクトル fBm 6oct) ────────────────
    (setvar famp 0.5)
    (setvar wx 0.0) (setvar wy 0.0) (setvar wz 0.0)
    (setvar q pp)
    (repeat (j 6)
      (setvar wx (+ wx (* famp (- (* 2.0 (noise q)) 1.0))))
      (setvar wy (+ wy (* famp (- (* 2.0 (noise (+ q (make-point 17.3 0 0)))) 1.0))))
      (setvar wz (+ wz (* famp (- (* 2.0 (noise (+ q (make-point 0 31.7 0)))) 1.0))))
      (setvar famp (* famp 0.5))
      (setvar q (* q 2.0)))
    (setvar pp (+ pp (+ (make-point 35.2 -21.9 6.25) (make-point wx wy wz))))
    (setvar pp (* pp veinfreq))

    ;; 3oct の鋭い鉱脈 (手前が奥を遮る合成)
    (setvar tsum 0.0)
    (setvar frq 1.0)
    (repeat (j 3)
      (setvar tb (abs (- (* 2.0 (noise (* pp frq))) 1.0)))
      (setvar tb (/ (pow (smoothstep 0.8 1.0 (- 1.0 tb)) sharpness) frq))
      (setvar tsum (+ tsum (* (- 1.0 tsum) tb)))
      (setvar frq (* frq 2.0)))
    ;; 低周波でパッチ状に間引く
    (setvar gate (smoothstep -0.1 0.05
                             (- (* 2.0 (noise (* (+ pp (make-point -4.4 8.34 27.1)) 2.0))) 1.0)))
    (setvar Ct (mix Ct veincolor (* tsum gate)))

    ;; ── 目地の色 ────────────────────────────────────────────────
    (setvar Ct (mix groovecolor Ct groovy))

    ;; ── ⑤ 研磨: ハイライト+反射はタイル部だけ ─────────────────────
    (setvar spec (* specularcolor (* Ks (specular Nf Ir roughness))))
    (if (> Kr 0.001)
        (progn
          (setvar rdir (reflect I Nf))
          (setvar refl (* specularcolor (* Kr (trace P rdir hitf))))))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* groovy (+ spec refl)))))
)))

(compile-shader gmarbtile_polish-shader)
(append-shader gmarbtile_polish-shader)
