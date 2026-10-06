;;; bsdfholo — スキャンライン/ホログラム (PT -Q 演出材質, 2026-08-02)
;;;
;;; cosθ と Pg の縞を掛けた発光。走査線は Pg.y の正弦縞で、位相に (1−cosθ) を
;;; 混ぜてあるので**視線を動かすと走査線が流れる**。縁ほど発光が立つ
;;; (ホログラムの「輪郭が濃い」見え方) + 本体はほぼ黒 = 発光だけが絵になる。
;;;
;;; |I|=0 の退避: 発光ゼロ (黒い球に落ちる)。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfholo)
;;;            (param holo-color 0.25 1.0 0.55) (param gain 3.5)
;;;            (param freq 34) (param slide 6.0) (param sharp 3.0)
;;;            (param rim-mix 0.65) (param rough 0.5))

(setq bsdfholo-shader

(make-shader bsdfholo :keyword :volume
      (((base-color color) (make-color 0.01 0.02 0.015))
       ((holo-color color) (make-color 0.25 1.0 0.55))
       ((gain    float) 3.5)
       ((freq    float) 34.0)   ; 走査線の空間周波数 (world y)
       ((slide   float) 6.0)    ; 視線角→位相 (走査線が視線で流れる量)
       ((sharp   float) 3.0)    ; 縞の締まり (pow)
       ((rim-mix float) 0.65)   ; 0=一様発光 / 1=縁だけ発光
       ((rough   float) 0.50))

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((sl float) 0.0) ((rim float) 0.0) ((em float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    (setvar cv (clamp cv 0.0 1.0))

    ;; 走査線: sin(y·freq + slide·(1−cosθ)) — 視線で位相が滑る
    (setvar sl (+ 0.5 (* 0.5 (sin (+ (* (ycomp Pg) freq)
                                     (* slide (- 1.0 cv)))))))
    (setvar sl (pow sl sharp))
    ;; 縁強調 (rim-mix で一様⇔縁だけ を選ぶ)
    (setvar rim (+ (- 1.0 rim-mix) (* rim-mix (pow (- 1.0 cv) 1.5))))
    (setvar em (* gain (* vd (* sl rim))))
    (setvar Ci (mix (make-color 0.0 0.0 0.0) holo-color (clamp em 0.0 1000.0)))
    (setvar Cl base-color)
    (setvar Oi (make-color rough 0.0 0.0))
)))

(compile-shader bsdfholo-shader)
(append-shader bsdfholo-shader)
