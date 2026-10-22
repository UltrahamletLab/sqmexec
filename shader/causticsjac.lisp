;;; causticsjac.lisp — ヤコビアン方式の疑似コースティクス (2026-08-10)
;;;
;;; caustics.lisp / causticsproj.lisp は「2層リッジノイズの積」でそれらしい網を作るが、
;;; **コースティクス本来の鋭い折り目 (カスプ) と細胞状の構造が出ない** — ノイズの帯を
;;; 交差させているだけなので、太さが一様な蛇行した紐にしかならない。
;;;
;;; こちらは光学に沿って作る。水面の高さ場を h(x,z) とすると、屈折した光線が床に作る
;;; 写像はおよそ p -> p + c*∇h。**この写像のヤコビアン行列式が 0 に近づく場所に光が
;;; 集まる**ので、明るさを 1/|det J| で出す:
;;;
;;;   det J = (1 + c*h_xx)(1 + c*h_zz) - (c*h_xz)^2
;;;
;;; 折り畳み (det が符号を変える線) が自然に**鋭い明線**になり、その交点が一段明るい
;;; カスプになる。ノイズ方式と違って線の太さが場所によって変わり、細胞が閉じる。
;;;
;;; h は指向の違う5本の正弦波の和 (解析的なので h_xx/h_zz/h_xz が厳密に出る)。
;;; 規則性を崩すため、サンプル位置に fBm のドメインワープを掛けてから波を評価する。
;;;
;;; 立った物体にも貼れるように causticsproj と同じ2つの仕掛けを持つ:
;;;   * proj-y: サンプル点の y を捨てる平面投影 (体に貼っても大理石にならない)
;;;   * up-gate: 上向き面ほど強く (垂直面で投影が縦に伸びる筋を消す)
;;; 床では法線が真上なので up-gate は素通しになる。
;;;
;;; パラメータ定義順 (shade_dr.cpp の causticsjac_params[] と一致必須, 最大24):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 caustic-color=4 scale=5 intensity=6 curv=7
;;;   soft=8 focus=9 warp=10 phase=11 fade-far=12 up-gate=13 proj-y=14 speed=15

(setq causticsjac-shader
(make-shader causticsjac :keyword :surface
  (((Ka float) 0.20) ((Kd float) 0.60) ((Ks float) 0.08) ((roughness float) 0.15)
   ((caustic-color color) (make-color 0.80 1.00 1.05))
   ((scale     float) 0.90)   ; 波数のスケール (大=網が細かい)
   ((intensity float) 1.00)   ; 光網の明るさ
   ((curv      float) 0.55)   ; ∇h の効き = 折り畳みの強さ。大=線が増え密になる
   ((soft      float) 0.10)   ; det=0 の特異点を丸める量。小=線が細く鋭い
   ((focus     float) 1.60)   ; pow 指数。大=線が締まりコントラストが上がる
   ((warp      float) 0.55)   ; fBm ドメインワープ量 (規則性を崩す)
   ((phase     float) 0.0)    ; 水面の位相 (アニメ用)
   ((fade-far  float) 45.0)   ; 距離LOD
   ((up-gate   float) 0.0)    ; 上向き面ゲートの指数 (0=ゲート無し=床用)
   ((proj-y    float) 0.0)    ; 投影平面の y
   ((speed     float) 1.0))   ; 位相の進み方の倍率
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Nn point) (normalize N))
    ((Ir point) (normalize (- I)))
    ((pp point) (make-point 0 0 0))
    ((pw point) (make-point 0 0 0))
    ((px float) 0) ((pz float) 0)
    ((wnx float) 0) ((wnz float) 0)
    ((arg float) 0) ((sv float) 0) ((amp float) 0)
    ((hxx float) 0) ((hzz float) 0) ((hxz float) 0)
    ((jxx float) 0) ((jzz float) 0) ((jxz float) 0)
    ((det float) 0) ((caus float) 0) ((ph float) 0)
    ((nup float) 0) ((gate float) 1)
    ((dist float) 0) ((fade float) 0) ((invf float) 1)
    ((ld color) (make-color 0 0 0))
    ((basec color) (make-color 0 0 0))
    ((cterm color) (make-color 0 0 0)))
  ;; --- 距離フェード(LOD) ---
  (setvar dist (length (- E Pg)))
  (setvar fade (smoothstep (* fade-far 0.3) fade-far dist))
  (setvar invf (- 1 fade))
  (setvar ph (* phase speed))
  ;; --- 平面投影 + fBm ドメインワープ ---
  (setvar pp (* scale (make-point (xcomp Pg) proj-y (zcomp Pg))))
  ;; ★ ワープは **時間で動かさない** (静止)。ここに位相を入れるとノイズ領域が
  ;;   平行移動して周期性が消え、アニメのループが継ぎ目で飛ぶ。規則性を崩すのが
  ;;   目的なので静止で足りる。動きは下の波の位相だけが担う。
  (setvar pw (+ pp (* warp (make-point
                             (- (* 2 (noise (+ (* 0.35 pp) (make-point 4.1 0.0 1.7)))) 1)
                             0
                             (- (* 2 (noise (+ (* 0.35 pp) (make-point 9.3 0.0 6.2)))) 1)))))
  (setvar px (xcomp pw))
  (setvar pz (zcomp pw))

  ;; --- 高さ場 h = Σ a_i sin(k_i·p + ω_i φ) の2階微分を解析的に積む ---
  ;;   h_xx += -a*wx*wx*sin(arg) など (5波を展開。DSL に配列が無いので手で並べる)
  (setvar wnx  1.00) (setvar wnz  0.00) (setvar amp 1.00)
  (setvar arg (+ (* wnx px) (* wnz pz) (* ph 1.0)))
  (setvar sv (* amp (sin arg)))
  (setvar hxx (- hxx (* sv wnx wnx)))
  (setvar hzz (- hzz (* sv wnz wnz)))
  (setvar hxz (- hxz (* sv wnx wnz)))

  (setvar wnx  0.43) (setvar wnz  1.30) (setvar amp 0.72)
  (setvar arg (+ (* wnx px) (* wnz pz) (* ph 2.0)))
  (setvar sv (* amp (sin arg)))
  (setvar hxx (- hxx (* sv wnx wnx)))
  (setvar hzz (- hzz (* sv wnz wnz)))
  (setvar hxz (- hxz (* sv wnx wnz)))

  (setvar wnx -1.30) (setvar wnz  1.30) (setvar amp 0.50)
  (setvar arg (+ (* wnx px) (* wnz pz) (* ph 3.0)))
  (setvar sv (* amp (sin arg)))
  (setvar hxx (- hxx (* sv wnx wnx)))
  (setvar hzz (- hzz (* sv wnz wnz)))
  (setvar hxz (- hxz (* sv wnx wnz)))

  (setvar wnx  2.00) (setvar wnz -1.33) (setvar amp 0.34)
  (setvar arg (+ (* wnx px) (* wnz pz) (* ph 4.0)))
  (setvar sv (* amp (sin arg)))
  (setvar hxx (- hxx (* sv wnx wnx)))
  (setvar hzz (- hzz (* sv wnz wnz)))
  (setvar hxz (- hxz (* sv wnx wnz)))

  (setvar wnx -0.81) (setvar wnz -3.02) (setvar amp 0.22)
  (setvar arg (+ (* wnx px) (* wnz pz) (* ph 5.0)))
  (setvar sv (* amp (sin arg)))
  (setvar hxx (- hxx (* sv wnx wnx)))
  (setvar hzz (- hzz (* sv wnz wnz)))
  (setvar hxz (- hxz (* sv wnx wnz)))

  ;; --- ヤコビアン行列式。0 に近いほど集光 ---
  (setvar jxx (+ 1 (* curv hxx)))
  (setvar jzz (+ 1 (* curv hzz)))
  (setvar jxz (* curv hxz))
  (setvar det (- (* jxx jzz) (* jxz jxz)))
  ;; ★ 1/|det| をそのまま使うと全域で 1 に飽和して網が反転する (最初これで真っ白になった)。
  ;;   det=0 で 1・|det|=soft で 0.5 になるよう正規化する。soft が線の太さそのものになる。
  (setvar caus (pow (/ soft (+ (abs det) soft)) focus))

  ;; --- 上向き面ゲート (床は N.y=1 なので素通し。up-gate 0 でも無効化) ---
  (setvar nup (clamp (ycomp Nn) 0 1))
  (setvar gate 1)
  (if (> up-gate 0.0001) (setvar gate (pow nup up-gate)))

  ;; --- 合成 ---
  (setvar ld (diffuse Nf))
  (setvar basec (* Cs (+ (* Ka (ambient)) (* Kd ld))))
  (setvar cterm (* intensity invf gate caustic-color caus ld))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ basec cterm (* Ks (specular Nf Ir roughness))))))))

(compile-shader causticsjac-shader)
(append-shader causticsjac-shader)
