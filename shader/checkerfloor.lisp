;;; checkerfloor — ワールド座標 (Pg) の市松。無限床 (SDF plane) 用。
;;;
;;; 標準の checker は s,t (UV) で市松を作るので、**UV を持たない SDF plane や
;;; blob には模様が出ない** (2026-08-18 に実際に無地の床が焼けた)。
;;; こちらは Pg の x,z で市松にするので、UV の無いジオメトリでも出る。
;;;
;;; tile-size = 1マスのワールド単位 (Blender の Checker scale と対応させるなら
;;;             plane サイズ / scale / 2)。y は使わないので床専用。
;;; specular を持たせてあるのは、Cycles の Principled (roughness 低め) と
;;; 見え方を揃えるため。

(setq checkerfloor-shader

(make-shader checkerfloor :keyword :surface
      (((Ka          float) 0.2)
       ((Kd          float) 0.8)
       ((Ks          float) 0.15)
       ((roughness   float) 0.25)
       ((tile-size   float) 2.4)
       ((black-color color) (make-color 0.05 0.05 0.06)))

  (enter (((P2 point) (make-point 0 0 0))
          ((xm float) 0.0)
          ((zm float) 0.0)
          ((Nf point) (make-point 0 1 0)))

    (setvar P2 (/ (transform "world" Pg) tile-size))
    (setvar xm (- (xcomp P2) (floor (xcomp P2))))    ; frac (mod は負で壊れる)
    (setvar zm (- (zcomp P2) (floor (zcomp P2))))

    (if (< xm 0.5)
        (if (< zm 0.5) (setvar Ci Cs) (setvar Ci black-color))
        (if (< zm 0.5) (setvar Ci black-color) (setvar Ci Cs)))

    (setvar Nf (faceforward (normalize N) I))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* Ci (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* Ks (specular Nf (normalize (- I)) roughness)))))
)))

(compile-shader checkerfloor-shader)
(append-shader checkerfloor-shader)
