;;; terracotta — 風化した無釉の赤褐色土器 (古代の壺)。photorealistic 志向。
;;;   ・base-color を土台に、大スケール vfbm で「火だすき/煤」の暗い斑 (dark-color) と
;;;     擦れて明るくなった高所 (light-color) をブレンド = 均質さを排除
;;;   ・微細グレイン (中周波 vfbm) で色の粒状ムラ
;;;   ・肩の刻線帯 (band-y 周辺) を波打つ暗い register として描く (刻線に溜まった土=暗色)
;;;   ・vfbm 勾配の法線バンプで素地のざらつき (engine 共有ノイズ noise.c と同系統)
;;;   ・掠め角で薄く埃っぽく明るむ疑似リム (aged dusty sheen)
;;;   ・マット: 低 Ks・高 roughness。凹凸(縦ローブ/うねり)は SDF displace(mode lobes)側で担当。
;;;
;;; パラメータ定義順 (shade_dr.c の terracotta_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 base-color=4 dark-color=5 light-color=6
;;;   cloud-scale=7 cloud-amp=8 grain-scale=9 grain-amp=10 band-y=11 band-w=12
;;;   bump-amp=13 bump-scale=14 spec-color=15

(setq terracotta-shader

(make-shader terracotta :keyword :surface
      (
       ((Ka float) 0.28)
       ((Kd float) 0.90)
       ((Ks float) 0.05)
       ((roughness float) 0.55)
       ((base-color  color) (make-color 0.55 0.32 0.24))   ; 赤褐色テラコッタ
       ((dark-color  color) (make-color 0.27 0.17 0.13))   ; 火だすき/煤/刻線の暗色
       ((light-color color) (make-color 0.70 0.52 0.42))   ; 擦れて明るい素地
       ((cloud-scale float) 2.4)     ; 火だすき斑の空間周波数 (大スケール)
       ((cloud-amp   float) 2.2)     ; 暗斑のコントラスト
       ((grain-scale float) 26.0)    ; 微細グレインの周波数
       ((grain-amp   float) 0.13)    ; 微細グレインの強さ
       ((band-y      float) 1.00)    ; 肩の刻線帯の中心高さ (world y)
       ((band-w      float) 0.05)    ; 刻線帯の半幅
       ((bump-amp    float) 0.55)    ; 素地ざらつきバンプの振幅
       ((bump-scale  float) 22.0)    ; 同・周波数
       ((spec-color  color) (make-color 1.0 0.96 0.88))
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((bp point) 0)
          ((n0 float) 0) ((nx float) 0) ((ny float) 0) ((nz float) 0)
          ((grad point) 0)
          ((nc float) 0) ((dk float) 0)
          ((nl float) 0) ((lt float) 0)
          ((ng float) 0)
          ((we float) 0) ((dyc float) 0) ((bandm float) 0) ((bandtex float) 0)
          ((fres float) 0)
          ((base color) (make-color 0 0 0))
          ((be float) 0.05))
    ;; ── 素地ざらつき bump: vfbm 有限差分勾配で法線を摂動 ──
    (setvar bp (* Pg bump-scale))
    (setvar n0 (vfbm bp 4))
    (setvar nx (vfbm (+ bp (make-point be 0 0)) 4))
    (setvar ny (vfbm (+ bp (make-point 0 be 0)) 4))
    (setvar nz (vfbm (+ bp (make-point 0 0 be)) 4))
    (setvar grad (make-point (- nx n0) (- ny n0) (- nz n0)))
    (setvar Nf (normalize (- Nf (* bump-amp grad))))
    ;; ── 土台色 ──
    (setvar base base-color)
    ;; ── 火だすき/煤: 大スケール vfbm の高い所を dark-color へ ──
    (setvar nc (vfbm (* Pg cloud-scale) 4))
    (setvar dk (clamp (* (- nc 0.48) cloud-amp) 0 1))
    (setvar base (mix base dark-color (* dk 0.75)))
    ;; ── 擦れて明るい高所: 別スケール vfbm の高い所を light-color へ ──
    (setvar nl (vfbm (+ (* Pg (* cloud-scale 2.1)) (make-point 3.1 1.7 5.9)) 4))
    (setvar lt (clamp (* (- nl 0.60) 1.7) 0 1))
    (setvar base (mix base light-color (* lt 0.45)))
    ;; ── 肩の刻線帯: 波打つ暗い register (刻線に溜まった土) ──
    (setvar we (* (- (vfbm (+ (* Pg 6.0) (make-point 1.3 0 4.7)) 2) 0.5) 0.03))
    (setvar dyc (abs (+ (- (ycomp Pg) band-y) we)))
    (setvar bandm (- 1 (smoothstep band-w (+ band-w 0.045) dyc)))
    (setvar bandtex (vfbm (+ (* Pg (* grain-scale 0.6)) (make-point 3.7 0 2.9)) 3))
    (setvar base (mix base dark-color (* bandm (+ 0.28 (* 0.34 bandtex)))))
    ;; ── 微細グレイン (平均1を保つ色の粒ムラ) ──
    (setvar ng (vfbm (* Pg grain-scale) 3))
    (setvar base (* base (+ (- 1 grain-amp) (* grain-amp 2 ng))))
    ;; ── 疑似リム: 掠め角で薄く埃っぽく明るむ ──
    (setvar fres (- 1 (clamp (dot Nf Ir) 0 1)))
    (setvar base (mix base light-color (* 0.12 (* fres fres))))
    ;; ── ライティング (マット) ──
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* spec-color Ks (specular Nf Ir roughness)))))
)))

(compile-shader terracotta-shader)
(append-shader terracotta-shader)
