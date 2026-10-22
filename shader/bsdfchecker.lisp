;;; bsdfchecker — パストレーシング (-Q) 用の材質シェーダー実例 1号
;;;
;;; :volume クラスの**第2の読み替え規約** (PT 材質評価)。エンジンの
;;; dr_bsdf_material (shade_dr.cpp) が PT の各パス頂点で呼び、ライティングは
;;; PT 側が NEE+MIS で積分する — シェーダーは「その点の BSDF パラメータ」だけ返す。
;;;
;;; 入出力 (dr_bsdf_material が設定/回収する):
;;;   read   Pg/P ヒット点 (ワールド)    read  N/Ng  シェーディング法線
;;;   read   Cs   シーンの (color ..)    read  u,v   テクスチャ座標
;;;   write  Cl   アルベド (既定 = 従来 4-BSDF 写像の色)
;;;   write  Ci   発光 (既定 = (param emission) or 0)
;;;   write  Oi   (roughness, metallic, transmission) ← color を3連の数値として使う
;;;   write  t    IOR (>1 のときだけ採用)
;;;   ※ Oi を書くと3成分とも上書きになる (部分上書き不可)
;;;
;;; この実例: 3D 市松。タイルごとに色と roughness を変える —
;;; 明タイルは磨き (映り込みシャープ)、暗タイルは荒い、を1面で見せる。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfchecker)
;;;            (param scale 0.75) (param rough1 0.10) (param rough2 0.55))

(setq bsdfchecker-shader

(make-shader bsdfchecker :keyword :volume
      (((scale    float) 1.0)                          ; タイル1辺の長さ
       ((color1   color) (make-color 0.85 0.85 0.85))  ; 明タイル
       ((color2   color) (make-color 0.14 0.14 0.16))  ; 暗タイル
       ((rough1   float) 0.10)      ; 明タイルの roughness (磨き)
       ((rough2   float) 0.55)      ; 暗タイルの roughness (荒い)
       ((metallic float) 0.0))

  (enter (((fx float) 0.0)
          ((fy float) 0.0)
          ((fz float) 0.0)
          ((w  float) 0.0)
          ((rg float) 0.0))

    ;; 3D 市松のパリティ。mod が負を返しうるので二乗で 0/1 に畳む
    (setvar fx (floor (/ (xcomp Pg) scale)))
    (setvar fy (floor (/ (ycomp Pg) scale)))
    (setvar fz (floor (/ (zcomp Pg) scale)))
    (setvar w  (mod (+ fx (+ fy fz)) 2.0))
    (setvar w  (* w w))

    (setvar Cl (mix color1 color2 w))
    (setvar rg (+ (* rough1 (- 1.0 w)) (* rough2 w)))
    (setvar Oi (make-color rg metallic 0.0))
)))

(compile-shader bsdfchecker-shader)
(append-shader bsdfchecker-shader)
