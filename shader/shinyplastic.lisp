;;; shinyplastic
;;; Shiny plastic surface — diffuse + white specular + ray-traced reflection.
;;;
;;; Converted from:
;;;   shinyplastic.sl + MaterialShinyPlastic (BMRT)
;;;   (c) 1990-2000 Exluna, Inc. / Larry Gritz
;;;
;;; DR notes:
;;;   - SampleEnvironment → (trace P R intersected) / blur は pbrenv 代替 (見送り記録)
;;;   - specular is WHITE (plastic behavior, not metal)
;;;   - twosided は落とした (sqm の trace は深さ上限で自衛)
;;;
;;; 2026-08-09: 本ファイルは**未ビルドの孤児ソース**だった (core/テーブル/build-all
;;;   全部無し — roughmetal/shinymetal と同景)。使用シーンゼロなので、旧註の
;;;   「fresnel() not available」を現在の作法 (Schlick を .lisp で) に改め、
;;;   **原典 MaterialShinyPlastic どおりのフレネル**でフル配線した:
;;;     fkr = Schlick(F0(ior), cosθ) → 反射は fkr·Kr / 拡散+ambient は fkt=1−fkr
;;;   正面は映り込みが弱く縁で強い = ニス/ラッカーの応答。

(setq shinyplastic-shader

(make-shader shinyplastic :keyword :surface
      (((Ka        float)  1.0)
       ((Kd        float)  0.5)
       ((Ks        float)  0.5)
       ((roughness float)  0.1)
       ((Kr        float)  1.0)    ; 反射率 (フレネル込みなので原典既定 1)
       ((ior       float)  1.5))   ; 屈折率 → F0 = ((ior−1)/(ior+1))²

  (enter (
    ((Nf          point) (faceforward (normalize N) I))
    ((Ir          point) (normalize (- I)))
    ((R           point) (reflect I Nf))
    ((intersected float)  0.0)
    ((F0          float)  0.0)
    ((fkr         float)  0.0)
    ((refl        color)  (make-color 0 0 0)))

    ;; Schlick フレネル (原典の fresnel(IN, Nf, 1/ior, ..) 相当)
    (setvar F0 (pow (/ (- ior 1.0) (+ ior 1.0)) 2.0))
    (setvar fkr (+ F0 (* (- 1.0 F0)
                         (pow (- 1.0 (clamp (dot Nf Ir) 0.0 1.0)) 5.0))))

    ;; 反射トレース (fkr·Kr 重み)
    (setvar refl (* (* Kr fkr) (trace P R intersected)))

    (setvar Oi Os)
    ;; plastic: diffuse は Cs で着色 (fkt=1−fkr 減衰)、specular は白
    (setvar Ci (* Oi
                  (+ (* Cs (* (- 1.0 fkr)
                              (+ (* Ka (ambient))
                                 (* Kd (diffuse Nf)))))
                     (* Ks (specular Nf Ir roughness))
                     refl))))))

(compile-shader shinyplastic-shader)
(append-shader shinyplastic-shader)
