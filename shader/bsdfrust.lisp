;;; bsdfrust — パストレーシング (-Q) 用の材質シェーダー実例 2号 (錆びた金属)
;;;
;;; :volume クラスの PT 材質規約 (詳細は bsdfchecker.lisp 冒頭のコメント)。
;;; fBm ノイズのマスクで「金属 (metallic 1, 低 roughness)」と
;;; 「錆 (metallic 0, 高 roughness, 茶色アルベド)」を点ごとに混ぜる —
;;; metallic/roughness の**空間変化**が GGX の importance sampling に直結する実例。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (bsdf bsdfrust)
;;;            (param coverage 0.45) (param scale 2.2))
;;;   coverage 大 = 錆が増える。edge-width = 金属↔錆の遷移幅。

(setq bsdfrust-shader

(make-shader bsdfrust :keyword :volume
      (((scale       float) 2.2)      ; ノイズの空間スケール
       ((coverage    float) 0.45)     ; 錆の量 (fBm 閾値)
       ((edge-width  float) 0.16)     ; 金属↔錆の遷移幅
       ((metal-color color) (make-color 0.72 0.74 0.78))
       ((rust-color  color) (make-color 0.40 0.15 0.05))
       ((rust-color2 color) (make-color 0.62 0.32 0.10))
       ((rough-metal float) 0.14)     ; 金属部の roughness
       ((rough-rust  float) 0.78)     ; 錆部の roughness
       ((octaves     float) 5.0))

  (enter (((q       point) (make-point 0 0 0))
          ((q2      point) (make-point 0 0 0))
          ((nfv     float) 0.0)      ; ※ "n" はグローバル N と衝突するので不可
          ((mottle  float) 0.0)
          ((w       float) 0.0)
          ((rustcol color) (make-color 0 0 0))
          ((rg      float) 0.0)
          ((mt      float) 0.0))

    (setvar q (make-point (* (xcomp Pg) scale)
                          (* (ycomp Pg) scale)
                          (* (zcomp Pg) scale)))
    (setvar nfv (vfbm q octaves))
    ;; w: 0=金属 / 1=錆
    (setvar w (smoothstep (- coverage edge-width) (+ coverage edge-width) nfv))

    ;; 錆の色むら (二層目の fBm)
    (setvar q2 (make-point (* (xcomp q) 2.7)
                           (* (ycomp q) 2.7)
                           (* (zcomp q) 2.7)))
    (setvar mottle (vfbm q2 3.0))
    (setvar rustcol (mix rust-color rust-color2 mottle))

    (setvar Cl (mix metal-color rustcol w))
    (setvar rg (+ (* rough-metal (- 1.0 w)) (* rough-rust w)))
    (setvar mt (- 1.0 w))
    (setvar Oi (make-color rg mt 0.0))
)))

(compile-shader bsdfrust-shader)
(append-shader bsdfrust-shader)
