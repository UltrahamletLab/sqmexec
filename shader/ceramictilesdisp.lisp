;;; ceramictilesdisp — ceramictiles の相棒: 目地を沈める変位シェーダー
;;;
;;; 移植元: BMRT ceramictiles.sl の変位部
;;;   tiledisp = smoothpulse(0,.075,.925,1, stile) * smoothpulse(0,.075,.925,1, ttile)
;;;   Displace(Nf, "shader", groovedepth*(tiledisp-1), truedisp)
;;;
;;; sqm では :surface から N/形を触れないので、この部分だけ :displacement に分離する
;;; (brick ←→ brickbump と同じ対)。出力 h∈[0,1] (1=タイル面, 0=目地の底) で、
;;; **原典の groovedepth はシーンの (amp)** に書く。
;;;
;;; ⚠ 表面シェーダー ceramictiles と **spacing/axis を必ず一致**させること。
;;;   また shader-space は :surface 専用なので、**タイルの向きを (shader-space ..) で
;;;   回すシーンではこの変位は使わない** (色と溝がズレる)。(local) は使える。
;;;
;;; パラメータ定義順 (shade_dr.cpp の ceramictilesdisp_dparams[] と一致必須):
;;;   stilespacing=0 ttilespacing=1 axis=2
;;;
;;; 使い方:
;;;   (displace (amp 0.02) (mode dsl) (shader ceramictilesdisp) (lipschitz 30)
;;;             (param stilespacing 0.6) (param ttilespacing 0.6) (param axis 2))
;;;   lipschitz ≈ 1.5/(0.075*min(spacing)) × 1.4 (2軸合成)。spacing 0.6 なら 47。

(setq ceramictilesdisp-shader

(make-shader ceramictilesdisp :keyword :displacement
      (
       ((stilespacing float) 1.0)
       ((ttilespacing float) 1.0)
       ((axis         float) 2.0)     ; 投影面 0=yz 1=zx 2=xy
       )

  (enter (((su  float) 0.0) ((tv  float) 0.0)
          ((stl float) 0.0) ((ttl float) 0.0)
          ((h   float) 0.0))

    (setvar su (xcomp P))
    (setvar tv (ycomp P))
    (if (< axis 0.5) (setvar su (zcomp P)))
    (if (and (> axis 0.5) (< axis 1.5)) (setvar tv (zcomp P)))
    (setvar su (/ su stilespacing))
    (setvar tv (/ tv ttilespacing))
    (setvar stl (- su (floor su)))
    (setvar ttl (- tv (floor tv)))

    ;; smoothpulse(0,.075,.925,1,x) = smoothstep(0,.075,x) - smoothstep(.925,1,x)
    (setvar h (* (- (smoothstep 0.0 0.075 stl) (smoothstep 0.925 1.0 stl))
                 (- (smoothstep 0.0 0.075 ttl) (smoothstep 0.925 1.0 ttl))))
    (setvar disp h)
)))

(compile-shader ceramictilesdisp-shader)
(append-shader ceramictilesdisp-shader)
