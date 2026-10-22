;;; celldots.lisp — fundza "RSL - Cellnoise" cell_test の移植
;;;
;;; 3D セル格子の中心からの距離で水玉を描く。原典の dist2cell は 27 セル走査
;;; だが、ジッタ無し (cellnoise がコメントアウト) なら最近接中心は常に自セル
;;; なので frac(pp)-0.5 の距離だけで同値 — ループ不要で DSL に載る。
;;; 原典は Oi=0 の切り抜きだが、sqm の Oi<0.05 は「穴」でなく背景色の塗りに
;;; なる (filament の教訓) ので、水玉を2トーンの色模様として描く。
;;; セルごとの色ムラは vnoise(セル中心) でハッシュ代用。
;;;
;;; パラメータ定義順 (shade_dr.cpp の celldots_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 freq=4 dot-radius=5 blur=6
;;;   base-color=7 dot-color=8 dot-color2=9

(setq celldots-shader
(make-shader celldots :keyword :surface
  (((Ka float) 0.2)
   ((Kd float) 0.8)
   ((Ks float) 0.4)
   ((roughness float) 0.1)
   ((freq float) 6.0)
   ((dot-radius float) 0.32)
   ((blur float) 0.06)
   ((base-color color) (make-color 0.92 0.88 0.80))
   ((dot-color  color) (make-color 0.75 0.15 0.12))
   ((dot-color2 color) (make-color 0.15 0.30 0.65)))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((pp point) (make-point 0 0 0))
    ((cellc point) (make-point 0 0 0))
    ((dd float) 0) ((dsel float) 0)
    ((tint color) (make-color 0 0 0))
    ((surf color) (make-color 0 0 0)))
    (setvar pp (* freq Pg))
    (setvar cellc (make-point (+ (floor (xcomp pp)) 0.5)
                              (+ (floor (ycomp pp)) 0.5)
                              (+ (floor (zcomp pp)) 0.5)))
    (setvar dd (length (- pp cellc)))
    (setvar dsel (- 1 (smoothstep (- dot-radius blur) dot-radius dd)))
    (setvar tint (mix dot-color dot-color2 (vnoise cellc)))
    (setvar surf (mix base-color tint dsel))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* surf (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* Ks (specular Nf Ir roughness))))))))
(compile-shader celldots-shader)
(append-shader celldots-shader)
