;;; toon
;;;
;;; セルシェーディング (トゥーン) サーフェスシェーダー。
;;;   - 拡散光を levels 段に量子化してフラットな塗り分けにする
;;;   - スペキュラを閾値でハード化したハイライト
;;;   - シルエット (かすめ角) に暗いアウトラインを描く
;;;
;;; パラメータ定義順 (shade_dr.c の toon_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 levels=4 edge-width=5
;;;   spec-threshold=6 edge-color=7 specular-color=8


(setq toon-shader

(make-shader toon :keyword :surface
      (
       ((Ka float) 0.30)
       ((Kd float) 0.70)
       ((Ks float) 0.50)
       ((roughness float) 0.05)
       ((levels float) 3)
       ((edge-width float) 0.30)
       ((spec-threshold float) 0.50)
       ((edge-color color) (make-color 0 0 0))
       ((specular-color color) (make-color 1 1 1))
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((d color) (make-color 0 0 0))
          ((dq color) (make-color 0 0 0))
          ((sp color) (make-color 0 0 0))
          ((base color) (make-color 0 0 0))
          ((qx float) 0) ((qy float) 0) ((qz float) 0)
          ((slum float) 0) ((son float) 0)
          ((fres float) 0) ((rim float) 0) ((e0 float) 0) ((e1 float) 0))
    ;; ── 拡散光を levels 段に量子化 (光色は保ったままチャンネルごとに段化) ──
    (setvar d (diffuse Nf))
    (setvar qx (/ (floor (* (comp d 0) levels)) levels))
    (setvar qy (/ (floor (* (comp d 1) levels)) levels))
    (setvar qz (/ (floor (* (comp d 2) levels)) levels))
    (setvar dq (make-color qx qy qz))
    (setvar base (* Cs (+ (* Ka (ambient)) (* Kd dq))))
    ;; ── スペキュラを閾値でオン/オフ化したハードハイライト ──
    (setvar sp (specular Nf Ir roughness))
    (setvar slum (* 0.3333 (+ (+ (comp sp 0) (comp sp 1)) (comp sp 2))))
    (setvar son (step spec-threshold slum))
    (setvar base (+ base (* son (* Ks specular-color))))
    ;; ── シルエットのアウトライン (かすめ角ほど edge-color に寄せる) ──
    (setvar fres (- 1 (dot Nf Ir)))
    (setvar e0 (- (- 1 edge-width) 0.03))
    (setvar e1 (+ (- 1 edge-width) 0.03))
    (setvar rim (smoothstep e0 e1 fres))
    (setvar base (mix base edge-color rim))
    ;; ── 出力 ──
    (setvar Oi Os)
    (setvar Ci (* Oi base))
)))

(compile-shader toon-shader)
(append-shader toon-shader)
