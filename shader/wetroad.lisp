;;; wetroad.lisp — 雨上がりの濡れたアスファルト
;;;
;;; エンジンの `-R` (Schlick) + native 反射は **加算** なので、掠め角で F→1 になると
;;; 暗いアスファルトの拡散成分が完全に埋もれ、路面が完全な鏡 = 「冠水した運河」に
;;; 見える (車載視点の低い目線では路面のほぼ全域が掠め角になり露呈した)。
;;; ここでは **mix で合成** する — F は「反射がどれだけ占めるか」であって
;;; 「どれだけ足すか」ではない。エネルギー的にも素直で、白飛びしない。
;;;
;;; 揺らぎは高さ場の勾配で法線を傾ける (ripples と同じ手口) を2スケール:
;;;   うねり … 進行方向に伸ばした低周波。反射が縦に長く滲む = 濡れた道路の見え方
;;;   さざなみ … 中周波の細かい乱れ。鏡像の輪郭を崩す
;;; どちらも **濡れている所だけ**効かせる (wetness マスク) ので、乾いた部分は
;;; ざらついたアスファルトのまま残り、水たまりとの差が出る。
;;;
;;; ⚠ 自前 trace なので **シーン側の ks は 0 にする** (同じ面の native 反射と
;;;   二重加算になって白飛びする。ripples/seascape と同じ注意)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の wetroad_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 Kr=4 road-color=5 grain=6
;;;   wob-amp=7 wob-fx=8 wob-fz=9 rip-amp=10 rip-freq=11
;;;   wet=12 wet-patch=13 wet-scale=14 fres-power=15 fres-max=16 spec-color=17

(setq wetroad-shader
(make-shader wetroad :keyword :surface
  (((Ka float) 0.20) ((Kd float) 0.55) ((Ks float) 0.30) ((roughness float) 0.035)
   ((Kr float) 0.92)                                   ; 反射の上限側の強さ
   ((road-color color) (make-color 0.105 0.108 0.120))
   ((grain      float) 0.45)    ; 骨材のざらつき (色のムラ)
   ((wob-amp    float) 0.110)   ; うねりの強さ。0.05=ほぼ鏡 / 0.2=水面のように波立つ
   ((wob-fx     float) 0.55)    ; うねりの周波数 (横断方向)
   ((wob-fz     float) 0.10)    ; 〃 (進行方向)。小さいほど反射が縦に伸びる
   ((rip-amp    float) 0.046)   ; さざなみの強さ (うねりの 0.4 倍が目安)
   ((rip-freq   float) 2.60)    ; さざなみの周波数
   ((wet        float) 0.85)    ; 全体の濡れ具合 0..1
   ((wet-patch  float) 0.55)    ; 濡れムラの強さ (乾いた部分を作る)
   ((wet-scale  float) 0.085)   ; 濡れムラの大きさ (小=大きな斑)
   ((fres-power float) 4.0)     ; フレネルの立ち上がり
   ((fres-max   float) 0.88)    ; 反射率の上限。1 にすると完全鏡=運河になる
   ((spec-color color) (make-color 0.85 0.88 0.96)))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((dir point) 0)
    ((qq point) 0) ((rr point) 0) ((slope point) 0)
    ((ex point) (make-point 0.35 0 0))
    ((ez point) (make-point 0 0 0.35))
    ((h0 float) 0) ((hx float) 0) ((hz float) 0)
    ((r0 float) 0) ((rx float) 0) ((rz float) 0)
    ((sx float) 0) ((sz float) 0)
    ((wpat float) 0) ((wetness float) 0)
    ((ag float) 0) ((cc float) 0) ((fres float) 0)
    ((base color) (make-color 0 0 0))
    ((lit  color) (make-color 0 0 0))
    ((refl color) (make-color 0 0 0))
    ((hitp float) 0))

  ;; --- 濡れムラ: 水が残っている所と乾き始めた所 ---
  (setvar wpat (noise (* Pg wet-scale)))
  (setvar wetness (clamp (* wet (+ (- 1 wet-patch) (* wet-patch (* 2 wpat)))) 0 1))

  ;; --- うねり: 進行方向 (z) に引き伸ばした低周波の高さ場の勾配 ---
  ;;     ex/ez は有限差分の刻み。ノイズの周期に対して十分小さく取る。
  (setvar qq (make-point (* (xcomp Pg) wob-fx) (* (ycomp Pg) 0.3) (* (zcomp Pg) wob-fz)))
  (setvar h0 (noise qq))
  (setvar hx (noise (+ qq ex)))
  (setvar hz (noise (+ qq ez)))

  ;; --- さざなみ: 等方の中周波 ---
  (setvar rr (* Pg rip-freq))
  (setvar r0 (noise rr))
  (setvar rx (noise (+ rr ex)))
  (setvar rz (noise (+ rr ez)))

  ;; --- 合成した傾きで法線を倒す (濡れている所だけ揺らぐ) ---
  (setvar sx (* wetness (+ (* wob-amp (- hx h0)) (* rip-amp (- rx r0)))))
  (setvar sz (* wetness (+ (* wob-amp (- hz h0)) (* rip-amp (- rz r0)))))
  (setvar slope (make-point sx 0 sz))
  (setvar Nf (normalize (- Nf slope)))

  ;; --- アスファルトの地色 (骨材のムラ) ---
  (setvar ag (noise (* Pg 11.0)))
  (setvar base (* road-color (+ (- 1 (* grain 0.5)) (* grain ag))))

  ;; --- フレネル: 掠め角ほど反射が占める。上限を切って完全鏡にしない ---
  (setvar cc (clamp (dot Nf Ir) 0 1))
  (setvar fres (clamp (* Kr (* wetness (pow (- 1 cc) fres-power))) 0 fres-max))

  ;; --- 反射 ---
  (setvar dir (reflect I Nf))
  (setvar refl (trace P dir hitp))

  ;; --- **加算でなく mix** — ここがこのシェーダーの要点 ---
  (setvar lit (* base (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ (mix lit refl fres)
                      (* spec-color (* Ks (specular Nf Ir roughness)))))))))

(compile-shader wetroad-shader)
(append-shader wetroad-shader)
