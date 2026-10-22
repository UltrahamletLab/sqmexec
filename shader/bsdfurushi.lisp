;;; bsdfurushi — 輪島塗 (溜塗の赤縁 + 蒔絵の松葉文)。パストレーシング用の材質。
;;;
;;; :volume クラスの **PT 材質規約** (bsdfchecker.lisp 冒頭に全文):
;;;   read  Pg/P (ワールド) / N / Cs (シーンの color) / u,v
;;;   write Cl アルベド / Ci 発光 / Oi = (roughness, metallic, transmission) / t = IOR
;;;
;;; ── この材質が解く2つのこと ──────────────────────────────────────────────
;;;
;;; ① **溜塗の赤縁** — 溜塗は透明な赤褐色の漆の下に黒が沈む塗りで、**縁だけ
;;;    黒が薄く研ぎ出されて下地の赤が透ける**。参考写真では 口縁・蓋の縁・
;;;    摘みの上端・畳付き の4箇所に赤い線が走り、これが漆器の識別要素になっている。
;;;
;;;    ★ フレネル (掠め角) では**作らない**。2026-08-02 に I (視線方向) が
;;;      ブリッジで渡るようになった (-Q のみ。実例 bsdffresnel.lisp) が、
;;;      実物の赤縁は視線依存ではなく「黒が物理的に薄い場所」に固定なので、
;;;      フレネルで作るとカメラ移動で赤が滑る。**幾何 (位置と法線) で作る**
;;;      のが正: 「指定した高さの帯」= 轆轤挽きの器の縁は必ず特定の高さにある、
;;;      という性質を使う。e1/e2/e3 に縁の world-y を渡す。
;;;
;;; ② **蒔絵の松葉文** — 中心から放射する細い金線の束。円筒座標で描く。
;;;    ★ atan2 は ±π で不連続 (dfspiral.lisp と同じ罠)。模様の中心角からの差を
;;;      [-π,π] に畳んでから使う。畳んだ跡は器の反対側に来るので、模様の半径が
;;;      周長より十分小さければ見えない。
;;;    ★ **針の太さを一定にする**には角度でなく垂線距離で判定する。
;;;      放射状の線を「角度の余り」だけで切ると、中心から遠いほど太くなる。
;;;      p = d·Δφ (垂線距離) で切ると実際の針になる。
;;;    ★ 中心では全ての針が集まって潰れるので、中心付近をフェードで抜く。
;;;
;;; ── 制約 (承知の上で使うこと) ─────────────────────────────────────────────
;;;   模様は (円周方向の弧長, 高さ) の平面に描く。**ほぼ水平な面 (蓋の天面や
;;;   摘みの上) では高さがほとんど変わらないので模様が径方向に伸びて潰れる**。
;;;   置くのは立った面 (胴、蓋の外周の斜面) に限ること。水平面に置きたければ
;;;   |N.y| で (x,z) 平面へ切り替える版が要る。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color 0.0115 0.011 0.011) (kd 1) (bsdf bsdfurushi)
;;;            (param edge 0.85) (param e2 0.785)
;;;            (param m1y 0.42) (param m1t 100))
;;;   ※ 黒地はシーンの (color ..) = Cs から来る (param を1つ節約するため)。
;;;   ※ (surface ..) の param 文字列は **512 バイト上限** (SurfData.extra_params)。
;;;     全部書くと溢れるので、既定から変える分だけ書くこと。

(setq bsdfurushi-shader

(make-shader bsdfurushi :keyword :volume
      (((tame-color color) (make-color 0.30 0.075 0.025))  ; 下地の赤褐色 (べっ甲)
       ((edge       float) 0.85)     ; 赤縁の出る量。0 で呂色 (黒一色) になる
       ((edge-w     float) 0.020)    ; 帯の幅 (world)。太いと塗り分けに見える
       ((e1         float) 0.005)    ; 縁の高さ その1 (畳付き)
       ((e2         float) 0.785)    ; その2 (口縁 + 蓋の縁)
       ((e3         float) 1.003)    ; その3 (摘みの上端)
       ((rough      float) 0.04)     ; 漆の roughness。0.02=樹脂 / 0.10 超で曇る
       ((gold-color color) (make-color 0.86 0.63 0.24))  ; 蒔絵の金
       ((gold-rough float) 0.22)     ; 金粉なので鏡面ほど滑らかではない
       ((needles    float) 26.0)     ; 松葉の針の本数 (全周あたり)
       ((needle-w   float) 0.0035)   ; 針の太さ (world)。垂線距離で判定
       ((m-r        float) 0.17)     ; 松葉の半径 — 胴 (m1)
       ((m-r2       float) 0.075)    ; 松葉の半径 — 蓋 (m2/m3)
       ((m1y        float) 0.42)     ; 松葉1 中心の高さ
       ((m1t        float) 100.0)    ; 松葉1 中心の角度 (度。atan2(z,x) 基準)
       ((m2y        float) 0.805)
       ((m2t        float)  72.0)
       ((m3y        float) 0.808)
       ((m3t        float) 128.0))

  (enter (((rr    float) 0.0)
          ((th    float) 0.0)
          ((amber float) 0.0)
          ((ww    float) 0.0)
          ((dth   float) 0.0)
          ((aa    float) 0.0)
          ((bb    float) 0.0)
          ((dd    float) 0.0)
          ((ph    float) 0.0)
          ((gg    float) 0.0)
          ((fr    float) 0.0)
          ((pp    float) 0.0)
          ((gk    float) 0.0)
          ((gold  float) 0.0)
          ((rg    float) 0.0)
          ((col   color) (make-color 0 0 0)))

    (setvar rr (sqrt (+ (* (xcomp Pg) (xcomp Pg)) (* (zcomp Pg) (zcomp Pg)))))
    (setvar th (atan2 (zcomp Pg) (xcomp Pg)))

    ;; ══ ① 溜塗の赤縁 ═══════════════════════════════════════════════════
    ;; 指定した3つの高さに帯を立てる。轆轤の器は縁が必ず特定の高さにあるので、
    ;; 高さの帯 = そのまま縁のリングになる。
    (setvar amber (- 1.0 (smoothstep 0.0 edge-w (abs (- (ycomp Pg) e1)))))
    (setvar ww    (- 1.0 (smoothstep 0.0 edge-w (abs (- (ycomp Pg) e2)))))
    (setvar amber (+ amber ww))
    (setvar ww    (- 1.0 (smoothstep 0.0 edge-w (abs (- (ycomp Pg) e3)))))
    (setvar amber (clamp (* edge (+ amber ww)) 0.0 1.0))
    (setvar col (mix Cs tame-color amber))

    ;; ══ ② 蒔絵の松葉 ═══════════════════════════════════════════════════
    ;; 松葉1 (胴) ────────────────────────────────────────────────────────
    (setvar dth (- th (* m1t 0.0174532925)))
    (setvar dth (- dth (* 6.283185307 (floor (/ (+ dth 3.14159265) 6.283185307)))))
    (setvar aa (* dth rr))
    (setvar bb (- (ycomp Pg) m1y))
    (setvar dd (sqrt (+ (* aa aa) (* bb bb))))
    (setvar ph (atan2 bb aa))
    (setvar gg (* (/ ph 6.283185307) needles))
    (setvar fr (- gg (floor gg)))
    (setvar fr (- 0.5 (abs (- fr 0.5))))        ; 最寄りの針までの角度 (周期の割合)
    (setvar pp (* dd (* fr (/ 6.283185307 needles))))   ; 垂線距離 = 針の太さの基準
    (setvar gk (* (- 1.0 (smoothstep (* needle-w 0.35) needle-w pp))
                  (* (- 1.0 (smoothstep (* m-r 0.72) m-r dd))
                     (smoothstep 0.0 (* m-r 0.09) dd))))
    (setvar gold gk)

    ;; 松葉2 (蓋の外周) ──────────────────────────────────────────────────
    (setvar dth (- th (* m2t 0.0174532925)))
    (setvar dth (- dth (* 6.283185307 (floor (/ (+ dth 3.14159265) 6.283185307)))))
    (setvar aa (* dth rr))
    (setvar bb (- (ycomp Pg) m2y))
    (setvar dd (sqrt (+ (* aa aa) (* bb bb))))
    (setvar ph (atan2 bb aa))
    (setvar gg (* (/ ph 6.283185307) needles))
    (setvar fr (- gg (floor gg)))
    (setvar fr (- 0.5 (abs (- fr 0.5))))
    (setvar pp (* dd (* fr (/ 6.283185307 needles))))
    (setvar gk (* (- 1.0 (smoothstep (* needle-w 0.35) needle-w pp))
                  (* (- 1.0 (smoothstep (* m-r2 0.72) m-r2 dd))
                     (smoothstep 0.0 (* m-r2 0.09) dd))))
    (setvar gold (clamp (+ gold gk) 0.0 1.0))

    ;; 松葉3 (蓋の外周) ──────────────────────────────────────────────────
    (setvar dth (- th (* m3t 0.0174532925)))
    (setvar dth (- dth (* 6.283185307 (floor (/ (+ dth 3.14159265) 6.283185307)))))
    (setvar aa (* dth rr))
    (setvar bb (- (ycomp Pg) m3y))
    (setvar dd (sqrt (+ (* aa aa) (* bb bb))))
    (setvar ph (atan2 bb aa))
    (setvar gg (* (/ ph 6.283185307) needles))
    (setvar fr (- gg (floor gg)))
    (setvar fr (- 0.5 (abs (- fr 0.5))))
    (setvar pp (* dd (* fr (/ 6.283185307 needles))))
    (setvar gk (* (- 1.0 (smoothstep (* needle-w 0.35) needle-w pp))
                  (* (- 1.0 (smoothstep (* m-r2 0.72) m-r2 dd))
                     (smoothstep 0.0 (* m-r2 0.09) dd))))
    (setvar gold (clamp (+ gold gk) 0.0 1.0))

    ;; ══ 合成 ═══════════════════════════════════════════════════════════
    ;; 金は金属、漆は誘電体。metallic を蒔絵のマスクでそのまま切り替える
    (setvar col (mix col gold-color gold))
    (setvar rg  (+ (* rough (- 1.0 gold)) (* gold-rough gold)))

    (setvar Cl col)
    (setvar Oi (make-color rg gold 0.0))
    (setvar t 1.50)                 ; 漆の透明層の IOR
)))

(compile-shader bsdfurushi-shader)
(append-shader bsdfurushi-shader)
