;;; bsdfvelvet — ベルベット/スエード: 逆フレネルの sheen (PT -Q 材質, 2026-08-02)
;;;
;;; 布の毛足が掠め角で光を散らし「輪郭が白く立つ」質感。フレネルと逆で、
;;; アルベド自体を (1−cosθ)^p で明るくする + roughness 高め。
;;;   Cl = mix(base, sheen-color, sheen·(1−cosθ)^power)
;;;
;;; |I|=0 (SPPM/BDPT/VCM) の退避: sheen 項を切り base-color に落ちる。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfvelvet)
;;;            (param base-color 0.28 0.04 0.09)      ; 深紅のベルベット
;;;            (param sheen-color 0.92 0.85 0.88)
;;;            (param power 3.0) (param sheen 0.8) (param rough 0.8))

(setq bsdfvelvet-shader

(make-shader bsdfvelvet :keyword :volume
      (((base-color  color) (make-color 0.28 0.04 0.09))
       ((sheen-color color) (make-color 0.92 0.85 0.88))
       ((power    float) 3.0)
       ((sheen    float) 0.8)
       ((rough    float) 0.80)
       ((metallic float) 0.0))

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((sw float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    (setvar cv (clamp cv 0.0 1.0))

    (setvar sw (* sheen (* vd (pow (- 1.0 cv) power))))
    (setvar Cl (mix base-color sheen-color (clamp sw 0.0 1.0)))
    (setvar Oi (make-color rough metallic 0.0))
)))

(compile-shader bsdfvelvet-shader)
(append-shader bsdfvelvet-shader)
