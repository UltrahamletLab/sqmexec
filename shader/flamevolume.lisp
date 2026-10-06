;;; flamevolume — SDFボリュームの**標本評価**シェーダー (炎)
;;;
;;; 従来の SQM ボリュームは C++ 側の固定 fBm 密度式をサンプルし、単一の消散係数で
;;; 前方積分していた。この :volume シェーダーは **マーチ標本ごと**に呼ばれ、
;;; 密度・散乱アルベド・発光・RGB消散だけを返す。境界交差/ステップ分割/前方積分/
;;; 自己影は C++ 側 (vol.cpp) に残る = 速度と既存互換を保ったまま材質だけ差し替える。
;;; 特徴② (シェーディングは .lisp 側) をボリュームへ広げるための実例1号。
;;;
;;; ※ 大気用の :volume (smoke/fog) は「一次レイにつき1回」呼ばれる**別経路**。
;;;   こちらは標本ごと。SGV の意味も下記のとおり読み替える。
;;;
;;; 入出力 (エンジン dr_volume_sample が設定/回収する):
;;;   read   Pg  ワールド座標の標本点
;;;   read   u   容器内の正規化高さ 0..1 (bbox 下端0/上端1)
;;;   read   v   境界から内側への距離 (容器の縁で 0)
;;;   read   s   従来 fBm 密度 (builtin。使っても捨ててもよい)
;;;   read   Cs  シーンの (albedo ..)
;;;   write  t   最終密度
;;;   write  Cl  散乱アルベド
;;;   write  Ci  発光
;;;   write  Oi  RGB消散倍率 (波長別の吸収。赤は通し青は吸う炎が書ける)
;;;
;;; phase は **point** なので X/Y/Z を独立に動かせる。Y を増やすと密度場が上へ
;;; 移流し (炎の立ち上がり)、X/Z に周期を与えると左右の揺れやねじれになる。
;;;
;;; 使い方 (SSQ):
;;;   (volume (shader flamevolume) (density 3.0) (steps 144)
;;;           (param phase 0 1.2 0.15) (param noise-scale 1.15 1.65 1.15)
;;;           (param coverage 0.42) (param emit 2.8))

(setq flamevolume-shader

(make-shader flamevolume :keyword :volume
      (((phase        point) (make-point 0 0 0))      ; 密度場のドメインオフセット(XYZ独立)
       ((noise-scale  point) (make-point 1.15 1.65 1.15)) ; 軸ごとの空間スケール
       ((coverage     float) 0.48)      ; 大=密に充填
       ((density-gain float) 2.2)       ; 密度の全体ゲイン
       ((octaves      float) 5.0)       ; fBm オクターブ
       ((edge-width   float) 0.22)      ; 容器の縁でのフェード幅
       ((height-fade  float) 0.55)      ; 上ほど薄くする量 (炎の先が痩せる)
       ((temp-gamma   float) 1.6)       ; 温度コントラスト (大=芯だけ熱い)
       ((cool-color   color) (make-color 1.15 0.08 0.005))
       ((hot-color    color) (make-color 1.80 0.62 0.035))
       ((core-color   color) (make-color 2.80 2.05 0.72))
       ((scatter-color color) (make-color 0.55 0.30 0.12))
       ((extinction   color) (make-color 1.00 0.78 0.42))  ; RGB消散 (青ほど吸う)
       ((emit         float) 2.2))

  (enter (((q     point) (make-point 0 0 0))
          ((nfv   float) 0.0)
          ((raw   float) 0.0)
          ((edge  float) 0.0)
          ((topf  float) 0.0)
          ((dens  float) 0.0)
          ((temp  float) 0.0)
          ((white float) 0.0)
          ((heat  color) (make-color 0 0 0)))

    ;; ── 密度場 ────────────────────────────────────────────────
    ;; 軸ごとにスケールを変えられるので、Y を大きくすると縦に伸びた炎の筋になる
    (setvar q (make-point (+ (* (xcomp Pg) (xcomp noise-scale)) (xcomp phase))
                          (+ (* (ycomp Pg) (ycomp noise-scale)) (ycomp phase))
                          (+ (* (zcomp Pg) (zcomp noise-scale)) (zcomp phase))))
    (setvar nfv (vfbm q octaves))
    ;; coverage で閾値化して 0..1 に伸ばす
    (setvar raw (clamp (/ (- nfv coverage) (- 1.0 coverage)) 0.0 1.0))
    ;; 容器の縁でフェード (v = 境界からの内向き距離)
    (setvar edge (smoothstep 0.0 edge-width v))
    ;; 上ほど薄い (炎の先が痩せる)
    (setvar topf (- 1.0 (* height-fade (smoothstep 0.18 1.0 u))))
    (setvar dens (* density-gain (* raw (* edge topf))))
    (setvar t dens)

    ;; ── 温度ランプ → 発光色 ───────────────────────────────────
    (setvar temp (pow (clamp (* dens 0.72) 0.0 1.0) temp-gamma))
    (setvar white (smoothstep 0.58 0.98 temp))
    (setvar heat (mix cool-color hot-color temp))
    (setvar heat (mix heat core-color white))

    (setvar Cl scatter-color)
    (setvar Oi extinction)
    (setvar Ci (* heat (* emit dens)))
)))

(compile-shader flamevolume-shader)
(append-shader flamevolume-shader)
