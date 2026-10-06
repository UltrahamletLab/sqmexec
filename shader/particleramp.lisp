;;; particleramp.lisp — ワールド高さで色を引く粒用サーフェス (2026-08-14)
;;;                      (three.js webgpu_particles の移植で使う)
;;;
;;; blob-bulk は **per-blob 色を持てず**、object 内の2つ目の (surface ..) も
;;; 無視される。なので「下は炎・上は煙」のような色の変化は
;;; **ワールド y から引く**しかない。元例の「オレンジ→黒」に当たる。
;;;
;;; 発光体として使うので Ka を主役にし、Kd は輪郭を出す程度に添える
;;; (点光源で粒を照らしても、粒が自分で光っていないと炎に見えない)。
;;;
;;; y0 未満は hot-color、y1 超は cool-color、間は smoothstep。
;;; fade は上端に向けて暗く落とす量 (煙が空へ溶ける)。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color 1 1 1) (ka 1.0) (kd 0.25) (ks 0) (phong 0)
;;;            (shader particleramp)
;;;            (param hot-color 3.0 1.15 0.28) (param cool-color 0.30 0.10 0.09)
;;;            (param y0 0.10) (param y1 0.75) (param fade 0.55) (param gain 1.0))

(setq particleramp-shader

(make-shader particleramp :keyword :surface
      (((Ka        float) 1.0)
       ((Kd        float) 0.25)
       ((hot-color color) (make-color 3.00 1.15 0.28))   ; 下 = 炎
       ((cool-color color) (make-color 0.30 0.10 0.09))  ; 上 = 煙
       ((y0        float) 0.10)      ; ここまでは完全に hot
       ((y1        float) 0.75)      ; ここから先は完全に cool
       ((fade      float) 0.55)      ; 上端でさらに落とす量
       ((gain      float) 1.0))

  (enter (((yy   float) 0.0)
          ((mixv float) 0.0)
          ((fadev float) 0.0)
          ((col  color) (make-color 0 0 0))
          ((amb  color) (make-color 0 0 0))
          ((dif  color) (make-color 0 0 0)))

    ;; ⚠ P は blob のワールド座標。transform は使わない
    ;;   (blob には固有の object 空間が無く、"shader" 空間も設定していない)。
    (setvar yy (ycomp P))
    (setvar mixv (smoothstep y0 y1 yy))
    (setvar col (mix hot-color cool-color mixv))

    ;; 上ほど暗く落とす = 煙が抜けていく
    (setvar fadev (- 1.0 (* fade (smoothstep y0 (* y1 1.6) yy))))
    (setvar col (* col (* gain fadev)))

    ;; 発光主体 + 弱い拡散。ambient/diffuse は C 側のフック
    (setvar amb (ambient))
    (setvar dif (diffuse (normalize N)))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* col Ka) (* (* col Kd) (+ amb dif)))))
)))

(compile-shader particleramp-shader)
(append-shader particleramp-shader)
