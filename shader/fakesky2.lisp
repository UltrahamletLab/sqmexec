;;; fakesky2.lisp — 写実的な天空ドームシェーダー (フラクタル雲つき)
;;;
;;; シーンを囲む大球の内側に貼る。N を空方向として扱う (球の中心は原点付近に)。
;;; 構成:
;;;   - 地平 horizon-color → 天頂 zenith-color の色相グラデーション
;;;   - sundir 方向の太陽ディスク + 広いグロー (sun-color)
;;;   - turbulence (fbm) による雲: ドーム面へ遠近投影し、cloud-cover で
;;;     被覆率、cloud-sharp で縁の柔らかさを制御。密な所ほど白く、太陽側が明るい。
;;;   - 地平付近で雲をフェードアウト (smoothstep)
;;;
;;; パラメータ定義順 (shade_dr.c の fakesky2_params[] と一致必須, 最大16):
;;;   up=0 sundir=1 zenith-color=2 horizon-color=3 sun-color=4 cloud-color=5
;;;   sun-size=6 sun-glow=7 cloud-cover=8 cloud-sharp=9 cloud-scale=10
;;;   horizon-falloff=11 exposure=12 cloud-drift=13 cloud-horizon=14

(setq fakesky2-shader
(make-shader fakesky2 :keyword :surface
  (((up            point) (make-point 0 1 0))
   ((sundir        point) (make-point -0.5 0.45 -0.45))
   ((zenith-color  color) (make-color 0.16 0.33 0.72))
   ((horizon-color color) (make-color 0.80 0.86 0.95))
   ((sun-color     color) (make-color 1.00 0.95 0.80))
   ((cloud-color   color) (make-color 1.00 1.00 1.00))
   ((sun-size        float) 1200.0)
   ((sun-glow        float) 6.0)
   ((cloud-cover     float) 0.50)
   ((cloud-sharp     float) 0.20)
   ((cloud-scale     float) 1.40)
   ((horizon-falloff float) 0.45)
   ((exposure        float) 1.10)
   ((cloud-drift     float) 0.0)     ; 雲の流れ (タイムラプス用の位相)
   ((cloud-horizon   float) 0.28))   ; 雲フェード上限高度 (小さいほど雲が低空=地平近くまで広がる)
  (enter (
    ((dir point) (normalize N))
    ((sd  point) (normalize sundir))
    ((alt float) 0) ((altc float) 0) ((gfac float) 0)
    ((mu float) 0) ((sundisk float) 0) ((glow float) 0)
    ((cy float) 0) ((cx float) 0) ((cz float) 0)
    ((fbm float) 0) ((thr float) 0) ((density float) 0) ((hfade float) 0)
    ((cp  point) (make-point 0 0 0))
    ((sky color) (make-color 0 0 0))
    ((sunterm color) (make-color 0 0 0))
    ((cloudcol color) (make-color 0 0 0))
    ((col color) (make-color 0 0 0)))
  ;; --- 高度 (地平=0, 天頂=1) ---
  (setvar alt (dot up dir))
  (setvar altc (* 0.5 (+ alt (abs alt))))            ; max(0, alt)
  ;; --- 空のグラデーション ---
  (setvar gfac (pow (clamp altc 0 1) horizon-falloff))
  (setvar sky (mix horizon-color zenith-color gfac))
  ;; --- 太陽ディスク + グロー ---
  (setvar mu (clamp (dot dir sd) 0 1))
  (setvar sundisk (pow mu sun-size))
  (setvar glow (pow mu sun-glow))
  (setvar sunterm (* sun-color (+ sundisk (* 0.5 glow))))
  (setvar sky (+ sky sunterm))
  ;; --- フラクタル雲をドーム面へ遠近投影 ---
  (setvar cy (clamp altc 0.06 1))                    ; 地平でゼロ割回避 (下限0.06)
  (setvar cx (+ (/ (* (xcomp dir) cloud-scale) cy) cloud-drift))
  (setvar cz (+ (/ (* (zcomp dir) cloud-scale) cy) (* cloud-drift 0.25)))
  (setvar cp (make-point cx cz 0))
  (setvar fbm (turbulence cp 6))
  (setvar thr (- 1 cloud-cover))
  (setvar density (smoothstep thr (+ thr cloud-sharp) fbm))
  (setvar hfade (smoothstep 0.05 cloud-horizon altc)); 地平付近でフェード (上限=cloud-horizon)
  (setvar density (* density hfade))
  ;; --- 雲の色 (密な所ほど白, 太陽側ほど明るく暖色) ---
  (setvar cloudcol (mix (* cloud-color 0.55) cloud-color (smoothstep thr (+ thr 0.30) fbm)))
  (setvar cloudcol (* cloudcol (+ 0.65 (* 0.35 mu))))
  (setvar cloudcol (mix cloudcol sun-color (* 0.35 glow)))
  ;; --- 合成 ---
  (setvar col (mix sky cloudcol density))
  (setvar col (* col exposure))
  (setvar Oi Os)
  (setvar Ci (* Oi col))
)))

(compile-shader fakesky2-shader)
(append-shader fakesky2-shader)
