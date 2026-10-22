;;; lava.lisp — 溶岩 / マグマ (冷えた黒い地殻 + 細く光る亀裂)
;;;
;;; メタボールに乗せると溶けた塊。狙いは「大半が冷えた暗い地殻、その隙間を細い
;;; 発光亀裂(vein)が走る」溶岩岩。閾値で面を二分すると明暗が反転しやすいので、
;;; ノイズ場 f の等高線(f≈0.5)に沿った細いリッジを亀裂として光らせる。
;;;   - vein: 1 - |2f-1| を sharp 倍してクランプ → f≈0.5 の細い帯だけ 1
;;;   - 熱ランプ: vein 中心ほど hot-color → glow-color (オレンジ→黄白)
;;;   - emit: vein を自己発光で加算 (ライト非依存)
;;;   - 地殻: vein 以外の暗い岩。法線バンプで凹凸の陰影
;;;   - flow: ノイズ座標をずらしてマグマの流れをアニメ化
;;;
;;; パラメータ定義順 (shade_dr.c の lava_params[] と一致必須, 最大16):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 crust-color=4 hot-color=5 glow-color=6
;;;   feat-scale=7 vein-sharp=8 vein-soft=9 glow=10 flow=11 bump=12

(setq lava-shader
(make-shader lava :keyword :surface
  (((Ka float) 0.12) ((Kd float) 0.50) ((Ks float) 0.18) ((roughness float) 0.20)
   ((crust-color color) (make-color 0.05 0.04 0.04))   ; 冷えた地殻 (ほぼ黒)
   ((hot-color   color) (make-color 1.10 0.32 0.04))   ; 亀裂のオレンジ
   ((glow-color  color) (make-color 1.60 1.35 0.45))   ; 亀裂中心の黄白
   ((feat-scale  float) 0.9)
   ((vein-sharp  float) 5.0)    ; 大=亀裂が細い
   ((vein-soft   float) 1.4)    ; 亀裂の縁の落ち方 (pow指数)
   ((glow        float) 2.0)    ; 発光強度
   ((flow        float) 0.0)    ; マグマ流れの位相 (アニメ用)
   ((bump        float) 0.8))   ; 地殻バンプ量
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((pp point) (make-point 0 0 0))
    ((f float) 0) ((vein float) 0) ((hx float) 0) ((hz float) 0)
    ((bx float) 0) ((bz float) 0)
    ((Nb point) (make-point 0 1 0))
    ((heat color) (make-color 0 0 0))
    ((emit color) (make-color 0 0 0))
    ((crust color) (make-color 0 0 0)))
  ;; --- 流れる多オクターブ場 (0..1) ---
  (setvar pp (+ (* feat-scale Pg) (make-point flow (* flow 0.3) (* flow 0.7))))
  (setvar f (+ (* 0.6 (noise pp)) (* 0.3 (noise (* 2 pp))) (* 0.1 (noise (* 4 pp)))))
  ;; --- 細い発光亀裂: f≈0.5 の等高線に沿った細帯 ---
  (setvar vein (- 1 (clamp (* vein-sharp (abs (- (* 2 f) 1))) 0 1)))
  (setvar vein (pow vein vein-soft))
  ;; --- 熱ランプ + 発光 (中心ほど明るい) ---
  (setvar heat (mix hot-color glow-color vein))
  (setvar emit (* glow vein heat))
  ;; --- 地殻バンプ (ノイズ勾配で N を傾ける) ---
  (setvar bx (* feat-scale (xcomp Pg) 2)) (setvar bz (* feat-scale (zcomp Pg) 2))
  (setvar hx (- (noise (make-point (+ bx 0.5) bz 21)) (noise (make-point (- bx 0.5) bz 21))))
  (setvar hz (- (noise (make-point bx (+ bz 0.5) 21)) (noise (make-point bx (- bz 0.5) 21))))
  (setvar Nb (normalize (make-point (- (xcomp Nf) (* bump hx)) (ycomp Nf) (- (zcomp Nf) (* bump hz)))))
  ;; --- 冷えた地殻 (亀裂部は地殻を暗く落とす) ---
  (setvar crust (* crust-color (- 1 (* 0.85 vein)) (+ (* Ka (ambient)) (* Kd (diffuse Nb)))))
  ;; --- 合成: 地殻 + 発光 + 弱いスペキュラ ---
  (setvar Oi Os)
  (setvar Ci (* Oi (+ crust emit (* Ks (specular Nb Ir roughness))))))))

(compile-shader lava-shader)
(append-shader lava-shader)
