;;; funkyglass
;;; Randomly colored transparent glass with rim-transparency effect.
;;;
;;; Converted from RenderMan SL (BMRT / Larry Gritz) to DynamicRender Lisp.
;;; Original: funkyglass.sl (c) 1990-2000 Exluna, Inc. / Larry Gritz.
;;; Conversion: 2026

(setq funkyglass-shader

(make-shader funkyglass :keyword :surface
      (((Ka        float)  0.2)
       ((Kd        float)  0.2)
       ((Ks        float)  1.0)
       ((roughness float)  0.08)
       ((specular-color color) (make-color 1 1 1)))

  (enter (((Nf    point) (faceforward (normalize N) I))
          ((Ir    point) (normalize (- I)))

          ;; 3-channel noise: sample at different spatial frequencies
          ;; to approximate RenderMan's "color noise(P)"
          ((nr    float) (noise (* 1.00 P)))
          ((ng    float) (noise (* 1.37 P)))
          ((nb    float) (noise (* 0.73 P)))

          ;; Ct = 2*(noise - 0.5) + 0.5 = 2*noise - 0.5  [contrast stretch]
          ((cr    float) (- (* 2.0 nr) 0.5))
          ((cg    float) (- (* 2.0 ng) 0.5))
          ((cb    float) (- (* 2.0 nb) 0.5))
          ((Ct    color) (make-color cr cg cb))

          ;; Ot = avg(Ct) + (1 - Ct)  [brighter where color is darker]
          ((avg   float) (/ (+ cr cg cb) 3.0))
          ((Ot    float) (+ avg (- 1.0 avg)))   ; simplifies to 1.0... use rim only

          ;; Rim transparency: edges more transparent (like real glass)
          ((facing float) (abs (dot Nf (normalize I))))
          ((rim    float) (- 0.75 (* 0.5 facing)))
          ((Oi-val color) (* Os rim)))

    (setvar Oi Oi-val)
    (setvar Ci (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                  (* specular-color Ks (specular Nf Ir roughness)))))))

(compile-shader funkyglass-shader)
(append-shader funkyglass-shader)
