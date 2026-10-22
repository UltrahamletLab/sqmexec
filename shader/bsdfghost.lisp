;;; bsdfghost — 曇り硝子の縁透過 (ゴースト) PT -Q 材質 (2026-08-02)
;;;
;;; Oi の transmission チャンネルにフレネルを書く実例 — 正面は磨りガラス
;;; (拡散)、輪郭ほど透過が立ち向こうが透ける。PT 側の混合 Dielectric
;;; (確率 trans でガラス / 1−trans で拡散) がそのまま「縁ほどガラス化」になる。
;;;   trans = clamp(t0 + (1−t0)·(1−cosθ)^power, 0, trans-max)
;;;   t (IOR) も書ける (>1 のとき採用)。
;;;
;;; |I|=0 (SPPM/BDPT/VCM) の退避: trans=t0 (正面の磨りガラスのまま)。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfghost)
;;;            (param frost-color 0.78 0.82 0.86)
;;;            (param t0 0.05) (param power 2.5) (param trans-max 0.95)
;;;            (param rough 0.5) (param ior 1.5))

(setq bsdfghost-shader

(make-shader bsdfghost :keyword :volume
      (((frost-color color) (make-color 0.78 0.82 0.86))
       ((t0        float) 0.05)    ; 正面の透過率 (磨りガラスの残り透け)
       ((power     float) 2.5)
       ((trans-max float) 0.95)
       ((rough     float) 0.50)
       ((metallic  float) 0.0)
       ((ior       float) 1.5))

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((tr float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    (setvar cv (clamp cv 0.0 1.0))

    ;; 縁ほどガラス化。|I|=0 では t0 (正面) のまま
    (setvar tr (+ t0 (* (- 1.0 t0) (* vd (pow (- 1.0 cv) power)))))
    (setvar tr (clamp tr 0.0 trans-max))

    (setvar Cl frost-color)
    (setvar Oi (make-color rough metallic tr))
    (setvar t ior)
)))

(compile-shader bsdfghost-shader)
(append-shader bsdfghost-shader)
