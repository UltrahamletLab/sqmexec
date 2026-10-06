;;; bsdfrimlit — リムライト内蔵材質 (PT -Q 演出材質, 2026-08-02)
;;;
;;; ライトを置かずに「逆光の輪郭光」を出す — キャラクター/製品写真の定番演出を
;;; 材質1個で。狭い (1−cosθ)^p の白い発光を Ci に足すだけで、被写体の輪郭に
;;; 常にバックライトが回っているように見える。
;;; bsdfshield との違い: 発光は控えめ・本体は普通の不透明な材質のまま。
;;;
;;; |I|=0 の退避: リム発光ゼロ = ただの拡散材質。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfrimlit)
;;;            (param base-color 0.30 0.32 0.36)     ; 製品のボディ色
;;;            (param rim-color 1.0 0.97 0.92) (param gain 2.2)
;;;            (param power 5.0) (param rough 0.4) (param metallic 0.15))

(setq bsdfrimlit-shader

(make-shader bsdfrimlit :keyword :volume
      (((base-color color) (make-color 0.30 0.32 0.36))
       ((rim-color  color) (make-color 1.0 0.97 0.92))
       ((gain     float) 2.2)
       ((power    float) 5.0)    ; 大きいほど輪郭が細い
       ((rough    float) 0.40)
       ((metallic float) 0.15))

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((rim float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    (setvar cv (clamp cv 0.0 1.0))

    (setvar rim (* gain (* vd (pow (- 1.0 cv) power))))
    (setvar Ci (mix (make-color 0.0 0.0 0.0) rim-color (clamp rim 0.0 1000.0)))
    (setvar Cl base-color)
    (setvar Oi (make-color rough metallic 0.0))
)))

(compile-shader bsdfrimlit-shader)
(append-shader bsdfrimlit-shader)
