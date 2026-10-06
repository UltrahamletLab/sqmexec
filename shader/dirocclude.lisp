;;; dirocclude.lisp — fundza "RSL - Directional Occlusion Light" の移植
;;;
;;; 原典はライトシェーダー (solar + occlusion(Ps, dir, ..) で「方向付きAOを
;;; 光として配る」)。sqm の DR ライトは build_dr_lights の決め打ち分岐が要るので、
;;; 同じ絵をサーフェス側で出す: direction まわり半角 coneangle の円錐遮蔽率で
;;; Cs×light-color を減光する。原典第2版の dot 反転 (面が光に背けば方向も反転 =
;;; 両面照明) も踏襲。multiplier = pow 締め (原典既定 2)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の dirocclude_params[] と一致必須):
;;;   samples=0 coneangle=1 multiplier=2 maxdist=3 direction=4 light-color=5
(setq dirocclude-shader
(make-shader dirocclude :keyword :surface
  (((samples float) 64)
   ((coneangle float) 90)
   ((multiplier float) 2)
   ((maxdist float) 3.0)
   ((direction point) (make-point 0 1 0))
   ((light-color color) (make-color 1 1 1)))
  (enter (((dir point) (normalize direction))
          ((Nn point) (normalize N))
          ((Po point) P)
          ((dt float) 0)
          ((occ float) 0))
    (setvar dt (dot Nn dir))
    (if (< dt 0) (setvar dir (- dir)))
    ;; dir が面の接線に近いとレイ原点が表面に残り自己交差ノイズ →
    ;; 原点を法線方向に持ち上げる (フックの軸方向オフセットでは足りないケース)
    (setvar Po (+ P (* 0.01 Nn)))
    (setvar occ (- 1 (occlusion Po dir samples (radians coneangle) maxdist)))
    (setvar occ (pow occ multiplier))
    (setvar Oi Os)
    (setvar Ci (* Oi Cs light-color occ))))
)
(compile-shader dirocclude-shader)
(append-shader dirocclude-shader)
