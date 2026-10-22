;;; ripples — 同心円状に広がる波紋の水面。中心 (center-x,center-z) から放射状に
;;;   sin(r*freq - phase) のリングを作り、その径方向スロープで法線を摂動 (bump)。
;;;   遠方は falloff で凪ぐ。水色 + 掠め角フレネルで空色を映す + 反射トレース(frog が映る)
;;;   + クレストの鋭いハイライト。phase を進めると波紋が外へ広がる (アニメ可)。
;;;
;;; パラメータ定義順 (shade_dr.c の ripples_params[] と一致させること):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 water-color=4 crest-color=5 freq=6 amp=7
;;;   phase=8 falloff=9 center-x=10 center-z=11 fres-tint=12 sky-color=13 Kr=14 spec-color=15

(setq ripples-shader

(make-shader ripples :keyword :surface
      (
       ((Ka float) 0.25)
       ((Kd float) 0.55)
       ((Ks float) 0.90)
       ((roughness float) 0.015)
       ((water-color color) (make-color 0.04 0.16 0.18))   ; 深い水色
       ((crest-color color) (make-color 0.12 0.34 0.36))   ; 波頭=明るい水色
       ((freq float) 3.0)        ; リングの密度
       ((amp  float) 0.6)        ; 波の法線摂動の強さ
       ((phase float) 0.0)       ; 波紋の位相 (増やすと外へ広がる)
       ((falloff float) 0.12)    ; 遠方での減衰 (大=早く凪ぐ)
       ((center-x float) 0.0)    ; 波紋の中心 (xz)
       ((center-z float) 0.0)
       ((fres-tint float) 0.5)   ; 掠め角で空色を映す強さ
       ((sky-color color) (make-color 0.25 0.55 0.62))     ; フレネルで映る空(=背景)
       ((Kr float) 0.45)         ; 反射トレース強度 (frog が水面に映る)
       ((spec-color color) (make-color 1.0 1.0 0.95))
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((dir point) 0)
          ((dx float) 0)
          ((dz float) 0)
          ((rad float) 0)
          ((env float) 0)
          ((ph float) 0)
          ((slope float) 0)
          ((hgt float) 0)
          ((fres float) 0)
          ((nr point) 0)
          ((refl color) (make-color 0 0 0))
          ((base color) (make-color 0 0 0))
          ((hitp float) 0))
    ;; ── 中心からの径距離 (r=0 の特異点を eps で回避) ──
    (setvar dx (- (xcomp Pg) center-x))
    (setvar dz (- (zcomp Pg) center-z))
    (setvar rad (+ (length (make-point dx 0 dz)) 0.0001))
    ;; ── 同心リング: 位相 ph、遠方減衰 env ──
    (setvar ph (- (* rad freq) phase))
    (setvar env (/ 1.0 (+ 1.0 (* falloff rad))))
    (setvar slope (* amp (* env (cos ph))))    ; 径方向スロープ dH/dr
    (setvar hgt   (* env (sin ph)))            ; 波頭の高さ (色用)
    ;; ── 径方向ベクトルに沿って法線を傾ける (波の bump) ──
    (setvar nr (make-point (/ dx rad) 0 (/ dz rad)))
    (setvar Nf (normalize (- Nf (* slope nr))))
    ;; ── 水色: 波頭で明色へ ──
    (setvar base (mix water-color crest-color (clamp (+ 0.5 (* 1.5 hgt)) 0 1)))
    ;; ── 掠め角フレネルで空色を映す ──
    (setvar fres (- 1 (clamp (dot Nf Ir) 0 1)))
    (setvar base (mix base sky-color (* fres-tint fres)))
    ;; ── 反射トレース (frog が水面に映る) ──
    (setvar dir (reflect I Nf))
    (setvar refl (* Kr (trace P dir hitp)))
    ;; ── ライティング (鋭いスペキュラ + 反射加算) ──
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                           (* spec-color Ks (specular Nf Ir roughness)))
                        refl)))
)))

(compile-shader ripples-shader)
(append-shader ripples-shader)
