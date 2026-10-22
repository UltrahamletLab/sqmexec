;;; bsdflayer — 吸収つきクリアコート層の色づき (PT -Q 材質, 2026-08-02)
;;;
;;; 検討 doc (2026-08-02_PTブリッジに視線方向I) §4 の「層構造の色づき」の実装:
;;; 透明な着色層 (漆・琥珀コート・キャンディ塗装) を斜めに通る光路は 1/cosθ で
;;; 伸びる → Beer-Lambert で **掠め角ほど層の色が濃く沈む**。溜塗の物理そのもの。
;;;   Cl = base-color × coat-color^(thickness/cosθ)   (チャンネル毎の減衰)
;;;
;;; I の規約: 視点→P の全長ベクトル。**|I|=0 (SPPM/BDPT/VCM) は垂直入射扱い**
;;; (cosθ=1) — 層の色は残し角度依存だけ消える、が最も破綻の少ない退避。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdflayer)
;;;            (param base-color 0.80 0.62 0.28)   ; 下地 (金梨地など)
;;;            (param coat-color 0.60 0.18 0.06)   ; コートの透過色 (溜漆)
;;;            (param thickness 1.2)
;;;            (param rough 0.10) (param metallic 0.35))

(setq bsdflayer-shader

(make-shader bsdflayer :keyword :volume
      (((base-color color) (make-color 0.80 0.62 0.28))
       ((coat-color color) (make-color 0.60 0.18 0.06))
       ((thickness  float) 1.2)     ; 層の光学的厚み (往復ぶん込み)
       ((rough      float) 0.10)
       ((metallic   float) 0.35))

  (enter (((len   float) 0.0)
          ((valid float) 0.0)
          ((cosv  float) 0.0)
          ((plen  float) 0.0)
          ((ar    float) 0.0)
          ((ag    float) 0.0)
          ((ab    float) 0.0))

    (setvar len   (sqrt (dot I I)))
    (setvar valid (clamp (* len 100000.0) 0.0 1.0))
    (setvar cosv  (/ (abs (dot (normalize N) I))
                     (clamp len 0.000001 1000000.0)))
    (setvar cosv  (clamp cosv 0.08 1.0))          ; 掠め角の発散を抑える床
    ;; |I|=0 → cosθ=1 (垂直入射相当): cosv_eff = 1 + valid·(cosv−1)
    (setvar cosv (+ 1.0 (* valid (- cosv 1.0))))

    ;; Beer-Lambert: 層内光路 = thickness/cosθ、チャンネル毎に減衰
    (setvar plen (/ thickness cosv))
    (setvar ar (pow (clamp (comp coat-color 0) 0.001 1.0) plen))
    (setvar ag (pow (clamp (comp coat-color 1) 0.001 1.0) plen))
    (setvar ab (pow (clamp (comp coat-color 2) 0.001 1.0) plen))
    (setvar Cl (make-color (* (comp base-color 0) ar)
                           (* (comp base-color 1) ag)
                           (* (comp base-color 2) ab)))
    (setvar Oi (make-color rough metallic 0.0))
)))

(compile-shader bsdflayer-shader)
(append-shader bsdflayer-shader)
