;;; selocclude.lisp — fundza "Selective Occlusion" (rt_occlusion) の移植
;;;
;;; 原典: _occlusion = 1 - occlusion(P, n, samples, "coneangle", .., "subset", subset)
;;;       で「指定した trace set のオブジェクトだけが遮蔽する」AO。
;;; sqm では (occlusion-set P axis samples coneangle maxdist subset) が対応
;;; (2026-08-03 追加)。scene 側は surface ブロックの (trace-set <name>) で所属を
;;; 宣言する。subset はカンマ区切りで複数可 ("fixed,floor")。
;;; 原典の bake3d/brickmap 部は移植しない (sqm の点群の受け皿は blob-bulk 点描)。
;;; ※blob を遮蔽物として選別するには支配 ball に (shader ..) が要る
;;;   (surf_ptr 経由の識別。mesh/SDF は無条件)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の selocclude_params[] と一致必須):
;;;   samples=0 coneangle=1 multiplier=2 maxdist=3 subset=4
(setq selocclude-shader
(make-shader selocclude :keyword :surface
  (((samples float) 64)
   ((coneangle float) 80)
   ((multiplier float) 1)
   ((maxdist float) 2.0)
   ((subset string) ""))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((occ float) 0))
    (setvar occ (occlusion-set P Nf samples (radians coneangle) maxdist subset))
    (setvar occ (pow (- 1 occ) multiplier))
    (setvar Oi Os)
    (setvar Ci (* Oi Cs occ))))
)
(compile-shader selocclude-shader)
(append-shader selocclude-shader)
