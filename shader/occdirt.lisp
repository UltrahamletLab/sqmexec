;;; occdirt.lisp — occlusion() の活用例: 窪み汚れマスク (crevice dirt)
;;;
;;; 遮蔽率をそのまま「汚れの溜まりやすさ」として使い、
;;;   surf = mix(clean-color, dirt-color, clamp(gain*occ))
;;; を通常の Ka/Kd 照明に載せる。溝・接地際・入り隅にだけ煤/錆/苔が乗る。
;;; -O (全景AO) では書けない per-material の使い方 = occlusion() フックの本命。
;;; maxdist は「汚れの届く深さ」: 小さいほど狭い溝だけが汚れる。
;;;
;;; mask = smoothstep(dirt-lo, dirt-hi, gain*occ) — 下限 dirt-lo が
;;; サンプリングノイズ床 (occ 数%の斑) を汚れに拾わない要 (gain 直乗せは
;;; 開けた面までスペックルになる。実測で踏んだ)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の occdirt_params[] と一致必須):
;;;   Ka=0 Kd=1 samples=2 maxdist=3 gain=4 clean-color=5 dirt-color=6
;;;   dirt-lo=7 dirt-hi=8
(setq occdirt-shader
(make-shader occdirt :keyword :surface
  (((Ka float) 0.30)
   ((Kd float) 0.90)
   ((samples float) 32)
   ((maxdist float) 0.8)
   ((gain float) 1.6)
   ((clean-color color) (make-color 0.75 0.78 0.82))
   ((dirt-color color) (make-color 0.30 0.20 0.12))
   ((dirt-lo float) 0.12)
   ((dirt-hi float) 0.65))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Po point) P)
          ((occ float) 0)
          ((mask float) 0)
          ((surf color) (make-color 0 0 0)))
    ;; 原点持ち上げ: 水平近くのサンプルレイが緩曲面 (トーラス冠部等) の
    ;; すれすれを走って自己ヒットするスペックル対策 (dirocclude と同じ処方)
    (setvar Po (+ P (* 0.015 Nf)))
    (setvar occ (occlusion Po Nf samples (radians 90) maxdist))
    (setvar mask (smoothstep dirt-lo dirt-hi (* gain occ)))
    (setvar surf (mix clean-color dirt-color mask))
    (setvar Oi Os)
    (setvar Ci (* Oi surf (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))))
)
(compile-shader occdirt-shader)
(append-shader occdirt-shader)
