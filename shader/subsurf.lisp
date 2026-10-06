;;; subsurf.lisp — fundza "RSL - Fake Subsurface Effects" subsurf1 の移植
;;;
;;; 2層フェイクSSS: 表層のプラスチック照明 (Ktop) と、ノイズで法線を乱した
;;; 「皮下」照明 (Ksub) を加算する。皮下層はハイライト色 (locolor) と
;;; 皮下色 (sub-color) を別に持つので、蝋/肌のような「表面はツヤ・中は柔らかい
;;; 別色」の二重感が出る。既存 subsurface.lisp (裏面透過近似) とは別技法。
;;; 原典の P 変位 + calculatenormal は DSL に無いので、ノイズ点で法線を直接
;;; 乱す (nsub = normalize(Nf + Km*(2*pnoise-1)))。envmapping は省略 (Kenv=0 相当)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の subsurf_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 sub-ka=4 sub-kd=5 sub-ks=6 Km=7 bump-freq=8
;;;   Ktop=9 Ksub=10 hicolor=11 locolor=12 sub-color=13

(setq subsurf-shader
(make-shader subsurf :keyword :surface
  (((Ka float) 1.0)
   ((Kd float) 0.5)
   ((Ks float) 0.7)
   ((roughness float) 0.1)
   ((sub-ka float) 1.0)
   ((sub-kd float) 0.5)
   ((sub-ks float) 0.7)
   ((Km float) 0.6)
   ((bump-freq float) 9.0)
   ((Ktop float) 0.5)
   ((Ksub float) 0.5)
   ((hicolor color) (make-color 1 1 1))
   ((locolor color) (make-color 1 1 1))
   ((sub-color color) (make-color 1 1 1)))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((pp point) (make-point 0 0 0))
    ((nx float) 0) ((ny float) 0) ((nz float) 0)
    ((perturb point) (make-point 0 0 0))
    ((nsub point) (make-point 0 0 0))
    ((topcol color) (make-color 0 0 0))
    ((subcol color) (make-color 0 0 0)))
    ;; 表層: 通常のプラスチック照明
    (setvar topcol (* Ktop (+ (* Ka (ambient)) (* Kd (diffuse Nf))
                              (* hicolor Ks (specular Nf Ir roughness)))))
    ;; 皮下層: ノイズで乱した「偽の法線」で照明をもう一周
    ;; (pnoisep はフック未実装 — スカラー noise 3回のオフセット違いで代用)
    (setvar pp (* bump-freq Pg))
    (setvar nx (noise pp))
    (setvar ny (noise (+ pp (make-point 71.7 13.3 5.9))))
    (setvar nz (noise (+ pp (make-point 27.1 91.3 47.7))))
    (setvar perturb (make-point (- (* 2 nx) 1) (- (* 2 ny) 1) (- (* 2 nz) 1)))
    (setvar nsub (normalize (+ Nf (* Km perturb))))
    (setvar subcol (* Ksub sub-color
                      (+ (* sub-ka (ambient)) (* sub-kd (diffuse nsub))
                         (* locolor sub-ks (specular nsub Ir roughness)))))
    (setvar Oi Os)
    (setvar Ci (* Oi Cs (+ topcol subcol))))))
(compile-shader subsurf-shader)
(append-shader subsurf-shader)
