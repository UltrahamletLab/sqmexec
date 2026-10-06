;;; maclaurin.lisp — fundza "RSL - The Polar Coordinate System" の移植
;;;
;;; 極座標 (R,θ) を atan2 で復元し、マクローリンの三等分曲線
;;; r(θ) = a·cos(bθ)/cos(θ) をストロークで描く。b を変えるとバラ曲線族。
;;; 原典は s,t だが SDF の s,t は不安定なのでワールド2軸 (mandelbrot と同じ
;;; axis 0=xy 壁 / 1=xz 床) + sc (縮尺) + center で写す。
;;;
;;; パラメータ定義順 (shade_dr.cpp の maclaurin_params[] と一致必須):
;;;   Ka=0 Kd=1 sc=2 a=3 b=4 stroke=5 blur=6 center-x=7 center-y=8 axis=9
;;;   curve-color=10 base-color=11
(setq maclaurin-shader
(make-shader maclaurin :keyword :surface
  (((Ka float) 0.30)
   ((Kd float) 0.85)
   ((sc float) 0.35)
   ((a float) 2.0)
   ((b float) 6.0)
   ((stroke float) 0.06)
   ((blur float) 0.8)
   ((center-x float) 0.0)
   ((center-y float) 0.0)
   ((axis float) 0.0)
   ((curve-color color) (make-color 0.90 0.15 0.10))
   ((base-color color) (make-color 0.94 0.91 0.84)))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((xd float) 0) ((yd float) 0)
          ((rad float) 0) ((th float) 0) ((rcv float) 0)
          ((blend float) 0)
          ((surf color) (make-color 0 0 0)))
    (setvar xd (/ (- (xcomp Pg) center-x) sc))
    (if (> axis 0.5)
        (setvar yd (/ (- (zcomp Pg) center-y) sc))
        (setvar yd (/ (- (ycomp Pg) center-y) sc)))
    (setvar rad (sqrt (+ (* xd xd) (* yd yd))))
    (setvar th (atan2 yd xd))
    ;; マクローリン三等分曲線 (cosθ→0 で r が発散 → ストロークは自然に消える)
    (setvar rcv (/ (* a (cos (* b th))) (cos th)))
    (setvar blend (- 1 (smoothstep stroke (* stroke (+ 1 blur)) (abs (- rad rcv)))))
    (setvar surf (mix base-color curve-color blend))
    (setvar Oi Os)
    (setvar Ci (* Oi surf (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))))
)
(compile-shader maclaurin-shader)
(append-shader maclaurin-shader)
