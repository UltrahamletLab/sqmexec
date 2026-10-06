;;; bsdffresnel — PT (-Q) 用の**視点依存**材質シェーダー実例 (2026-08-02)
;;;
;;; dr_bsdf_material が I (視線) を渡すようになった (同日実装) ことの実証。
;;; 掠め角ほど edge-color が立つ Schlick フレネルでアルベドを混ぜる —
;;; フレネルのリム / 光沢の縁立ち / 層の色づきの基本形。
;;;
;;; I の規約 (RenderMan 本来): 視点(前のパス頂点)→P の全長ベクトル。E = P - I。
;;;   ※クラシック :surface の I (単位方向) と違い長さ=距離を持つ。方向を使う
;;;     ときは正規化すること。
;;; **|I| = 0 は「無効」** — SPPM (-J) / BDPT (-W) / VCM (-U) の経路では
;;; エンジンが I=0 を渡す (相互律を壊す視点依存項を双方向系に持ち込まない
;;; ための明示的な無効化)。視点依存項は必ず |I| でゲートすること。
;;; → このシェーダーは |I|=0 のとき base-color に落ちる (視点依存項オフ)。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdffresnel)
;;;            (param base-color 0.05 0.05 0.06)
;;;            (param edge-color 0.85 0.30 0.10)
;;;            (param f0 0.04) (param power 5.0)
;;;            (param rough 0.30) (param metallic 0.0))
;;;
;;; 詳細: docs/2026-08-02_PTブリッジに視線方向Iを渡す_検討.md (sqm 側)

(setq bsdffresnel-shader

(make-shader bsdffresnel :keyword :volume
      (((base-color color) (make-color 0.05 0.05 0.06))  ; 正面の色
       ((edge-color color) (make-color 0.85 0.30 0.10))  ; 掠め角の色
       ((f0       float) 0.04)   ; 正面での混合率の床 (Schlick F0)
       ((power    float) 5.0)    ; Schlick 指数
       ((rough    float) 0.30)
       ((metallic float) 0.0))

  (enter (((len  float) 0.0)
          ((cosv float) 0.0)
          ((fres float) 0.0))

    ;; cosθ = |N̂·I| / |I|。normalize(I) は |I|=0 で NaN を生むので
    ;; 素の dot を clamp した長さで割る (全経路 NaN フリー)
    (setvar len  (sqrt (dot I I)))
    (setvar cosv (/ (abs (dot (normalize N) I))
                    (clamp len 0.000001 1000000.0)))
    (setvar cosv (clamp cosv 0.0 1.0))

    ;; Schlick: F = f0 + (1-f0)(1-cosθ)^power、|I|=0 なら 0 (無効ゲート)
    (setvar fres (+ f0 (* (- 1.0 f0) (pow (- 1.0 cosv) power))))
    (setvar fres (* fres (clamp (* len 100000.0) 0.0 1.0)))

    (setvar Cl (mix base-color edge-color fres))
    (setvar Oi (make-color rough metallic 0.0))
)))

(compile-shader bsdffresnel-shader)
(append-shader bsdffresnel-shader)
