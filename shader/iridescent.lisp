;;; iridescent
;;;
;;; 薄膜干渉 (thin-film interference) による玉虫色サーフェスシェーダー。
;;; 視線と法線のなす角 (フレネル項) と 3D noise で虹色の「位相」を
;;; 変化させ、エッジ (かすめ角) ほど発色が強くなる。
;;;
;;; パラメータ定義順 (shade_dr.c の iridescent_params[] と一致させること):
;;;   Ka=0 Kd=1 Ks=2 Kr=3 roughness=4 rainbow-freq=5
;;;   noise-scale=6 noise-amp=7 edge-boost=8 base-mix=9 specular-color=10


(setq iridescent-shader

(make-shader iridescent :keyword :surface
      (
       ((Ka float) 0.20)
       ((Kd float) 0.45)
       ((Ks float) 0.65)
       ((Kr float) 0.20)
       ((roughness float) 0.015)
       ((rainbow-freq float) 9.0)
       ((noise-scale float) 1.4)
       ((noise-amp float) 2.5)
       ((edge-boost float) 0.65)
       ((base-mix float) 0.35)
       ((specular-color color) (make-color 1 1 1))
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((dir point) (reflect I (faceforward (normalize N) I)))
          ((fres float) 0)
          ((nz float) 0)
          ((phase float) 0)
          ((w float) 0)
          ((rr float) 0)
          ((gg float) 0)
          ((bb float) 0)
          ((rainbow color) (make-color 0 0 0))
          ((body color) (make-color 0 0 0))
          ((tr color) (make-color 0 0 0))
          ((intersected float) 0))
    ;; フレネル項: 正面=0, かすめ角=1
    (setvar fres (- 1 (dot Nf Ir)))
    ;; 3D noise で位相をかき混ぜ、面内に虹のうねりを作る
    (setvar nz (noise (* noise-scale Pg)))
    (setvar phase (+ (* rainbow-freq fres) (* noise-amp nz)))
    ;; 虹色: RGB を 120度 (2pi/3) ずつ位相シフトした正弦波
    (setvar rr (+ 0.5 (* 0.5 (sin phase))))
    (setvar gg (+ 0.5 (* 0.5 (sin (+ phase 2.0944)))))
    (setvar bb (+ 0.5 (* 0.5 (sin (+ phase 4.1888)))))
    (setvar rainbow (make-color rr gg bb))
    ;; ベース色との混合率: エッジほど虹が強く出る
    (setvar w (clamp (+ base-mix (* edge-boost fres)) 0 1))
    (setvar body (mix Cs rainbow w))
    ;; 反射トレース (Kr)
    (setvar tr (* Kr (trace P dir intersected)))
    ;; シェーディング合成
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (+ (* body (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                           tr)
                        (* specular-color Ks (specular Nf Ir roughness)))))
)))

(compile-shader iridescent-shader)
(append-shader iridescent-shader)
