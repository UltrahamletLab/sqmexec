;;; bsdftoon — トゥーン輪郭色 (PT -Q 演出材質, 2026-08-02)
;;;
;;; cosθ (視線と法線のなす角) の閾値でアルベドを段階化するセルルック。
;;;   正面帯 (bright) / 中間帯 (mid) / 輪郭帯 (dark = 描き線) の3段を
;;;   smoothstep の細い遷移で割る。従来の :surface toon と違い、PT の
;;;   GI・ソフトシャドウの上にセル段が載る「PT のセルルック」になる。
;;;
;;; |I|=0 の退避: mid-color 一色のフラットに落ちる。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdftoon)
;;;            (param bright-color 0.98 0.80 0.35)
;;;            (param mid-color 0.80 0.48 0.22)
;;;            (param dark-color 0.10 0.06 0.05)
;;;            (param edge1 0.62) (param edge2 0.26) (param soft 0.04)
;;;            (param rough 0.9))

(setq bsdftoon-shader

(make-shader bsdftoon :keyword :volume
      (((bright-color color) (make-color 0.98 0.80 0.35))
       ((mid-color    color) (make-color 0.80 0.48 0.22))
       ((dark-color   color) (make-color 0.10 0.06 0.05))
       ((edge1 float) 0.62)   ; bright↔mid の cosθ 閾値
       ((edge2 float) 0.26)   ; mid↔dark (描き線) の cosθ 閾値
       ((soft  float) 0.04)   ; 遷移幅
       ((unlit float) 0.0)    ; セル色を自前発光で下支え (0=完全に照明依存)
       ((rough float) 0.90))

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((w1 float) 0.0) ((w2 float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    ;; |I|=0 → cv を中間帯へ (mid 一色)
    (setvar cv (+ (* (- 1.0 vd) (* 0.5 (+ edge1 edge2))) (* vd (clamp cv 0.0 1.0))))

    (setvar w1 (smoothstep (- edge1 soft) (+ edge1 soft) cv))   ; 1=正面側
    (setvar w2 (smoothstep (- edge2 soft) (+ edge2 soft) cv))   ; 0=輪郭側
    (setvar Cl (mix dark-color (mix mid-color bright-color w1) w2))
    (setvar Ci (mix (make-color 0.0 0.0 0.0) Cl (clamp unlit 0.0 1.0)))
    (setvar Oi (make-color rough 0.0 0.0))
)))

(compile-shader bsdftoon-shader)
(append-shader bsdftoon-shader)
