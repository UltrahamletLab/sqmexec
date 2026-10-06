;;; causticsproj.lisp — 疑似コースティクスを「上から投影」する版 (2026-08-10)
;;;
;;; caustics.lisp は床用で、パターンを `scale * Pg` の **3Dノイズ**から引く。床は
;;; y がほぼ一定なので問題にならないが、**立った物体 (カッパの体) に貼ると y 方向にも
;;; 模様が変化して大理石のようになり、「水面から降ってきた光の網」に見えない**。
;;;
;;; そこでこの版は原理を2点だけ変える:
;;;   ① **平面投影**: サンプル点の y を捨てて (Pg.x, proj-y, Pg.z) で引く
;;;      → パターンが鉛直方向に押し出された「光のカーテン」になり、上から落ちた網が
;;;        体に掛かって見える。床の caustics と同じ scale/phase を渡せば **床の網と
;;;        体の網が同じ模様として繋がる**。
;;;   ② **N·up ゲート**: 上を向いた面ほど強く、横を向いた面では消す (up-gate は指数)。
;;;      実際の水中でも光網は上向き面に乗るので、これが無いと体の側面や裏にまで
;;;      模様が回り込んで貼り絵に見える。
;;;
;;; 網が (diffuse Nf) に乗るのは原典と同じ = **影の中では網も消える**。
;;;
;;; パラメータ定義順 (shade_dr.cpp の causticsproj_params[] と一致必須, 最大16):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 caustic-color=4 scale=5 intensity=6
;;;   sharpness=7 focus=8 warp=9 dispersion=10 phase=11 fade-far=12
;;;   up-gate=13 proj-y=14

(setq causticsproj-shader
(make-shader causticsproj :keyword :surface
  (((Ka float) 0.20) ((Kd float) 0.60) ((Ks float) 0.10) ((roughness float) 0.15)
   ((caustic-color color) (make-color 0.85 1.00 1.05))  ; 光網の色
   ((scale      float) 1.70)   ; 模様の細かさ (床の caustics と揃えると繋がる)
   ((intensity  float) 1.20)   ; 光網の明るさ
   ((sharpness  float) 5.00)   ; 大=リッジ帯が細い
   ((focus      float) 1.90)   ; pow指数: 大=網が細く先鋭
   ((warp       float) 0.80)   ; ドメインワープ量
   ((dispersion float) 0.030)  ; RGBずらし量 (色収差フリンジ)
   ((phase      float) 0.0)    ; 水流の位相 (床と同じ値を渡すこと)
   ((fade-far   float) 45.0)   ; 距離LOD
   ((up-gate    float) 1.60)   ; 上向き面ゲートの指数 (大=真上向きだけ)
   ((proj-y     float) 0.0))   ; 投影平面の y (床の高さに合わせると位相が揃う)
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Nn point) (normalize N))
    ((Ir point) (normalize (- I)))
    ((pp point) (make-point 0 0 0))
    ((pw point) (make-point 0 0 0))
    ((pa point) (make-point 0 0 0))
    ((pb point) (make-point 0 0 0))
    ((pd point) (make-point 0 0 0))
    ((wx float) 0) ((wz float) 0)
    ((fa float) 0) ((fb float) 0) ((ra float) 0) ((rb float) 0)
    ((fa2 float) 0) ((fb2 float) 0) ((ra2 float) 0) ((rb2 float) 0)
    ((caus float) 0) ((caus2 float) 0) ((cg float) 0)
    ((nup float) 0) ((gate float) 0)
    ((dist float) 0) ((fade float) 0) ((invf float) 1)
    ((ld color) (make-color 0 0 0))
    ((basec color) (make-color 0 0 0))
    ((cterm color) (make-color 0 0 0)))
  ;; --- 距離フェード(LOD) ---
  (setvar dist (length (- E Pg)))
  (setvar fade (smoothstep (* fade-far 0.3) fade-far dist))
  (setvar invf (- 1 fade))
  ;; --- ① 平面投影: y を捨てて xz だけでパターンを引く ---
  (setvar pp (* scale (make-point (xcomp Pg) proj-y (zcomp Pg))))
  ;; --- ドメインワープ (水面ゆらぎの歪み, phase で漂う) ---
  (setvar wx (noise (+ (* 0.4 pp) (make-point (+ 11.3 (* phase 0.31)) 7.7 5.1))))
  (setvar wz (noise (+ (* 0.4 pp) (make-point 3.1 9.4 (+ 17.0 (* phase 0.23))))))
  (setvar pw (+ pp (* warp (make-point (- (* 2 wx) 1) 0 (- (* 2 wz) 1)))))
  ;; --- 2層リッジノイズ: 逆方向ドリフトの積 = 明滅する網目 ---
  (setvar pa (+ pw (make-point (* phase 0.70) 0 (* phase 0.45))))
  (setvar pb (+ (* 1.9 pw) (make-point (- 5.2 (* phase 0.55)) 0 (+ 8.7 (* phase 0.80)))))
  (setvar fa (+ (* 0.65 (noise pa)) (* 0.35 (noise (* 2.3 pa)))))
  (setvar fb (+ (* 0.65 (noise pb)) (* 0.35 (noise (* 2.3 pb)))))
  (setvar ra (- 1 (clamp (* sharpness (abs (- (* 2 fa) 1))) 0 1)))
  (setvar rb (- 1 (clamp (* sharpness (abs (- (* 2 fb) 1))) 0 1)))
  (setvar caus (pow (clamp (* 1.3 ra rb) 0 1) focus))
  ;; --- 色収差 ---
  (setvar pd (make-point dispersion 0 (* dispersion 0.6)))
  (setvar fa2 (+ (* 0.65 (noise (+ pa pd))) (* 0.35 (noise (* 2.3 (+ pa pd))))))
  (setvar fb2 (+ (* 0.65 (noise (+ pb pd))) (* 0.35 (noise (* 2.3 (+ pb pd))))))
  (setvar ra2 (- 1 (clamp (* sharpness (abs (- (* 2 fa2) 1))) 0 1)))
  (setvar rb2 (- 1 (clamp (* sharpness (abs (- (* 2 fb2) 1))) 0 1)))
  (setvar caus2 (pow (clamp (* 1.6 ra2 rb2) 0 1) focus))
  (setvar cg (* 0.5 (+ caus caus2)))
  ;; --- ② 上向き面ゲート (幾何法線の y。faceforward 済みの Nf だと裏面で反転する) ---
  (setvar nup (clamp (ycomp Nn) 0 1))
  (setvar gate (pow nup up-gate))
  ;; --- 合成: 通常の plastic 相当 + 投影された光網 ---
  (setvar ld (diffuse Nf))
  (setvar basec (* Cs (+ (* Ka (ambient)) (* Kd ld))))
  (setvar cterm (* intensity invf gate caustic-color (make-color caus cg caus2) ld))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ basec cterm (* Ks (specular Nf Ir roughness))))))))

(compile-shader causticsproj-shader)
(append-shader causticsproj-shader)
