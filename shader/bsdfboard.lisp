;;; bsdfboard — パストレーシング (-Q) 用の材質シェーダー (板目の天板・テーブル)
;;;
;;; :volume クラスの PT 材質規約 (詳細は bsdfchecker.lisp 冒頭のコメント):
;;;   Cl = アルベド / Oi = (roughness, metallic, trans)
;;;
;;; 木目が x 方向に走る板。z 方向の縞 (年輪の断面) を、x 方向に引き伸ばした
;;; fBm で揺らして板目らしい流れ模様にし、さらに細かい導管 (木理) の筋を重ねる。
;;; 晩材 (暗部) はやや艶、早材は荒い。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfboard)
;;;            (param ring-scale 7) (param warp 0.9))

(setq bsdfboard-shader

(make-shader bsdfboard :keyword :volume
      (((ring-scale  float) 7.0)      ; 年輪の密度 (大 = 細かい縞)
       ((warp        float) 0.9)      ; 縞を揺らすノイズ量
       ((stretch     float) 0.18)     ; 木目方向 (x) のノイズ引き伸ばし (小 = 長く流れる)
       ((fiber-amt   float) 0.07)     ; 細い導管の筋の濃さ
       ((fiber-scale float) 70.0)
       ((light-wood  color) (make-color 0.50 0.33 0.18))
       ((dark-wood   color) (make-color 0.27 0.15 0.07))
       ((rough-base  float) 0.50)
       ((rough-dark  float) 0.38))

  (enter (((q    point) (make-point 0 0 0))
          ((qf   point) (make-point 0 0 0))
          ((r    float) 0.0)
          ((fib  float) 0.0)
          ((band float) 0.0)
          ((rg   float) 0.0)
          ((col  color) (make-color 0 0 0)))

    (setvar q (make-point (* (xcomp Pg) stretch)
                          (* (ycomp Pg) 1.3)
                          (* (zcomp Pg) 1.3)))
    (setvar r (+ (* (zcomp Pg) ring-scale) (* warp (vfbm q 4.0))))
    (setvar r (- r (floor r)))
    (setvar band (- (smoothstep 0 0.75 r) (smoothstep 0.80 1 r)))

    ;; 木目に沿った細い筋 (x を大きく潰して z 方向だけ高周波)
    (setvar qf (make-point (* (xcomp Pg) 0.5)
                           (* (ycomp Pg) fiber-scale)
                           (* (zcomp Pg) fiber-scale)))
    (setvar fib (* fiber-amt (vfbm qf 2.0)))

    (setvar col (mix light-wood dark-wood band))
    (setvar Cl (mix col (make-color 0.15 0.08 0.04) (+ 0.0 (max 0.0 fib))))
    (setvar rg (+ (* rough-base (- 1.0 band)) (* rough-dark band)))
    (setvar Oi (make-color rg 0.0 0.0))
)))

(compile-shader bsdfboard-shader)
(append-shader bsdfboard-shader)
