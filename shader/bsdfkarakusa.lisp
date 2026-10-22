;;; bsdfkarakusa — 有田焼の染付・唐草文 (パストレーシング用の材質シェーダー)
;;;
;;; 兄弟の `bsdfsometsuke.lisp` (麻の葉) と同じ「白磁 + 呉須 + 釉」の枠で、
;;; 文様だけを **唐草 (からくさ)** に差し替えたもの。出力は :volume クラスの
;;; PT 材質規約 (Cl = アルベド / Oi = (rough, metal, trans) / t = IOR)。
;;;
;;; ⚠ **`-Q` は DR サーフェスシェーダーを通らない。** このシェーダーは PT 専用
;;;   なので、従来経路でも焼くシーンは別途 `(shader ..)` を併記すること。
;;;
;;; ■ 文様 = 唐草
;;;   唐草の骨は **水平にうねる蔓**。⚠ `sin(nθ + mh)` で組むと**螺旋の縞**
;;;   (床屋の看板) になる — 最初 Blender 側でそれを作って作り直した。正しくは
;;;   「高さ h が蔓の高さ `vine(θ) = zc + amp·sin(nθ + φ)` に近いところが線」。
;;;   逆位相の蔓を 2 本重ねると、あの絡み合った唐草の目になる。
;;;
;;; ■ 投影 = 円筒 (麻の葉のトライプラナーと違う)
;;;   唐草は「器の周りを water line のように回る」文様なので、軸まわりの角度 θ と
;;;   高さ h で張るのが素直。⚠ **回転体 (lathe) 専用**と割り切る — 手足のある
;;;   造形に貼ると軸から離れた部位で伸びる (そこは麻の葉のトライプラナーの出番)。
;;;   ⚠ θ = atan2 は ±π で**不連続**。蔓の周期 fold を**整数**にすれば継ぎ目で
;;;   位相が 2π·fold ずれる = sin は連続に繋がる (非整数だと縦に筋が出る)。
;;;
;;; ■ 花丸文 — 蔓の合間に散らす小さな丸。
;;;   ⚠ **3D のセルノイズで散らすとほとんど出ない** — セル中心が器の壁の内側に
;;;   入ってしまい、表面がそれを掠めない (Blender 版で実測、1 つも出なかった)。
;;;   (θ, h) の **2D 格子**で置くこと。ここではハッシュ無しの規則格子 + 位相ずらし。
;;;
;;; ■ 圏線 (けんせん) — 頸と高台際に引く水平の二重線。有田焼の定石で、
;;;   これが無いと文様が宙に浮いて見える。
;;;
;;; ■ 釉薬 — 染付は釉の**下**なので、**アルベドだけ**を文様で変え、
;;;   **roughness は一様**に保つ (文様側の粗さを変えると絵具が盛り上がって見える)。
;;;
;;;   params: body-color=0 dye-color=1 fold=2 amp=3 band-lo=4 band-hi=5
;;;           line-width=6 bleed=7 wobble=8 wobble-scale=9 flower=10 flower-scale=11
;;;           wash=12 wash-scale=13 glaze-rough=14

(setq bsdfkarakusa-shader

(make-shader bsdfkarakusa :keyword :volume
      ;; ⚠ **色はリニアのアルベドで置く** (DR 版の display-referred 値をそのまま
      ;;   持ってくると `-T aces:X:2.2` で γ を掛けられて別物になる。bsdfsometsuke
      ;;   と同じ罠)。呉須は DR 値の 2.2 乗。
      (((body-color color) (make-color 0.880 0.895 0.855))   ; 白磁
       ;; ⚠ 濃すぎる原色の青は「顔料」に見える。呉須は鉄分を含む土なので、
       ;;   彩度を落として緑を少し混ぜると焼物の藍になる。
       ((dye-color  color) (make-color 0.0130 0.0430 0.2400)) ; 呉須 (コバルト)
       ((fold        float) 7.0)     ; 蔓が一周する間のうねりの数 (**整数**にする)
       ((amp         float) 0.030)   ; うねりの振幅 (world 単位)
       ((band-lo     float) 0.075)   ; 文様の帯の下端 (world y)
       ((band-hi     float) 0.245)   ; 文様の帯の上端
       ((line-width  float) 0.0060)  ; 蔓の太さ (world 単位の半幅)
       ((bleed       float) 0.0035)  ; 縁のにじみ (手描きの柔らかさ)
       ((wobble      float) 1.6)     ; 蔓の揺らぎ (機械的な正弦にしない)
       ((wobble-scale float) 5.5)    ; 揺らぎの空間周波数
       ((flower      float) 0.0075)  ; 花丸の半径 (0 で消える)
       ((flower-scale float) 14.0)   ; 花丸の (θ,h) 格子の細かさ
       ((wash        float) 0.40)    ; 濃淡ムラ (だみ) の強さ
       ((wash-scale  float) 7.0)     ; 濃淡ムラの空間周波数
       ((glaze-rough float) 0.045)   ; 釉のスペキュラ (磁器は狭く鋭い)
      )

  (enter (((th float) 0) ((hh float) 0) ((rr float) 0)
          ((wob float) 0)
          ((j float) 0) ((ph float) 0) ((zc float) 0)
          ((vz float) 0) ((dv float) 0) ((ln float) 0)
          ((pat float) 0)
          ((fu float) 0) ((fv float) 0) ((cu float) 0) ((cv float) 0)
          ((du float) 0) ((dvv float) 0) ((fd float) 0) ((fl float) 0)
          ((ring float) 0) ((rd float) 0)
          ((wn float) 0) ((dens float) 0)
          ((dye color) (make-color 0 0 0))
          ((col color) (make-color 0 0 0)))

    ;; ── 円筒座標。軸は y (lathe の回転軸) ──
    (setvar th (atan2 (zcomp Pg) (xcomp Pg)))
    (setvar hh (ycomp Pg))
    (setvar rr (sqrt (+ (* (xcomp Pg) (xcomp Pg)) (* (zcomp Pg) (zcomp Pg)))))

    ;; 手描きの揺らぎ (一様な正弦は印刷に見える)
    (setvar wn (vfbm (* Pg wobble-scale) 3))
    (setvar wob (* wobble (- (* 2 wn) 1)))

    ;; ── 蔓 4 本。上下 2 段 × 逆位相 2 本で絡ませる ──────────────────
    ;;   高さ hh が蔓 vz(θ) に近いところが線。
    (setvar pat 0)
    (repeat (j 4)
      ;; j=0,1 → 下段 (逆位相) / j=2,3 → 上段 (逆位相を 90 度ずらす)
      (setvar ph (* 3.14159265 (+ (step 0.5 j)
                                  (* 0.5 (step 1.5 j)))))
      (setvar zc (+ (+ band-lo (* 0.28 (- band-hi band-lo)))
                    (* (step 1.5 j) (* 0.44 (- band-hi band-lo)))))
      (setvar vz (+ zc (* amp (sin (+ (+ (* fold th) ph) wob)))))
      (setvar dv (abs (- hh vz)))
      (setvar ln (- 1 (smoothstep line-width (+ line-width bleed) dv)))
      (setvar pat (max pat ln)))

    ;; ── 花丸文: (θ, h) の 2D 格子に置く ────────────────────────────
    ;;   ⚠ 3D セルノイズだと中心が壁の内側に入って表面に出ない (上のコメント)。
    (setvar fu (* (* th 0.16) flower-scale))     ; θ を h と同程度のスケールに
    (setvar fv (* hh flower-scale))
    (setvar cu (- fu (floor fu)))
    (setvar cv (- fv (floor fv)))
    (setvar du (- cu 0.5))
    (setvar dvv (- cv 0.5))
    (setvar fd (/ (sqrt (+ (* du du) (* dvv dvv))) flower-scale))
    (setvar fl (- 1 (smoothstep flower (+ flower bleed) fd)))
    (setvar pat (max pat fl))

    ;; 帯の外は文様を出さない (全面に回すと「布」に見える。器は余白が要る)
    (setvar pat (* pat (* (smoothstep band-lo (+ band-lo 0.012) hh)
                          (- 1 (smoothstep (- band-hi 0.012) band-hi hh)))))

    ;; ── 圏線: 帯の上下に二重線を引く ────────────────────────────────
    (setvar ring 0)
    (repeat (j 4)
      ;; 下段 2 本 (帯の下 0.010/0.017) / 上段 2 本 (帯の上)
      (setvar zc (+ (- band-lo 0.010) (* 0.007 (step 0.5 j))))
      (setvar zc (+ zc (* (step 1.5 j) (+ (- band-hi band-lo) 0.020))))
      (setvar rd (abs (- hh zc)))
      (setvar ring (max ring (- 1 (smoothstep 0.0016 0.0030 rd)))))
    (setvar pat (max pat ring))

    ;; ── 呉須の濃淡ムラ (だみ) ───────────────────────────────────────
    ;;   ⚠ **dens が 1 を超えると濃淡が出ない。** 最終合成は
    ;;   `mix(body, dye, clamp(pat*dens, 0, 1))` なので、線の芯 (pat=1) では
    ;;   dens>1 が clamp で潰れて**どこも同じ濃さ**になる (兄弟の bsdfsometsuke は
    ;;   1.15 まで許しているが、あちらは線が細く芯の面積が小さいので目立たない)。
    ;;   唐草は線が太いので、**dens を必ず 1 以下**に収めて芯で濃淡を出す。
    (setvar wn (vfbm (* Pg wash-scale) 3))
    (setvar dens (- 1 (* wash (- 1 (clamp (* 1.35 wn) 0 1)))))
    ;; 筆の擦れ (かすれ): 高周波を薄く重ねて一様な塗りを崩す
    (setvar dens (* dens (- 1 (* 0.22 (vfbm (* Pg (* wash-scale 5.5)) 2)))))
    (setvar dens (clamp dens 0 1))
    (setvar dye (mix dye-color (* dye-color 1.45) (clamp (* 2 (- wn 0.5)) 0 1)))

    ;; 染付は釉の**下** → アルベドだけを文様で変える
    (setvar col (mix body-color dye (clamp (* pat dens) 0 1)))

    (setvar Cl col)
    ;; Oi = (roughness, metallic, transmission)。釉は誘電体なので metallic 0
    (setvar Oi (make-color glaze-rough 0.0 0.0))
    (setvar t 1.52)                 ; 釉のガラス層の IOR
)))

(compile-shader bsdfkarakusa-shader)
(append-shader bsdfkarakusa-shader)
