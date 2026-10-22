;;; caustics.lisp — 水面コースティクス (海底/プール底の揺らめく光の網)
;;;
;;; 床メッシュ(ground.obj 等)に貼って、水面が屈折させた太陽光の網模様を擬似的に描く。
;;; 本物の屈折コースティクスではなく、lava の「等高線リッジ」技法の発展形:
;;;   - 2層のリッジノイズ (f≈0.5 の細帯) を逆方向にドリフトさせ、積を取ると
;;;     交点が明滅する網目になる (水面ゆらぎの干渉らしさが出る)
;;;   - ドメインワープでセルを歪ませ、直線的なノイズ模様を水っぽく崩す
;;;   - dispersion: パターンをRGBで微妙にずらしてサンプル → 網の縁に色収差
;;;   - 網は (diffuse Nf) を乗算 → 影の中ではコースティクスも消える
;;;     (ソフトシャドウ -s n と整合)
;;;   - phase で水面の流れをアニメ化 (ocean の phase と同じ流儀)
;;;   - fade-far: 遠景でリッジ模様を消す距離LOD (ocean と同じ流儀, near=0.3*far)
;;;
;;; パラメータ定義順 (shade_dr.c の caustics_params[] と一致必須, 最大16):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 caustic-color=4 scale=5 intensity=6
;;;   sharpness=7 focus=8 warp=9 dispersion=10 phase=11 fade-far=12

(setq caustics-shader
(make-shader caustics :keyword :surface
  (((Ka float) 0.20) ((Kd float) 0.60) ((Ks float) 0.08) ((roughness float) 0.15)
   ((caustic-color color) (make-color 0.85 1.00 1.05))  ; 光網の色 (やや水色)
   ((scale      float) 0.55)   ; 模様の細かさ
   ((intensity  float) 1.4)    ; 光網の明るさ
   ((sharpness  float) 4.5)    ; 大=リッジ帯が細い
   ((focus      float) 1.8)    ; pow指数: 大=網が細く先鋭
   ((warp       float) 0.7)    ; ドメインワープ量 (水っぽい歪み)
   ((dispersion float) 0.035)  ; RGBずらし量 (色収差フリンジ)
   ((phase      float) 0.0)    ; 水流の位相 (アニメ用)
   ((fade-far   float) 45.0))  ; 距離LOD: この距離で網→0
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((pp point) (make-point 0 0 0))
    ((pw point) (make-point 0 0 0))
    ((pa point) (make-point 0 0 0))
    ((pb point) (make-point 0 0 0))
    ((pd point) (make-point 0 0 0))
    ((wx float) 0) ((wz float) 0)
    ((fa float) 0) ((fb float) 0) ((ra float) 0) ((rb float) 0)
    ((fa2 float) 0) ((fb2 float) 0) ((ra2 float) 0) ((rb2 float) 0)
    ((caus float) 0) ((caus2 float) 0)
    ((cg float) 0)
    ((dist float) 0) ((fade float) 0) ((invf float) 1)
    ((ld color) (make-color 0 0 0))
    ((floorc color) (make-color 0 0 0))
    ((cterm color) (make-color 0 0 0)))
  ;; --- 距離フェード(LOD) ---
  (setvar dist (length (- E Pg)))
  (setvar fade (smoothstep (* fade-far 0.3) fade-far dist))
  (setvar invf (- 1 fade))
  ;; --- ドメインワープ (水面ゆらぎの歪み, phase で漂う) ---
  (setvar pp (* scale Pg))
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
  ;; --- 色収差: ずらした位置でもう1サンプル (R=caus, B=caus2, G=平均) ---
  (setvar pd (make-point dispersion 0 (* dispersion 0.6)))
  (setvar fa2 (+ (* 0.65 (noise (+ pa pd))) (* 0.35 (noise (* 2.3 (+ pa pd))))))
  (setvar fb2 (+ (* 0.65 (noise (+ pb pd))) (* 0.35 (noise (* 2.3 (+ pb pd))))))
  (setvar ra2 (- 1 (clamp (* sharpness (abs (- (* 2 fa2) 1))) 0 1)))
  (setvar rb2 (- 1 (clamp (* sharpness (abs (- (* 2 fb2) 1))) 0 1)))
  (setvar caus2 (pow (clamp (* 1.6 ra2 rb2) 0 1) focus))
  (setvar cg (* 0.5 (+ caus caus2)))
  ;; --- 合成: 床のmatte + 光網(ライト/影に従う) + 弱いスペキュラ ---
  (setvar ld (diffuse Nf))
  (setvar floorc (* Cs (+ (* Ka (ambient)) (* Kd ld))))
  (setvar cterm (* intensity invf caustic-color (make-color caus cg caus2) ld))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ floorc cterm (* Ks (specular Nf Ir roughness))))))))

(compile-shader caustics-shader)
(append-shader caustics-shader)
