;;; water
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq water-shader

(make-shader water :keyword :surface
      (
	((Ks float) 0.7)
        ((Kd float) 0.7)
        ((Ka float) 1)
        ((Kt float) 1)
        ((eta float) 1.333)
        ((roughness float) 0.01)
        ((specular-color color) (make-color 1 1 1))
       )
  (enter (((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I))))
    (setvar Oi Os)
    (setvar Ci (+ (* Os Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
		  (* specular-color Ks (specular Nf Ir roughness))))
    ;; 屈折(透過)はエンジン側 shade_dr.c の透過ブロックが scene roi/kt で処理する。
    ;; ここで Kt*trace(t-direction) を足すと二重屈折＋IOR不一致(eta≠roi)になるため廃止。
    ;; Kt/eta パラメータは index 維持のため定義は残す(本体では未使用)。
)))

(compile-shader water-shader)
(append-shader water-shader)
