;;; depth — 視点(カメラ)からヒット点までの距離をグレースケール表示する depth シェーダー
;;;
;;; 一次レイでは E = レイ原点 = カメラ位置。よって距離 = |E - Pg| (Pg=world ヒット位置)。
;;; near..far を [0,1] に正規化し、既定では near=白 / far=黒 (手前ほど明るい depth map)。
;;; invert>0.5 で near=黒 / far=白 に反転。ライティングは行わない (純粋な深度可視化)。
;;; ※ (distance a b) はフック不具合があるため (length (- E Pg)) を使う。
;;;
;;; パラメータ定義順 (shade_dr.c の depth_params[] と一致必須): near=0 far=1 invert=2

(setq depth-shader
(make-shader depth :keyword :surface
      (((near   float) 1.0)
       ((far    float) 60.0)
       ((invert float) 0.0))
  (enter (((dist float) 0)
          ((g    float) 0))
    (setvar dist (length (- E Pg)))
    (setvar g (clamp (/ (- dist near) (- far near)) 0.0 1.0))   ; 0=near 1=far
    (setvar g (- 1.0 g))                                         ; near=1(白) far=0(黒)
    ;; invert>0.5 で反転 (DSL の if は式に使えないため step で算術反転: g→1-g)
    (setvar g (+ g (* (step 0.5 invert) (- 1.0 (* 2.0 g)))))
    (setvar Oi Os)
    (setvar Ci (make-color g g g)))))

(compile-shader depth-shader)
(append-shader depth-shader)
