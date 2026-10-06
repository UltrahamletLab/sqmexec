;;; bsdfshield — SF シールド/オーラ (PT -Q 演出材質, 2026-08-02)
;;;
;;; アイデア集 B (非物理 — -Q 専用だからこそ許される) の1号。
;;; Ci (発光) に (1−cosθ)^p を書く → **輪郭だけ発光するバリア**。
;;; さらに Oi の transmission を正面ほど立てる → 中央は向こうが透け、
;;; 縁は不透明に発光する「エネルギーシールド」。
;;; PT では発光がライティングに載るので、シールドの光が周囲をほのかに照らす
;;; (シェーダー発光は NEE 非登録 = BSDF 直撃のみで運ばれる。不偏だがノイズ増)。
;;;
;;; |I|=0 (SPPM/BDPT/VCM) の退避: 発光ゼロ・透過は正面値 — ただの薄暗い球に落ちる。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfshield)
;;;            (param shield-color 0.25 0.70 1.0) (param gain 5.0)
;;;            (param power 2.5) (param trans-face 0.8)
;;;            (param rough 0.3) (param ior 1.05))

(setq bsdfshield-shader

(make-shader bsdfshield :keyword :volume
      (((base-color   color) (make-color 0.02 0.04 0.06))
       ((shield-color color) (make-color 0.25 0.70 1.0))
       ((gain       float) 5.0)    ; 縁発光の強さ
       ((power      float) 2.5)    ; 縁の締まり
       ((trans-face float) 0.8)    ; 正面の透過率 (中央ほど透ける)
       ((rough      float) 0.30)
       ((ior        float) 1.05))  ; ほぼ無屈折の膜

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((rim float) 0.0) ((tr float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    (setvar cv (clamp cv 0.0 1.0))

    (setvar rim (* vd (pow (- 1.0 cv) power)))
    (setvar Ci (mix (make-color 0.0 0.0 0.0) shield-color (clamp (* gain rim) 0.0 1000.0)))
    ;; 正面ほど透ける (縁は発光が主役なので不透明側へ)
    (setvar tr (* trans-face (+ (* (- 1.0 vd) 1.0) (* vd cv))))
    (setvar Cl base-color)
    (setvar Oi (make-color rough 0.0 (clamp tr 0.0 0.95)))
    (setvar t ior)
)))

(compile-shader bsdfshield-shader)
(append-shader bsdfshield-shader)
