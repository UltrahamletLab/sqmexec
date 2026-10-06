;;; bsdfiridescent — 玉虫色 (薄膜干渉) の PT (-Q) 材質版 (2026-08-02)
;;;
;;; :surface 版 iridescent の PT 移植。I (視線) ブリッジ (同日実装) を使い、
;;; 視線と法線のなす角で虹の位相を回す — 見る角度で色が流れる玉虫色。
;;; ライティングは PT が積分するので、ここは「その点の材質パラメータ」だけ返す:
;;;   Cl = 虹色アルベド (metallic 高め → 虹色がそのまま反射色 F0 になる)
;;;
;;; I の規約: 視点→P の全長ベクトル (RenderMan)。**|I|=0 = 無効 (SPPM/BDPT/VCM)**
;;; → base-color に落ちる。normalize(I) は NaN 罠なので dot/clamp 形で。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfiridescent)
;;;            (param rainbow-freq 3.0) (param noise-scale 1.2)
;;;            (param noise-amp 0.6) (param strength 0.85)
;;;            (param rough 0.18) (param metallic 0.85))

(setq bsdfiridescent-shader

(make-shader bsdfiridescent :keyword :volume
      (((base-color   color) (make-color 0.03 0.03 0.04)) ; 無効時/下地の色
       ((rainbow-freq float) 3.0)    ; 角度1周あたりの虹の周回数
       ((noise-scale  float) 1.2)    ; 空間ノイズの周波数 (膜厚ムラ)
       ((noise-amp    float) 0.6)    ; ノイズが位相に与える振幅
       ((strength     float) 0.85)   ; 虹の混合率の天井
       ((rough        float) 0.18)
       ((metallic     float) 0.85))

  (enter (((len   float) 0.0)
          ((valid float) 0.0)
          ((cosv  float) 0.0)
          ((ph    float) 0.0)
          ((amt   float) 0.0)
          ((rr    float) 0.0)
          ((gg    float) 0.0)
          ((bb    float) 0.0)
          ((rainbow color) (make-color 0.0 0.0 0.0)))

    (setvar len   (sqrt (dot I I)))
    (setvar valid (clamp (* len 100000.0) 0.0 1.0))     ; |I|=0 → 0
    (setvar cosv  (/ (abs (dot (normalize N) I))
                     (clamp len 0.000001 1000000.0)))
    (setvar cosv  (clamp cosv 0.0 1.0))

    ;; 薄膜の光路差 ~ (1-cosθ) + 膜厚ムラ (空間ノイズ) で虹の位相を回す
    (setvar ph (+ (* rainbow-freq (- 1.0 cosv))
                  (* noise-amp (vnoise (* Pg noise-scale)))))
    (setvar rr (+ 0.5 (* 0.5 (sin (* 6.283185 ph)))))
    (setvar gg (+ 0.5 (* 0.5 (sin (+ (* 6.283185 ph) 2.094395)))))
    (setvar bb (+ 0.5 (* 0.5 (sin (+ (* 6.283185 ph) 4.188790)))))
    (setvar rainbow (make-color rr gg bb))

    ;; 掠め角ほど発色 (edge boost)。|I|=0 なら 0 → base に落ちる
    (setvar amt (* strength (+ 0.35 (* 0.65 (pow (- 1.0 cosv) 1.5)))))
    (setvar Cl (mix base-color rainbow (* amt valid)))
    (setvar Oi (make-color rough metallic 0.0))
)))

(compile-shader bsdfiridescent-shader)
(append-shader bsdfiridescent-shader)
