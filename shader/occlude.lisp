;;; occlude.lisp — fundza "RSL - Ambient Occlusion" (occlude1) の移植
;;;
;;; 原典: gather("illuminance", P, nf, PI/2, samples) でヒット数を数え
;;;       Ci = (1 - hits/samples) * Cs の純AO表示。
;;; sqm では 2026-08-03 追加の (occlusion P axis samples coneangle maxdist)
;;; フックで直訳できる (黄金角スパイラルの決定論サンプル・遮蔽率を返す)。
;;; multiplier は姉妹編 (Directional Occlusion) の pow 締めを表示にも使えるよう追加。
;;; maxdist: RSL は無限だが sqm はレイ長上限が要る (シーンスケール比で調整)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の occlude_params[] と一致必須):
;;;   samples=0 coneangle=1 multiplier=2 maxdist=3
(setq occlude-shader
(make-shader occlude :keyword :surface
  (((samples float) 32)
   ((coneangle float) 90)
   ((multiplier float) 1)
   ((maxdist float) 2.0))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((occ float) 0))
    (setvar occ (occlusion P Nf samples (radians coneangle) maxdist))
    (setvar occ (pow (- 1 occ) multiplier))
    (setvar Oi Os)
    (setvar Ci (* Oi Cs occ))))
)
(compile-shader occlude-shader)
(append-shader occlude-shader)
