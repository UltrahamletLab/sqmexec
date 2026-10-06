;;;; pbrsurface.lisp — 物理ベース (metallic/roughness) サーフェスシェーダー。
;;;; 直接光: 多灯 Cook-Torrance (GGX NDF / Smith G / Schlick F) を C 側フック (pbr) で評価。
;;;; 環境光: フレネル重み付きの一バウンス反射 (trace) を split-sum 風に加算 = IBL 鏡面。
;;;;   albedo = Cs。F0 = mix(誘電体0.04, Cs, metallic)。metallic 0=誘電体 / 1=金属。
;;;;   Ka=拡散アンビ(擬似GI), Kd/Ks=直接光の拡散/鏡面倍率, Kr=環境反射倍率。
;;;;   反射は単一 trace=鏡面。roughness が上がると ambient へブレンドして曇らせる(安価な光沢近似)。
(setq pbrsurface-shader
(make-shader pbrsurface :keyword :surface
      (  ;; ── params: 並び順 == surfaceArgs index 0,1,2,... ──
       ((Ka float) 0.2)
       ((Kd float) 1.0)
       ((Ks float) 1.0)
       ((roughness float) 0.3)
       ((metallic float) 0.0)
       ((Kr float) 1.0)
      )
  (enter (((Nf point)         (faceforward (normalize N) I))
          ((Ir point)         (normalize (- I)))
          ((dielectric color) (make-color 0.04 0.04 0.04))
          ((F0 color)         (make-color 0 0 0))
          ((direct color)     (make-color 0 0 0))
          ((amb color)        (make-color 0 0 0))
          ((refl color)       (make-color 0 0 0)))
    ;; F0: 誘電体は 0.04、金属は albedo 色に寄せる
    (setvar F0 (mix dielectric Cs metallic))
    ;; 直接光: 拡散(Lambert)+鏡面(GGX) を多灯合算
    (setvar direct (pbr Nf Ir roughness metallic F0 Kd Ks))
    ;; 環境反射: GGX重要度サンプルのグロッシー反射 (C側 pbrenv)。粗さに応じて
    ;; 実シーンがボケて映る。フレネル(粗さ対応Schlick)は C 側で適用済み。
    ;; ノブ: SQM_PBR_ENV_SAMPLES (既定8, roughness<0.06は鏡面1本)。
    (setvar refl (pbrenv Nf Ir roughness F0))
    (setvar amb  (ambient))
    (setvar Oi Os)
    ;; 拡散アンビは金属では消す((1-metallic))。最終 = 拡散アンビ + 直接光 + グロッシー反射
    (setvar Ci (* Oi (+ (+ (* Cs (* Ka (* (- 1 metallic) amb))) direct)
                        (* Kr refl)))))))
(compile-shader pbrsurface-shader)
(append-shader pbrsurface-shader)
