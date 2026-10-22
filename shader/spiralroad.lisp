;;; spiralroad — 螺旋道路の時代進化路面 (web/spiral_road_preview.html の roadCol 移植)。
;;;   竜巻状スパイラル道路 (spiral-tube SDF) の上面を、付け根→先端 (θ=0→thmax) で
;;;   土(轍) → 石板(割れ目) → 砂利 → 石畳(千鳥+目地) → アスファルト(白線+黄破線) と進化させる。
;;;   θ は y↔θ の単調対応から解析復元: th=(Pg.y - yb)/rr。断面横座標 uu=|Pg.xz|-r(θ)。
;;;   ノイズは engine 共有 vnoise/vfbm (noise.c)。側面/裏面は法線yでコンクリ構造色へ。
;;;
;;; パラメータ定義順 (shade_dr.c の spiralroad_params[] と一致させること):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 yb=4 rr=5 ra=6 rb=7 thmax=8 hw=9 spec-color=10

(setq spiralroad-shader

(make-shader spiralroad :keyword :surface
      (
       ((Ka float) 0.18)
       ((Kd float) 0.85)
       ((Ks float) 0.10)
       ((roughness float) 0.15)
       ((yb float) -1.50)          ; 螺旋の y-base (θ=0 の高さ)
       ((rr float) 0.25199)        ; rise_rate = 全上昇 / θmax
       ((ra float) 0.80)           ; r(θ)=ra+rb*θ の付け根半径
       ((rb float) 0.10080)        ; dr/dθ
       ((thmax float) 37.699)      ; 完全成長時の θmax (ステージ正規化用・成長中も固定)
       ((hw float) 0.55)           ; 道の半幅 (白線の位置)
       ((spec-color color) (make-color 1.0 1.0 1.0))
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((th float) 0)
          ((rc float) 0)
          ((uu float) 0)
          ((au float) 0)
          ((sl float) 0)
          ((stage float) 0)
          ((dn float) 0)
          ((rut float) 0)
          ((pn float) 0)
          ((crack float) 0)
          ((gv float) 0)
          ((gv2 float) 0)
          ((cbx float) 0)
          ((cby float) 0)
          ((cellx float) 0)
          ((celly float) 0)
          ((fx float) 0)
          ((fy float) 0)
          ((shade float) 0)
          ((ebx float) 0)
          ((eby float) 0)
          ((ebm float) 0)
          ((mortar float) 0)
          ((an float) 0)
          ((edgef float) 0)
          ((dash float) 0)
          ((cline float) 0)
          ((topness float) 0)
          ((dirtc color) (make-color 0 0 0))
          ((stonec color) (make-color 0 0 0))
          ((gravelc color) (make-color 0 0 0))
          ((cobblec color) (make-color 0 0 0))
          ((asphc color) (make-color 0 0 0))
          ((base color) (make-color 0 0 0)))
    ;; ── 道路座標の解析復元: θ ← y (単調), 断面横 uu, 縦(弧長風) sl ──
    (setvar th (clamp (/ (- (ycomp Pg) yb) rr) 0 thmax))
    (setvar rc (+ ra (* rb th)))
    (setvar uu (- (sqrt (+ (* (xcomp Pg) (xcomp Pg)) (* (zcomp Pg) (zcomp Pg)))) rc))
    (setvar au (abs uu))
    (setvar sl (* th rc))
    (setvar stage (/ th thmax))
    ;; ── 1) 土 (石器時代): fBm まだら + 2本の轍 ──
    (setvar dn (vfbm (make-point (* sl 2.2) 3.1 (* uu 5.0)) 5))
    (setvar rut (- 1 (smoothstep 0.03 0.10 (abs (- au 0.20)))))
    (setvar dirtc (mix (make-color 0.44 0.31 0.19) (make-color 0.30 0.20 0.11) dn))
    (setvar dirtc (* dirtc (- 1 (* 0.25 rut))))
    ;; ── 2) 石の道 (古代): 大きな石板 + 割れ目 ──
    (setvar pn (vfbm (make-point (* sl 1.4) 7.7 (* uu 3.0)) 5))
    (setvar crack (smoothstep 0.46 0.50 (abs (- (mod (* pn 3.0) 1.0) 0.5))))
    (setvar stonec (mix (make-color 0.40 0.38 0.35) (make-color 0.52 0.50 0.46) pn))
    (setvar stonec (* stonec (+ 0.55 (* 0.45 crack))))
    ;; ── 3) 砂利道 (中世): 高周波の粒 2層 ──
    (setvar gv  (vnoise (make-point (* sl 40.0) 11.3 (* uu 40.0))))
    (setvar gv2 (vnoise (make-point (+ (* sl 90.0) 7.0) 5.9 (* uu 90.0))))
    (setvar gravelc (* (make-color 0.50 0.48 0.45) (+ 0.62 (* 0.5 gv)) (+ 0.8 (* 0.35 gv2))))
    ;; ── 4) 石畳 (近代): 千鳥格子セル + 目地 (セル明度=格子点ハッシュ) ──
    (setvar cbx (* sl 6.0))
    (setvar cby (* uu 7.0))
    (setvar cbx (+ cbx (* (step 0.5 (mod (* cby 0.5) 1.0)) 0.5)))
    (setvar cellx (floor cbx))
    (setvar celly (floor cby))
    (setvar fx (- cbx cellx))
    (setvar fy (- cby celly))
    (setvar shade (+ 0.75 (* 0.5 (vnoise (make-point cellx 17.0 celly)))))
    (setvar ebx (clamp fx -99 (- 1 fx)))
    (setvar eby (clamp fy -99 (- 1 fy)))
    (setvar ebm (clamp ebx -99 eby))
    (setvar mortar (smoothstep 0.10 0.16 ebm))
    (setvar cobblec (mix (make-color 0.26 0.25 0.26)
                         (* (make-color 0.47 0.45 0.44) shade) mortar))
    ;; ── 5) アスファルト (現代): 白いエッジライン + 黄色の破線センター ──
    (setvar an (vfbm (make-point (* (xcomp Pg) 6.0) 2.2 (* (zcomp Pg) 6.0)) 4))
    (setvar asphc (* (make-color 0.135 0.135 0.145) (+ 0.9 (* 0.2 an))))
    (setvar edgef (- 1 (smoothstep 0.012 0.030 (abs (- au (- hw 0.075))))))
    (setvar dash (step 0.5 (mod (* th 4.2) 1.0)))
    (setvar cline (* (- 1 (smoothstep 0.012 0.028 au)) dash))
    (setvar asphc (mix asphc (make-color 0.85 0.85 0.88) (* edgef 0.9)))
    (setvar asphc (mix asphc (make-color 0.95 0.75 0.15) (* cline 0.95)))
    ;; ── ステージ合成 (境界±0.03 をブレンド) ──
    (setvar base dirtc)
    (setvar base (mix base stonec  (smoothstep 0.17 0.23 stage)))
    (setvar base (mix base gravelc (smoothstep 0.37 0.43 stage)))
    (setvar base (mix base cobblec (smoothstep 0.57 0.63 stage)))
    (setvar base (mix base asphc   (smoothstep 0.77 0.83 stage)))
    ;; ── 側面/裏面はコンクリ構造色 (法線の上向き度でブレンド) ──
    (setvar topness (clamp (ycomp Nf) 0 1))
    (setvar base (mix (make-color 0.42 0.40 0.37) base (smoothstep 0.35 0.8 topness)))
    ;; ── ライティング ──
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* spec-color Ks (specular Nf Ir roughness)))))
)))

(compile-shader spiralroad-shader)
(append-shader spiralroad-shader)
