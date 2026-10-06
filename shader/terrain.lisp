;;; terrain.lisp — リアルな大地 (地形) サーフェスシェーダー
;;;
;;; 平面メッシュに貼って、procedural な地表を表現する。
;;; 改善ポイント (素のフラクタルノイズより自然に見せる):
;;;   - ドメインワーピング: ノイズ座標を別ノイズで歪め、有機的なパターンに
;;;   - 高度(fBm)による多素材ブレンド: 草 → 土 → 岩 を smoothstep で混合
;;;   - 法線バンプ: ノイズ勾配で法線を傾け、平面のまま凹凸の陰影を出す
;;;   - マクロ色ムラ + 微細グレイン: 均質さを排除
;;;   - 距離フェード(LOD): カメラから遠いほど高周波(fBm高オクターブ/微細グレイン/
;;;     法線バンプ)を減衰させ、遠景のエイリアシング(シマー)を抑える
;;;
;;; パラメータ定義順 (shade_dr.c の terrain_params[] と一致必須, 最大16):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 Cgrass=4 Cdirt=5 Crock=6
;;;   feat-scale=7 warp=8 bump=9 rock-thresh=10 grass-thresh=11
;;;   macro-scale=12 detail=13 fade-near=14 fade-far=15

(setq terrain-shader
(make-shader terrain :keyword :surface
  (((Ka float) 0.30) ((Kd float) 0.85) ((Ks float) 0.05) ((roughness float) 0.40)
   ((Cgrass color) (make-color 0.26 0.40 0.17))
   ((Cdirt  color) (make-color 0.40 0.30 0.18))
   ((Crock  color) (make-color 0.42 0.42 0.40))
   ((feat-scale   float) 0.15)
   ((warp         float) 0.70)
   ((bump         float) 1.40)
   ((rock-thresh  float) 0.60)
   ((grass-thresh float) 0.42)
   ((macro-scale  float) 0.03)
   ((detail       float) 0.35)
   ((fade-near    float) 8.0)
   ((fade-far     float) 26.0))
  (enter (
    ((NN point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((px float) (xcomp Pg)) ((pz float) (zcomp Pg))
    ((bs float) (* feat-scale 5))
    ((w1 float) 0) ((w2 float) 0) ((wpx float) 0) ((wpz float) 0)
    ((h float) 0) ((h6 float) 0) ((h3 float) 0) ((g2d float) 0) ((d2r float) 0)
    ((dist float) 0) ((fade float) 0) ((invf float) 1)
    ((deff float) 0) ((beff float) 0)
    ((mac float) 0) ((fg float) 0)
    ((bx float) 0) ((bz float) 0) ((hx float) 0) ((hz float) 0)
    ((Nb point) (make-point 0 1 0))
    ((base color) (make-color 0 0 0)))
  ;; --- ドメインワーピング: 座標を 2 つの noise で歪める ---
  (setvar w1 (noise (make-point (* px feat-scale) (* pz feat-scale) 0)))
  (setvar w2 (noise (make-point (+ (* px feat-scale) 5.2) (+ (* pz feat-scale) 1.3) 0)))
  (setvar wpx (+ (* px feat-scale) (* warp (- (* 2 w1) 1))))
  (setvar wpz (+ (* pz feat-scale) (* warp (- (* 2 w2) 1))))
  ;; --- 距離フェード(LOD): 近=0(full detail) 遠=1(detail減衰) ---
  (setvar dist (length (- E Pg)))
  (setvar fade (smoothstep fade-near fade-far dist))
  (setvar invf (- 1 fade))
  ;; --- fBm 高度場 (遠景は低オクターブへ補間して素材境界のちらつきを抑制) ---
  (setvar h6 (turbulence (make-point wpx wpz 0) 6))
  (setvar h3 (turbulence (make-point wpx wpz 0) 3))
  (setvar h (+ h6 (* fade (- h3 h6))))
  ;; --- 高度で素材ブレンド (草 → 土 → 岩) ---
  (setvar g2d (smoothstep grass-thresh (+ grass-thresh 0.18) h))
  (setvar d2r (smoothstep rock-thresh  (+ rock-thresh  0.15) h))
  (setvar base (mix Cgrass Cdirt g2d))
  (setvar base (mix base Crock d2r))
  ;; --- マクロ色ムラ (大スケールの日向/日陰) ---
  (setvar mac (noise (make-point (* px macro-scale) (* pz macro-scale) 11)))
  (setvar base (* base (+ 0.78 (* 0.44 mac))))
  ;; --- 微細グレイン (遠景で減衰) ---
  (setvar deff (* detail invf))
  (setvar fg (noise (make-point (* px feat-scale 6) (* pz feat-scale 6) 3)))
  (setvar base (* base (+ (- 1 (* 0.5 deff)) (* deff fg))))
  ;; --- 法線バンプ (ノイズ勾配で N を傾ける; 遠景で減衰してシマーを抑える) ---
  (setvar beff (* bump invf))
  (setvar bx (* px bs)) (setvar bz (* pz bs))
  (setvar hx (- (noise (make-point (+ bx 0.6) bz 7)) (noise (make-point (- bx 0.6) bz 7))))
  (setvar hz (- (noise (make-point bx (+ bz 0.6) 7)) (noise (make-point bx (- bz 0.6) 7))))
  (setvar Nb (normalize (make-point (- (xcomp NN) (* beff hx)) (ycomp NN) (- (zcomp NN) (* beff hz)))))
  ;; --- シェーディング ---
  (setvar Oi Os)
  (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nb))))
                      (* Ks (specular Nb Ir roughness)))))
)))

(compile-shader terrain-shader)
(append-shader terrain-shader)
