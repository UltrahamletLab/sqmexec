;;; blobbypaint.lisp — fundza "RSL - Blobby Effects" の移植 (2026-08-03)
;;;
;;; implicit surface の場 Σ(1-smoothstep(0,r,dist)) を**表面の模様**として塗る。
;;; sqm はこの原理のネイティブ実装 (メタボール) なので、これは「同じ数式を
;;; シェーディング側に適用する」チュートリアルの写し。原典の全バリアント統合:
;;;   ・iso 閾値 + blur (ソフト縁)      ・outline 1 = 等値線バンドだけ描く
;;;   ・rN<0 = 負極性ブロブ (場を減算)   ・rN=0 = 無効
;;;   ・ブロブ別カラー (col1..4) を場の重みで混合 (原典 block6)
;;;   ・warp = dist にノイズを乗じて輪郭を歪ませる (原典 block7)
;;; 中心は 3D ワールド座標 (原典どおり 3D 距離 — どんな面にも影響球が交差した
;;; 断面が写る)。配列パラメータが DSL に無いので4個を手展開。
;;;
;;; パラメータ定義順 (shade_dr.cpp の blobbypaint_params[] と一致必須):
;;;   Ka=0 Kd=1 iso=2 blur=3 outline=4 warp=5 warp-freq=6
;;;   p1=7 r1=8 p2=9 r2=10 p3=11 r3=12 p4=13 r4=14
;;;   col1=15 col2=16 col3=17 col4=18 base-color=19
(setq blobbypaint-shader
(make-shader blobbypaint :keyword :surface
  (((Ka float) 0.30)
   ((Kd float) 0.85)
   ((iso float) 0.30)
   ((blur float) 0.05)
   ((outline float) 0.0)
   ((warp float) 0.0)
   ((warp-freq float) 7.0)
   ((p1 point) (make-point -0.95 0 0))  ((r1 float) 1.0)
   ((p2 point) (make-point 0.1 0 1.2))  ((r2 float) 0.6)
   ((p3 point) (make-point 0.85 0 0))   ((r3 float) 1.5)
   ((p4 point) (make-point 0 0 0))      ((r4 float) 0.0)
   ((col1 color) (make-color 1.0 0.20 0.15))
   ((col2 color) (make-color 0.20 0.85 0.35))
   ((col3 color) (make-color 0.25 0.40 1.0))
   ((col4 color) (make-color 1.0 0.85 0.25))
   ((base-color color) (make-color 0.92 0.90 0.85)))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((wn float) 1)
          ((dd float) 0) ((ff float) 0) ((en float) 0)
          ((tf float) 0)
          ((tc color) (make-color 0 0 0))
          ((blend float) 0)
          ((surf color) (make-color 0 0 0)))
    ;; 原典 block7: dist にノイズを乗じて輪郭を歪ませる (warp 0 で恒等)
    (setvar wn (+ (- 1 warp) (* warp (noise (* warp-freq Pg)))))
    ;; ── blob 1..4 (手展開。en=有効, 符号=極性, 色は正極性の場だけ拾う) ──
    (setvar en (step 0.000001 (abs r1)))
    (setvar dd (* (length (- Pg p1)) wn))
    (setvar ff (* en (- 1 (smoothstep 0 (abs r1) dd))))
    (setvar tf (+ tf (* (sign r1) ff)))
    (setvar tc (+ tc (* col1 ff (step 0 r1))))
    (setvar en (step 0.000001 (abs r2)))
    (setvar dd (* (length (- Pg p2)) wn))
    (setvar ff (* en (- 1 (smoothstep 0 (abs r2) dd))))
    (setvar tf (+ tf (* (sign r2) ff)))
    (setvar tc (+ tc (* col2 ff (step 0 r2))))
    (setvar en (step 0.000001 (abs r3)))
    (setvar dd (* (length (- Pg p3)) wn))
    (setvar ff (* en (- 1 (smoothstep 0 (abs r3) dd))))
    (setvar tf (+ tf (* (sign r3) ff)))
    (setvar tc (+ tc (* col3 ff (step 0 r3))))
    (setvar en (step 0.000001 (abs r4)))
    (setvar dd (* (length (- Pg p4)) wn))
    (setvar ff (* en (- 1 (smoothstep 0 (abs r4) dd))))
    (setvar tf (+ tf (* (sign r4) ff)))
    (setvar tc (+ tc (* col4 ff (step 0 r4))))
    ;; 場の色を正規化気味に (原典は /3 + clamp。チャンネル毎 clamp)
    (setvar tc (make-color (clamp (* 0.55 (comp tc 0)) 0 1)
                           (clamp (* 0.55 (comp tc 1)) 0 1)
                           (clamp (* 0.55 (comp tc 2)) 0 1)))
    ;; iso 閾値: outline 0 = 塗り / 1 = 等値線バンド (原典 block4)
    (if (> outline 0.5)
        (setvar blend (* (smoothstep (- iso blur) iso tf)
                         (- 1 (smoothstep iso (+ iso blur) tf))))
        (setvar blend (smoothstep (- iso blur) (+ iso blur) tf)))
    (setvar surf (mix base-color tc blend))
    (setvar Oi Os)
    (setvar Ci (* Oi surf (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))))
)
(compile-shader blobbypaint-shader)
(append-shader blobbypaint-shader)
