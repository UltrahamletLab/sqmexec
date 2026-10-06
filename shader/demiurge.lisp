;;; demiurge.lisp — 手続き惑星の地表シェーダー
;;;
;;; https://github.com/owenyuwono/demiurge の惑星を sqm で描くためのもの。
;;;
;;; blob-bulk は **per-blob 属性を持てない**ので、バイオーム色は blob に載せられない。
;;; 代わりに tools/gen_demiurge_planet.py が equirect の
;;;   biome-map : RGB = バイオーム色 (プレート→隆起→侵食→気候 の帰結)
;;;   ocean-map : R=水マスク G=雪マスク B=傾斜
;;; を焼き、ここで **惑星中心から見た方向** で引く (poseidon の泡タイルと同じ手口)。
;;; sqm の texture() は最近傍なので 4タップの bilinear を自前で書く。
;;;
;;; シェーディング:
;;;   ・拡散 = バイオーム色 x diffuse (影は使わない — 球の自己遮蔽は法線で足りる)
;;;   ・海 = 水マスクの所だけ鏡面反射を足す (太陽のグリント)
;;;   ・雪 = 弱い鏡面
;;;   ・明暗境界 (terminator) = dot(N,L) を smoothstep で柔らかく落とし、
;;;     夜側は空の色だけ残す (大気の散乱の代わり)
;;;
;;; パラメータ定義順 = shade_dr.cpp の demiurge_params[] と一致必須:
;;;   Ka=0 Kd=1 Ks=2 roughness=3 biome-map=4 ocean-map=5 map-w=6 map-h=7
;;;   planet-r=8 sea-spec=9 snow-spec=10 sky-color=11 ambient-amt=12 terminator=13

(setq demiurge-shader
(make-shader demiurge :keyword :surface
  (((Ka float) 0.0) ((Kd float) 1.0) ((Ks float) 1.0)
   ((roughness float) 0.035)
   ((biome-map string) "")
   ((ocean-map string) "")
   ((map-w float) 2048.0) ((map-h float) 1024.0)
   ((planet-r float) 500000.0)
   ((sea-spec  float) 0.55)
   ((snow-spec float) 0.20)
   ((sky-color color) (make-color 0.055 0.085 0.150))
   ((ambient-amt float) 0.16)
   ((terminator  float) 0.055))
  (enter (
    ((Nf   point) (faceforward (normalize N) I))
    ((vd   point) (normalize (- I)))
    ((rd   point) (make-point 0 1 0))
    ((uu float) 0) ((vv float) 0)
    ((au float) 0) ((av float) 0) ((fu float) 0) ((fv float) 0)
    ((u0 float) 0) ((u1 float) 0) ((v0 float) 0) ((v1 float) 0)
    ((wat float) 0) ((snw float) 0) ((day float) 0) ((gl float) 0)
    ((c00 color) (make-color 0 0 0)) ((c10 color) (make-color 0 0 0))
    ((c01 color) (make-color 0 0 0)) ((c11 color) (make-color 0 0 0))
    ((alb color) (make-color 0.5 0.5 0.5))
    ((aux color) (make-color 0 0 0))
    ((lit color) (make-color 0 0 0)))

  ;; --- 惑星中心から見た方向 → equirect UV --------------------------------
  ;;     惑星は原点に置く約束 (generator がそう書く)。半径で割る必要は無く、
  ;;     方向さえ合っていればよい。
  (setvar rd (normalize Pg))
  ;; ⚠ DSL の atan は **1引数**。2引数版は atan2 (interface/shader.lisp の stf 末尾追加)
  (setvar uu (+ 0.5 (/ (atan2 (xcomp rd) (zcomp rd)) (* 2 pi))))
  (setvar vv (+ 0.5 (/ (asin (clamp (ycomp rd) -1 1)) pi)))

  ;; --- bilinear (sqm の texture() は最近傍) -------------------------------
  (setvar au (- (* uu map-w) 0.5)) (setvar av (- (* vv map-h) 0.5))
  (setvar fu (- au (floor au)))    (setvar fv (- av (floor av)))
  (setvar u0 (/ (+ (floor au) 0.5) map-w)) (setvar u1 (+ u0 (/ 1 map-w)))
  (setvar v0 (/ (+ (floor av) 0.5) map-h)) (setvar v1 (+ v0 (/ 1 map-h)))
  (setvar c00 (texture biome-map u0 v0)) (setvar c10 (texture biome-map u1 v0))
  (setvar c01 (texture biome-map u0 v1)) (setvar c11 (texture biome-map u1 v1))
  (setvar alb (mix (mix c00 c10 fu) (mix c01 c11 fu) fv))

  ;; 補助マップ (R=水 G=雪 B=傾斜) は最近傍で足りる
  (setvar aux (texture ocean-map uu vv))
  (setvar wat (comp aux 0))
  (setvar snw (comp aux 1))

  ;; --- 昼夜と明暗境界 ------------------------------------------------------
  ;;     dot(N,L) をそのまま使うと境界が硬いので smoothstep で薄い大気ぶん柔らげる。
  (setvar lit (* Kd alb (diffuse Nf)))

  ;; --- 海のグリントと雪の照り ---------------------------------------------
  (setvar gl (+ (* sea-spec wat) (* snow-spec snw)))
  (setvar lit (+ lit (* Ks gl (specular Nf vd roughness))))

  ;; --- 空由来の環境光 (夜側が真っ黒にならない程度に) ----------------------
  (setvar day (smoothstep (- terminator) terminator (dot Nf (normalize (- I)))))
  (setvar lit (+ lit (* alb sky-color ambient-amt)))

  (setvar Oi Os)
  (setvar Ci (* Oi (+ lit (* Ka alb (ambient)))))
)))

(compile-shader demiurge-shader)
(append-shader demiurge-shader)
