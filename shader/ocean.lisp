;;; ocean.lisp — リアルな海洋サーフェスシェーダー
;;;
;;; 平面メッシュに貼って水面を表現する。
;;;   - 波の法線: fBm 勾配で N を粗いうねり + 細かいさざ波に揺らす (平面のまま)
;;;   - フレネル: 見下ろし=深い水色、かすめ角=空の反射 (水らしさの核)
;;;   - 空の反射: trace で sky を映す (fakesky2 と組み合わせると雲が映る)
;;;   - 太陽グリント: 波面に鋭い specular
;;;   - 白波(foam): 既定オフ、foam-thresh を下げると波頭に出る
;;;
;;; パラメータ定義順 (shade_dr.c の ocean_params[] と一致必須, 最大16):
;;;   Ka=0 Ks=1 roughness=2 Kr=3 deep-color=4 shallow-color=5
;;;   wave-scale=6 wave-amp=7 wave-detail=8 fresnel-power=9 fresnel-bias=10
;;;   foam-thresh=11 foam-color=12 sun-glint=13 phase=14 fade-far=15
;;;
;;; 距離フェード(LOD): カメラから fade-far で波振幅/グリントを 0 に落とし、遠景の
;;;   水面を平滑な鏡面にしてエイリアシング(シマー)を抑える。near は fade-far*0.3。

(setq ocean-shader
(make-shader ocean :keyword :surface
  (((Ka float) 0.06) ((Ks float) 1.0) ((roughness float) 0.008) ((Kr float) 0.90)
   ((deep-color    color) (make-color 0.015 0.07 0.11))
   ((shallow-color color) (make-color 0.05  0.22 0.26))
   ((wave-scale    float) 0.25)
   ((wave-amp      float) 0.35)
   ((wave-detail   float) 0.50)
   ((fresnel-power float) 5.0)
   ((fresnel-bias  float) 0.02)
   ((foam-thresh   float) 1.0)
   ((foam-color    color) (make-color 0.85 0.90 0.92))
   ((sun-glint     float) 1.20)
   ((phase         float) 0.0)     ; 波のドリフト位相 (アニメーション用)
   ((fade-far      float) 55.0))   ; 距離フェード: この距離で波振幅/グリント→0
  (enter (
    ((NN point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((dir point) (make-point 0 1 0))
    ((Nw  point) (make-point 0 1 0))
    ((px float) (xcomp Pg)) ((pz float) (zcomp Pg))
    ((bx float) 0) ((bz float) 0)
    ((hx float) 0) ((hz float) 0) ((fx float) 0) ((fz float) 0)
    ((sx float) 0) ((sz float) 0)
    ((facing float) 0) ((fres float) 0) ((fn float) 0) ((foam float) 0)
    ((dist float) 0) ((fade float) 0) ((invf float) 1) ((nearf float) 0)
    ((hit float) 0)
    ((body color) (make-color 0 0 0))
    ((reflw color) (make-color 0 0 0))
    ((glint color) (make-color 0 0 0))
    ((watercol color) (make-color 0 0 0)))
  ;; --- 距離フェード(LOD): 遠景ほど波を平滑化 ---
  (setvar dist (length (- E Pg)))
  (setvar nearf (* fade-far 0.3))
  (setvar fade (smoothstep nearf fade-far dist))
  (setvar invf (- 1 fade))
  ;; --- 波の法線 (粗いうねり + 細かいさざ波の勾配で N を揺らす) ---
  (setvar bx (+ (* px wave-scale) phase)) (setvar bz (+ (* pz wave-scale) (* phase 0.6)))
  (setvar hx (- (noise (make-point (+ bx 0.5) bz 4)) (noise (make-point (- bx 0.5) bz 4))))
  (setvar hz (- (noise (make-point bx (+ bz 0.5) 4)) (noise (make-point bx (- bz 0.5) 4))))
  (setvar fx (- (noise (make-point (+ (* bx 4) 0.5) (* bz 4) 9)) (noise (make-point (- (* bx 4) 0.5) (* bz 4) 9))))
  (setvar fz (- (noise (make-point (* bx 4) (+ (* bz 4) 0.5) 9)) (noise (make-point (* bx 4) (- (* bz 4) 0.5) 9))))
  (setvar sx (+ hx (* wave-detail fx)))
  (setvar sz (+ hz (* wave-detail fz)))
  (setvar Nw (normalize (make-point (- (xcomp NN) (* wave-amp invf sx)) (ycomp NN) (- (zcomp NN) (* wave-amp invf sz)))))
  ;; --- フレネル (正面=低反射, かすめ角=高反射) ---
  (setvar facing (clamp (dot Nw Ir) 0 1))
  (setvar fres (+ fresnel-bias (* (- 1 fresnel-bias) (pow (- 1 facing) fresnel-power))))
  (setvar fres (clamp fres 0 1))
  ;; --- 水体色 (見下ろし=深い色, 浅角=明るい色) ---
  (setvar body (mix shallow-color deep-color facing))
  ;; --- 空の反射 (波の法線で反射) ---
  (setvar dir (reflect I Nw))
  (setvar reflw (* Kr (trace P dir hit)))
  ;; --- フレネルで水体と反射をブレンド ---
  (setvar watercol (mix body reflw fres))
  ;; --- 太陽グリント (波面の鋭い specular) ---
  (setvar glint (specular Nw Ir roughness))
  (setvar watercol (+ watercol (* sun-glint invf Ks glint)))
  ;; --- 白波 (既定 foam-thresh=1 でほぼ無効) ---
  (setvar fn (noise (make-point (* bx 2) (* bz 2) 13)))
  (setvar foam (smoothstep foam-thresh (+ foam-thresh 0.08) fn))
  (setvar watercol (mix watercol foam-color (* 0.7 foam)))
  ;; --- 出力 ---
  (setvar Oi Os)
  (setvar Ci (* Oi (+ watercol (* Ka body (ambient)))))
)))

(compile-shader ocean-shader)
(append-shader ocean-shader)
