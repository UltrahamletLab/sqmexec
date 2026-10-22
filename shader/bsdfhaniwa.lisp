;;; bsdfhaniwa — パストレーシング (-Q) 用の素焼き (埴輪) 材質。
;;;
;;; :volume クラスの PT 材質規約 (詳細は bsdfchecker.lisp 冒頭)。
;;; Cl = アルベド / Oi = (roughness, metallic, transmission)。
;;;
;;; 参照写真 (threejs_haniwa/reference.jpg) から実測した性質を写す:
;;;   ・完全にマット (roughness 0.94 固定)。**下げると素焼きがプラスチックになる**
;;;   ・**下ほど暗く低彩度** — 台筒は土に埋まっていた部分。y で連続に混ぜる
;;;   ・大きな焼けむら (低周波 fBm) + 灰緑の風化斑 (別レイヤ) + 砂粒 (高周波)
;;;   ・縦の擦痕 (轆轤・ヘラ目)。台筒に顕著 → y が低いほど強くする
;;;
;;; ⚠ **風化斑は薄く混ぜる** — Blender 版で全面に乗せたら彩度が 0.46→0.24 に落ちた。
;;;   patch は 0.12 前後が上限。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (bsdf bsdfhaniwa)
;;;            (param low-y 0.0) (param high-y 1.0) (param scale 2.6))

(setq bsdfhaniwa-shader

(make-shader bsdfhaniwa :keyword :volume
      (((scale        float) 2.6)      ; 焼けむらの空間スケール
       ;; ⚠ **アルベドはリニア**。実測 sRGB をそのまま入れると明るく低彩度になり、
       ;;   ACES を通した後 彩度 0.25 (参照 0.45) の白茶けた土になる。
       ;;   sRGB→linear 変換した値を入れること。
       ((top-color    color) (make-color 0.571 0.338 0.152))  ; #c7a277 (頭・胴)
       ((bot-color    color) (make-color 0.445 0.227 0.117))  ; #b28360 (台筒)
       ((burn-color   color) (make-color 0.254 0.120 0.058))  ; #8a6144 焼けむら
       ((patch-color  color) (make-color 0.156 0.144 0.098))  ; 風化した灰緑の斑
       ((patch-amt    float) 0.12)     ; 斑の混合上限。上げすぎると彩度が死ぬ
       ((patch-scale  float) 1.1)
       ((burn-amt     float) 0.34)     ; 焼けむらの深さ
       ((grain-amt    float) 0.055)    ; 砂粒 (高周波) の振れ
       ((grain-scale  float) 46.0)
       ((streak-amt   float) 0.045)    ; 縦の擦痕
       ((streak-scale float) 30.0)
       ((low-y        float) 0.0)      ; 色の勾配の下端 (ワールド y)
       ((high-y       float) 1.0)      ; 同 上端
       ((roughness    float) 0.94)     ; 素焼き = ほぼ完全拡散
       ((octaves      float) 5.0))

  (enter (((q      point) (make-point 0 0 0))
          ((q2     point) (make-point 0 0 0))
          ((q3     point) (make-point 0 0 0))
          ((hgt    float) 0.0)
          ((base   color) (make-color 0 0 0))
          ((burn   float) 0.0)
          ((patch  float) 0.0)
          ((grain  float) 0.0)
          ((streak float) 0.0)
          ((lo     float) 0.0)
          ((col    color) (make-color 0 0 0)))

    ;; ① 高さで上下の地色を混ぜる (下ほど暗く低彩度)
    (setvar hgt (clamp (/ (- (ycomp Pg) low-y) (max 0.0001 (- high-y low-y))) 0 1))
    (setvar base (mix bot-color top-color (smoothstep 0.05 0.62 hgt)))

    ;; ② 焼けむら (低周波 fBm)。暗い側へ引く
    (setvar q (make-point (* (xcomp Pg) scale) (* (ycomp Pg) scale)
                          (* (zcomp Pg) scale)))
    (setvar burn (vfbm q octaves))
    (setvar col (mix base burn-color (* burn-amt (smoothstep 0.30 0.78 burn))))

    ;; ③ 風化した灰緑の斑 (別スケール)。薄く。
    (setvar q2 (make-point (* (xcomp Pg) patch-scale) (* (ycomp Pg) patch-scale)
                           (* (zcomp Pg) patch-scale)))
    (setvar patch (smoothstep 0.44 0.64 (vfbm q2 3.0)))
    (setvar col (mix col patch-color (* patch-amt patch)))

    ;; ④ 縦の擦痕。**y を細かく xz を粗く**引き伸ばすと縦筋になる。
    ;;    台筒 (hgt 小) ほど強い = 土に埋まっていた側の風化。
    (setvar q3 (make-point (* (xcomp Pg) streak-scale)
                           (* (ycomp Pg) (* streak-scale 0.10))
                           (* (zcomp Pg) streak-scale)))
    (setvar streak (- (vnoise q3) 0.5))
    (setvar lo (- 1.0 (smoothstep 0.30 0.70 hgt)))
    (setvar col (+ col (* (* streak-amt (+ 0.35 (* 0.65 lo))) streak)))

    ;; ⑤ 砂粒 (高周波)
    (setvar q3 (make-point (* (xcomp Pg) grain-scale) (* (ycomp Pg) grain-scale)
                           (* (zcomp Pg) grain-scale)))
    (setvar grain (- (vnoise q3) 0.5))
    (setvar col (+ col (* grain-amt grain)))

    (setvar Cl col)
    (setvar Oi (make-color roughness 0.0 0.0))   ; 金属でも透明でもない
)))

(compile-shader bsdfhaniwa-shader)
(append-shader bsdfhaniwa-shader)
