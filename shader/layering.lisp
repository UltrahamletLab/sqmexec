;;; layering.lisp — fundza "RSL - Layering (Layered Shading)" の移植
;;;
;;; 色箔をクッキーカッター (マスク) で切り抜いて順に重ねる合成の教材。
;;; layer1 = 矩形 (top/left/bottom/right, 原典 lib.h rectangle())
;;; layer2 = 円   (中心 circ-s/circ-t, 半径 radius, 原典 lib.h circle())
;;; 原典は 0/1 のハードエッジ → fuzz>0 で smoothstep AA (0.002 既定。
;;; 内部で (max fuzz 0.0005) — smoothstep(e,e,x) のゼロ割りを避ける)。
;;; 円マスクは (distance a b) を使用 = 2026-08-03 フック修正のドッグフード。
;;; 照明: 原典は Ci=Oi*surf*Kfb の無照明箔。Kfb>0 でその挙動、既定は
;;; rotatetex と同じ Ka/Kd 照明 (Kfb=1, Ka=Kd=0 で原典の図3そのもの)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の layering_params[] と一致必須):
;;;   Kfb=0 Ka=1 Kd=2 fuzz=3 top=4 left=5 bottom=6 right=7
;;;   rect-color=8 circ-s=9 circ-t=10 radius=11 circ-color=12
(setq layering-shader
(make-shader layering :keyword :surface
  (((Kfb float) 0.0)
   ((Ka float) 0.30)
   ((Kd float) 0.90)
   ((fuzz float) 0.002)
   ((top float) 0.1)
   ((left float) 0.3)
   ((bottom float) 0.8)
   ((right float) 0.7)
   ((rect-color color) (make-color 0 0 1))
   ((circ-s float) 0.5)
   ((circ-t float) 0.3)
   ((radius float) 0.25)
   ((circ-color color) (make-color 1 0.239 0)))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((ff float) 0)
          ((mr float) 0) ((mc float) 0)
          ((dd float) 0)
          ((surf color) (make-color 0 0 0))
          ((lum color) (make-color 0 0 0)))
    (setvar ff (max fuzz 0.0005))
    ;; layer 1: 矩形クッキーカッター (原典 rectangle() の 0/1 → smoothstep 積)
    (setvar mr (* (smoothstep (- left ff) (+ left ff) s)
                  (- 1 (smoothstep (- right ff) (+ right ff) s))
                  (smoothstep (- top ff) (+ top ff) t)
                  (- 1 (smoothstep (- bottom ff) (+ bottom ff) t))))
    (setvar surf (mix Cs rect-color mr))
    ;; layer 2: 円クッキーカッター (原典 circle() — distance で st 平面距離)
    (setvar dd (distance (make-point s t 0) (make-point circ-s circ-t 0)))
    (setvar mc (- 1 (smoothstep (- radius ff) (+ radius ff) dd)))
    (setvar surf (mix surf circ-color mc))
    ;; 合成: 無照明箔 (Kfb) + 通常照明 (Ka/Kd)
    (setvar lum (+ (make-color Kfb Kfb Kfb)
                   (* Ka (ambient)) (* Kd (diffuse Nf))))
    (setvar Oi Os)
    (setvar Ci (* Oi surf lum))))
)
(compile-shader layering-shader)
(append-shader layering-shader)
