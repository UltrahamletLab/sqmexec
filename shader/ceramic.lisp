;;; ceramic — 陶磁器 (釉薬の硬いハイライト)
;;;
;;; 移植元: BMRT ceramic.sl + material.h の MaterialCeramic
;;;         + locillum.h の LocIllumGlossy
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;;   Ci = Cs*(Ka*ambient() + Kd*diffuse(Nf)) + Ks*LocIllumGlossy(Nf, V, roughness/10, sharp)
;;;   LocIllumGlossy: 芯が一様に明るく縁が急峻に落ちるハイライト (ガラス/液体/釉薬向け)。
;;;     w = 0.18*(1-sharpness)
;;;     C = Σ Cl * smoothstep(0.72-w, 0.72+w, pow(max(0, N.H), 1/roughness))
;;;   ※ Blinn の pow ローブを smoothstep で**閾値化**するのが肝 — specular() の
;;;     なだらかな山でなく「白い円盤」に近い硬いハイライトになる。
;;;
;;; ── sqm 版の違い ────────────────────────────────────────────────
;;; ・illuminance は光源反復フック (lightcount)/(lightsel) で回す (2026-08-09 新設,
;;;   brushedmetal と同じ)。lightsource("__nonspecular") 相当は sqm に無いので落とした。
;;; ・原典が**宣言だけして使っていない** Kr/blur/eta (MaterialCeramic は受け取らない):
;;;   Kr だけ trace で繋いだ。**既定 0 なので既定では原典と同じ絵** (宣言側の
;;;   既定 1 をそのまま繋ぐと原典の出力と変わってしまうため)。blur/eta は
;;;   sqm の trace が円錐ジッタ/フレネルを持たないので落とした (docs 参照)。
;;; ・ローカル名 V はグローバル v と大文字小文字非区別で衝突する → Vd。
;;;
;;; パラメータ定義順 (shade_dr.cpp の ceramic_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 specsharpness=4 Kr=5
;;;
;;; 使い方 (シーン):
;;;   (surface (color 0.30 0.42 0.55) (ka 0.2) (kd 0.5) (ks 0.5) (phong 0)
;;;            (shader ceramic)
;;;            (param roughness 0.1) (param specsharpness 0.5) (param Kr 0.12))
;;;   ※ phong>0 は roughness を 1/phong で上書きするので (phong 0) + param で渡す。
;;;   ※ specsharpness 1 = 縁が無限に鋭い円盤 / 0 = 鈍い。

(setq ceramic-shader

(make-shader ceramic :keyword :surface
      (
       ((Ka            float) 1.0)
       ((Kd            float) 0.5)
       ((Ks            float) 0.5)
       ((roughness     float) 0.1)
       ((specsharpness float) 0.5)
       ((Kr            float) 0.0)   ; 反射 (原典は宣言のみ→既定0で原典と同じ絵)
       )

  (enter (((Nf   point) (faceforward (normalize N) I))
          ((Vd   point) (normalize (- I)))
          ((H    point) (make-point 0 0 1))
          ((w    float) (* 0.18 (- 1.0 specsharpness)))
          ((expo float) (/ 10.0 (max roughness 0.0001)))  ; = 1/(roughness/10)
          ((nl   float) 0.0) ((j float) 0.0) ((g float) 0.0)
          ((nh   float) 0.0)
          ((spec color) (make-color 0 0 0))
          ((rdir point) (make-point 0 0 1))
          ((refl color) (make-color 0 0 0))
          ((hitf float) 0.0))

    ;; ── LocIllumGlossy: 光源を回して閾値化ハイライトを積む ─────────
    (setvar nl (lightcount))
    (repeat (j nl)
      (setvar g (lightsel j))          ; L (面→光源, 単位)・Cl (可視度込み) が書かれる
      (setvar H (normalize (+ (normalize L) Vd)))
      (setvar nh (max (dot Nf H) 0.0))
      (setvar spec (+ spec (* Cl (smoothstep (- 0.72 w) (+ 0.72 w)
                                             (pow nh expo))))))

    (setvar Ci (+ (* Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                  (* Ks spec)))

    ;; ── Kr: 反射 (原典の宣言を繋いだ拡張。既定 0 = 原典どおり) ─────
    (if (> Kr 0.0)
        (progn
          (setvar rdir (reflect I Nf))
          (setvar refl (trace P rdir hitf))
          (setvar Ci (+ Ci (* Kr refl)))))

    (setvar Oi Os)
    (setvar Ci (* Oi Ci))
)))

(compile-shader ceramic-shader)
(append-shader ceramic-shader)
