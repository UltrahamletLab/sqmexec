;;; bsdfpearl — パール/キャンディ塗装 (フリップフロップ) PT -Q 材質 (2026-08-02)
;;;
;;; 車塗装の「正面は赤、斜めから紫、輪郭は青」— 視線角で 3 色相を補間する
;;; フリップフロップ (color-shift) 塗装。パール顔料の配向反射の見た目近似。
;;;   w = 1−cosθ を smoothstep 2 枚で face→mid→edge の 3 色に割る + metallic 中
;;;
;;; |I|=0 の退避: w=0 → face-color (正面色) に落ちる。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfpearl)
;;;            (param face-color 0.72 0.05 0.09)
;;;            (param mid-color  0.52 0.10 0.48)
;;;            (param edge-color 0.12 0.18 0.75)
;;;            (param rough 0.22) (param metallic 0.55))

(setq bsdfpearl-shader

(make-shader bsdfpearl :keyword :volume
      (((face-color color) (make-color 0.72 0.05 0.09))  ; 正面
       ((mid-color  color) (make-color 0.52 0.10 0.48))  ; 中間 (紫)
       ((edge-color color) (make-color 0.12 0.18 0.75))  ; 掠め角 (青)
       ((mid-pos  float) 0.55)   ; face→mid の遷移中心 (w)
       ((rough    float) 0.22)
       ((metallic float) 0.55))

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((w  float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    (setvar cv (clamp cv 0.0 1.0))

    (setvar w (* vd (- 1.0 cv)))                   ; 0=正面 → 1=輪郭
    (setvar Cl (mix face-color mid-color (smoothstep 0.0 mid-pos w)))
    (setvar Cl (mix Cl edge-color (smoothstep mid-pos 1.0 w)))
    (setvar Oi (make-color rough metallic 0.0))
)))

(compile-shader bsdfpearl-shader)
(append-shader bsdfpearl-shader)
