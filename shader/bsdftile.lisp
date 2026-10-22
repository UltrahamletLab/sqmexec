;;; bsdftile — パストレーシング (-Q) 用。目地のある白いタイル張りの壁/床。
;;;
;;; :volume クラスの PT 材質規約 (詳細は bsdfchecker.lisp 冒頭)。
;;;   Cl = アルベド / Oi = (roughness, metallic, transmission) / t = IOR
;;;
;;; 狙い: **ガラスの後ろに置いて、屈折でタイルの目地が歪むのを見せる**ための面。
;;; 無地の壁だとガラスが「白い靄」にしか見えない — ガラスらしさは
;;; 「背後の直線が曲がること」でしか出ない。だから目地 (細い直線) が要る。
;;; bsdfchecker (市松) では目地が無いので、格子の交点で色が入れ替わるだけになり
;;; 「タイル」に見えない。
;;;
;;; タイルと目地で roughness を変えてある (タイル=磨き / 目地=荒い)。斜光で
;;; タイル面だけが返るので、色差をほとんど付けなくても割り付けが読める。
;;;
;;; 面の向きは Ng から選ぶ (三面のうち法線が最大の軸を捨てる) ので、床にも壁にも
;;; 同じシェーダーをそのまま貼れる。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color 1 1 1) (kd 1) (bsdf bsdftile)
;;;            (param scale 0.28) (param grout 0.007))

(setq bsdftile-shader

(make-shader bsdftile :keyword :volume
      (((scale       float) 0.28)                          ; タイル1辺 (ワールド)
       ((tile-color  color) (make-color 0.93 0.93 0.915))  ; タイル (白)
       ((grout-color color) (make-color 0.70 0.69 0.665))  ; 目地 (やや暗い灰)
       ((grout       float) 0.007)    ; 目地の半幅 (ワールド)
       ((soft        float) 0.004)    ; 目地の縁のぼかし (タイル単位・エイリアス防止)
       ((tile-rough  float) 0.09)     ; タイルの roughness (磨き)
       ((grout-rough float) 0.65)     ; 目地の roughness (荒い)
       ((tint        float) 0.030))   ; タイル毎の明度ゆらぎ (無いとCGに見える)

  ;; ※ローカル名は SGV グローバル (u v s t N P L I E Cs Cl Ci Oi ..) と衝突不可
  (enter (((ax float) 0.0) ((ay float) 0.0) ((az float) 0.0)
          ((wx float) 0.0) ((wy float) 0.0) ((wz float) 0.0)
          ((uu float) 0.0) ((vv float) 0.0)
          ((tu float) 0.0) ((tv float) 0.0)
          ((du float) 0.0) ((dv float) 0.0)
          ((mu float) 0.0) ((mv float) 0.0) ((mk float) 0.0)
          ((iu float) 0.0) ((iv float) 0.0)
          ((gh float) 0.0) ((rg float) 0.0) ((lo float) 0.0)
          ((q  point) (make-point 0 0 0)))

    ;; ── 面の向きで投影面を選ぶ ────────────────────────────────────────
    ;; (step edge x) = x>=edge で 1。max が使えないので step の積で「最大の軸」を出す
    (setvar ax (abs (xcomp Ng)))
    (setvar ay (abs (ycomp Ng)))
    (setvar az (abs (zcomp Ng)))
    (setvar wy (* (step ax ay) (step az ay)))          ; 床/天井 → xz
    (setvar wz (* (- 1.0 wy) (step ax az)))            ; z 向きの壁 → xy
    (setvar wx (- 1.0 (+ wy wz)))                      ; x 向きの壁 → zy
    (setvar uu (+ (* (+ wy wz) (xcomp Pg)) (* wx (zcomp Pg))))
    (setvar vv (+ (* wy (zcomp Pg)) (* (+ wz wx) (ycomp Pg))))

    ;; ── タイル内座標 ─────────────────────────────────────────────────
    ;; ⚠ mod は負を返しうる。そのままだと軸の負側が**一面べったり目地**になる
    ;;   (du が負 → smoothstep が 0)。+1 して mod し直し [0,1) に畳む
    (setvar tu (mod (/ uu scale) 1.0))
    (setvar tu (mod (+ tu 1.0) 1.0))
    (setvar tv (mod (/ vv scale) 1.0))
    (setvar tv (mod (+ tv 1.0) 1.0))

    ;; タイル縁までの距離 [0,0.5]。min が壊れているので 0.5-|t-0.5| で書く
    (setvar du (- 0.5 (abs (- tu 0.5))))
    (setvar dv (- 0.5 (abs (- tv 0.5))))

    (setvar gh (/ grout scale))
    (setvar mu (smoothstep gh (+ gh soft) du))
    (setvar mv (smoothstep gh (+ gh soft) dv))
    (setvar mk (* mu mv))                              ; 1=タイル 0=目地

    ;; ── タイル毎のゆらぎ ─────────────────────────────────────────────
    (setvar iu (floor (/ uu scale)))
    (setvar iv (floor (/ vv scale)))
    (setvar q  (make-point (* iu 0.37) (* iv 0.53) 0.0))
    (setvar lo (* tint (- (vnoise q) 0.5) mk))

    (setvar Cl (+ (mix grout-color tile-color mk)
                  (make-color lo lo (* lo 0.9))))
    ;; ⚠ (mix a b f) は color 専用。float の補間は素の算術で書く
    (setvar rg (+ grout-rough (* (- tile-rough grout-rough) mk)))
    (setvar Oi (make-color rg 0.0 0.0))
)))

(compile-shader bsdftile-shader)
(append-shader bsdftile-shader)
