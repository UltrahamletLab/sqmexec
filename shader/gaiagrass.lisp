;;; gaiagrass.lisp — 草の葉身シェーダー
;;;
;;; https://github.com/owenyuwono/gaia (grassgen) の bladeMesh.js の見た目を
;;; SQM の DSL に移したもの。原典の色は colorRamp.js の「条件駆動の色スタック」
;;; (chlorophyllVigor / senescence / anthoTint / glaucousness / speciesHue) で、
;;; そこは生成側 (tools/gen_gaia_grass.py) で解いて base/tip/dry の3色にして渡す。
;;; ここでやるのは残りの3つ:
;;;
;;;   1. 基部→先端のグラデーション (原典の base→tip gradient)。
;;;      blob には葉のパラメータが無いのでワールド高さ / blade-top で代用する。
;;;      草は根元が y=0 なので、これは実質「葉に沿った位置」になる。
;;;   2. 株ごとの色ばらつき (原典の aColorJitter = per-instance 属性)。
;;;      blob-bulk は per-blob 属性を持てないので、**株の大きさスケールの
;;;      値格子ノイズ**で置き換える (隣り合う葉が同じ値を引くので株単位に見える)。
;;;   3. **透過光** — 草を草らしく見せる最大の要素。薄い葉は逆光で光を透かす。
;;;      前方散乱の近似 pow(saturate(dot(V,-L)), 3) を lightsel で引いた実ライトに
;;;      掛ける (影も乗る)。
;;;
;;; パラメータ定義順 = shade_dr.cpp の gaiagrass_params[] と一致必須:
;;;   Ka=0 Kd=1 Ks=2 roughness=3 base-color=4 tip-color=5 dry-color=6
;;;   translucency=7 sheen=8 color-variation=9 clump-scale=10 blade-top=11
;;;   sundir=12 sky-color=13 ground-bounce=14

(setq gaiagrass-shader
(make-shader gaiagrass :keyword :surface
  (((Ka float) 0.0) ((Kd float) 1.0) ((Ks float) 1.0)
   ((roughness float) 0.08)
   ((base-color color) (make-color 0.216 0.404 0.184))
   ((tip-color  color) (make-color 0.454 0.545 0.243))
   ((dry-color  color) (make-color 0.706 0.647 0.376))
   ((translucency float) 1.15)   ; 逆光の抜け
   ((sheen        float) 0.5)    ; 葉表のつや
   ((color-variation float) 0.30)
   ((clump-scale  float) 1.6)    ; 株ごとのばらつきの空間スケール [1/m]
   ((blade-top    float) 1.30)   ; 一番高い葉先の高さ [m] (基部→先端の正規化用)
   ((sundir       point) (make-point 0.17 0.14 0.98))
   ((sky-color    color) (make-color 0.45 0.60 0.80))
   ((ground-bounce float) 0.16))
  (enter (
    ((Nf   point) (faceforward (normalize N) I))
    ((vd   point) (normalize (- I)))
    ((sdir point) (make-point 0 1 0))
    ((ht float) 0) ((vr float) 0) ((gvis float) 0)
    ((bck float) 0) ((upn float) 0)
    ((col  color) (make-color 0 0 0))
    ((lit  color) (make-color 0 0 0))
    ((amb  color) (make-color 0 0 0)))

  (setvar sdir (normalize sundir))

  ;; --- 基部→先端 + 株ごとのばらつき --------------------------------------
  (setvar ht (clamp (/ (ycomp Pg) (max blade-top 0.01)) 0 1))
  (setvar col (mix base-color tip-color (* ht ht)))
  (setvar vr (- (vfbm (make-point (* (xcomp Pg) clump-scale) 2.7
                                  (* (zcomp Pg) clump-scale)) 2) 0.5))
  (setvar col (mix col dry-color (clamp (* color-variation (+ 0.5 vr)) 0 1)))

  ;; --- 直射 (影込み) ------------------------------------------------------
  (setvar lit (* Kd col (diffuse Nf)))

  ;; --- 透過光: 逆光で葉が光る (前方散乱の近似) ---------------------------
  ;;     lightsel で **実ライトの L と Cl (可視性込み)** を引く。sundir param は
  ;;     空/地面フィルの向きにだけ使う (太陽が影に入れば透過も消えるのが正しい)。
  (setvar gvis (lightsel 0))
  (setvar bck (pow (clamp (dot vd (- L)) 0 1) 3))
  (setvar lit (+ lit (* col Cl bck translucency)))

  ;; --- 空と地面の環境光 ---------------------------------------------------
  (setvar upn (* 0.5 (+ 1 (ycomp Nf))))
  (setvar amb (* col (+ (* sky-color upn) (* base-color ground-bounce (- 1 upn)))))

  ;; --- 葉表のつや ---------------------------------------------------------
  (setvar lit (+ lit (* Ks sheen (specular Nf vd roughness))))

  (setvar Oi Os)
  (setvar Ci (* Oi (+ lit amb (* Ka col (ambient)))))
)))

(compile-shader gaiagrass-shader)
(append-shader gaiagrass-shader)
