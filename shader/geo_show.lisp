;;; geo_show.lisp — fundza "RSL - Sierpinski Point Clouds" Listing 5 の移植
;;;
;;; 点群 (brickmap → sqm では blob 点描) を等輝度で見せるためのシェーダー。
;;; マイクロポリゴンの法線を視線 (-I) に向けたことにして diffuse を評価する
;;; → 粒の向きに依らず、視点から見て一様な明るさになる。
;;; 原典のベイクパス (serpinski.sl の chaos game ループ) は DSL にループが
;;; 無いので Python 側 (gen_models/gen_sierpinski.py) が担う = 二段構成も原典どおり。
;;;
;;; パラメータ定義順 (shade_dr.cpp の geo_show_params[] と一致必須): Kd=0

(setq geo-show-shader
(make-shader geo_show :keyword :surface
  (((Kd float) 1.0))
  (enter (((fakeN point) (normalize (- I))))
    (setvar Oi Os)
    (setvar Ci (* Oi Cs Kd (diffuse fakeN))))))
(compile-shader geo-show-shader)
(append-shader geo-show-shader)
