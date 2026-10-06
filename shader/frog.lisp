;;; frog — 蛙の肌。背=濃緑/腹=明るい黄緑の高さ勾配 + まだら斑点(共有値fBm) +
;;;        しっとりした疑似SSS(掠め角=フレネルで縁が明るい黄緑へ透ける) +
;;;        微細な皮膚の凹凸(vfbm勾配で法線を摂動するbump)。
;;;   斑点・bump は engine 共有ノイズ vnoise/vfbm (noise.c) を使い SDF/ボリュームと同系統。
;;;
;;; パラメータ定義順 (shade_dr.c の frog_params[] と一致させること):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 back-color=4 belly-color=5 spot-color=6
;;;   sss-color=7 spot-scale=8 spot-amp=9 low-y=10 high-y=11 sss=12
;;;   bump-amp=13 bump-scale=14 spec-color=15

(setq frog-shader

(make-shader frog :keyword :surface
      (
       ((Ka float) 0.22)
       ((Kd float) 0.78)
       ((Ks float) 0.40)
       ((roughness float) 0.06)
       ((back-color  color) (make-color 0.10 0.34 0.16))   ; 背=濃緑 (高所 high-y)
       ((belly-color color) (make-color 0.62 0.78 0.42))   ; 腹=明るい黄緑 (低所 low-y)
       ((spot-color  color) (make-color 0.05 0.18 0.08))   ; まだら斑点=暗緑
       ((sss-color   color) (make-color 0.55 0.80 0.30))   ; SSS縁=透けた黄緑
       ((spot-scale float) 3.0)     ; 斑点の空間周波数
       ((spot-amp   float) 1.6)     ; 斑点のコントラスト
       ((low-y  float) -3.0)        ; 腹(明)になる高さ
       ((high-y float)  2.0)        ; 背(濃)になる高さ
       ((sss    float) 0.5)         ; 縁のSSS(フレネル)強度
       ((bump-amp   float) 1.5)     ; 皮膚凹凸の振幅
       ((bump-scale float) 8.0)     ; 皮膚凹凸の周波数
       ((spec-color color) (make-color 1.0 0.98 0.88))
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((bp point) 0)
          ((n0 float) 0)
          ((nx float) 0)
          ((ny float) 0)
          ((nz float) 0)
          ((grad point) 0)
          ((th float) 0)
          ((spots float) 0)
          ((fres float) 0)
          ((base color) (make-color 0 0 0))
          ((oct float) 5)
          ((be float) 0.04))
    ;; ── bump: vfbm の有限差分勾配で法線を摂動 (微細な皮膚の凹凸) ──
    (setvar bp (* Pg bump-scale))
    (setvar n0 (vfbm bp 4))
    (setvar nx (vfbm (+ bp (make-point be 0 0)) 4))
    (setvar ny (vfbm (+ bp (make-point 0 be 0)) 4))
    (setvar nz (vfbm (+ bp (make-point 0 0 be)) 4))
    (setvar grad (make-point (- nx n0) (- ny n0) (- nz n0)))
    (setvar Nf (normalize (- Nf (* bump-amp grad))))
    ;; ── 高さ勾配: 腹(low-y)=0 → 背(high-y)=1 ──
    (setvar th (smoothstep low-y high-y (ycomp Pg)))
    (setvar base (mix belly-color back-color th))
    ;; ── まだら斑点: 共有値fBm で部分的に spot-color へ ──
    (setvar spots (clamp (* (- (vfbm (* Pg spot-scale) oct) 0.45) spot-amp) 0 1))
    (setvar base (mix base spot-color spots))
    ;; ── 疑似SSS: 掠め角ほど縁が透けた黄緑へ (しっとり感) ──
    (setvar fres (- 1 (clamp (dot Nf Ir) 0 1)))
    (setvar base (mix base sss-color (* sss fres)))
    ;; ── ライティング ──
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* spec-color Ks (specular Nf Ir roughness)))))
)))

(compile-shader frog-shader)
(append-shader frog-shader)
