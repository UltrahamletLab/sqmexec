;;; envmapocc.lisp — envmap (1993) の遮蔽対応版 (2026-08-15)
;;;
;;; envmap は environment を法線方向で引くだけで可視性テストを持たないため、
;;; 彫った空洞の奥でも外面と同じ明るさになる (スカルプト cube で露呈)。
;;; ここでは 2026-08-03 追加の (occlusion P axis samples coneangle maxdist)
;;; フックで半球遮蔽率を測り、環境項と ambient 項を (1-occ)^power で絞る。
;;; specular は直接光なので -s の影に任せて触らない。
;;; native ks 反射 (エンジン側の実レイ) はもともと遮蔽が正しいので対象外。
;;;
;;; パラメータ定義順 (shade_dr.cpp の envmapocc_params[] と一致必須):
;;;   Ka=0 Ks=1 roughness=2 intensity=3 angle=4 map-name=5
;;;   occ-samples=6 occ-cone=7 occ-maxdist=8 occ-power=9
(setq envmapocc-shader

(make-shader envmapocc :keyword :surface
      (
	((Ka float) 1)
        ((Ks float) 1)
        ((roughness float) 0.02)
        ((intensity float) 0.5)
        ((angle float) 0.0)
        ((map-name string) "")
        ((occ-samples float) 24)
        ((occ-cone float) 90)
        ((occ-maxdist float) 2.5)
        ((occ-power float) 1.0)
       )
  (enter ((temp point)
	  ((direction point) (normalize N))
	  ((Nf point) (faceforward (normalize N) I))
	  ((NI point) (normalize I))
	  ((rad float) (radians angle))
	  ((occ float) 0)
	  ((vis float) 1)
	  ((ev color) (make-color 0 0 0)))
    ;; rotate direction for u-angle
    (setvar temp direction)
    (setxcomp direction (- (* (xcomp temp) (cos rad))
			   (* (zcomp temp) (sin rad))))
    (setzcomp direction (+ (* (xcomp temp) (sin rad))
			   (* (zcomp temp) (cos rad))))
    ;; Do environment mapping
    (if (string/= map-name "")
	(setvar ev (environment map-name direction))
        (setvar ev 0))
    ;; hemispheric occlusion → environment visibility
    (setvar occ (occlusion P Nf occ-samples (radians occ-cone) occ-maxdist))
    (setvar vis (pow (- 1 occ) occ-power))
    (setvar Oi Os)
    (setvar Ci (* Os Cs (+ (* Ka (ambient) vis)
			   (* Ks (+ (* ev intensity vis)
			            (specular Nf (- NI) roughness))))))
)))

(compile-shader envmapocc-shader)
(append-shader envmapocc-shader)
