;;; bsdfsometsuke — 有田焼の染付 (パストレーシング用の材質シェーダー)
;;;
;;; `sometsuke.lisp` (DR サーフェス版) の PT 対応。文様の生成は同一で、
;;; 出力だけ :volume クラスの PT 材質規約に載せ替えてある:
;;;   Cl = アルベド / Oi = (roughness, metallic, transmission) / Ci = 発光 / t = IOR
;;;
;;; ⚠ **`-Q` は DR サーフェスシェーダーを通らない** (材質は独自積分の 4-BSDF 写像)。
;;;   `(shader sometsuke)` だけ書いた .ssq を PT で焼くと文様は**黙って消え**、
;;;   ただの白磁になる。両経路で焼くシーンは `(shader sometsuke)` と
;;;   `(bsdf bsdfsometsuke)` を併記し、param は共通名で1回だけ書く。
;;;
;;; ■ 文様 = 麻の葉 — 正三角格子の **辺** と各三角形の **3本の中線** の合併。
;;;   重心座標 (a,b,c) で 辺=min(a,b,c) / 中線=min(|a-b|,|b-c|,|c-a|)。
;;;   ⚠ **中線の距離は √3 で割る** (重心座標→実距離の換算係数が辺と中線で違う)。
;;;
;;; ■ 投影 = トライプラナー (SDF に UV が無く、球面 s,t だと腕で文様が伸びる)。
;;; ⚠ **混合の鋭さ (sharpen) は 30 前後が要る。** 素の |n| や 4〜8 程度では
;;;     脇の投影が見る**別角度の格子が淡い線として残る** = 二重写し。線の文様は
;;;     写真テクスチャと違って「薄く重なる」が模様として読めてしまうので、
;;;     普通のトライプラナーより遥かに鋭い選択が要る。
;;;     実測 (外套膜を6倍拡大で判定): 4/8 はゴーストあり → 30 で消滅 →
;;;     1000 (実質ハード argmax) と画素差 0.038/255 = **30 で飽和**している。
;;;     継ぎ目は出ない — 3面とも**同じ寸法・同じ位相の三角格子**なので、
;;;     切り替わっても格子が繋がって見える (写真テクスチャなら継ぎ目が出る)。
;;;
;;; ■ 釉薬 — 染付は釉の**下**なので、**アルベドだけ**を文様で変え、
;;;   **roughness は一様**に保つ。文様側の粗さを変えると絵具が盛り上がって見える。
;;;   PT では釉のガラス層を IOR 1.52 の誘電体スペキュラが担うので、
;;;   DR 版の sheen (掠め角フレネル) は要らない (フレネルは積分器が持っている)。
;;;
;;;   params: body-color=0 dye-color=1 scale=2 line-width=3 bleed=4 wash=5
;;;           wash-scale=6 glaze-rough=7 sharpen=8
;;;   (:volume クラスは `_sym_` で名前解決するので shade_dr.cpp の表は不要)

(setq bsdfsometsuke-shader

(make-shader bsdfsometsuke :keyword :volume
      ;; ⚠ **色は「リニアのアルベド」で置く。** DR 版 (sometsuke.lisp) の値は
      ;;   display-referred で、そのまま持ってくると `-T aces:X:2.2` の PT では
      ;;   γ を掛けられて別物になる (呉須 0.075/0.230/0.640 をそのまま渡すと
      ;;   濃紺のはずの染めが水色に浮いた)。DR の値の 2.2 乗が対応するリニア値。
      (((body-color color) (make-color 0.880 0.895 0.855))  ; 白磁 (実物のアルベド ~0.85)
       ((dye-color  color) (make-color 0.0040 0.0370 0.3870)) ; 呉須 = (0.075 0.230 0.640)^2.2
       ((scale      float) 0.110)   ; 文様1格子の world 寸法
       ((line-width float) 0.024)   ; 線の太さ (重心座標での半幅)
       ((bleed      float) 0.008)   ; 線の縁のにじみ (手描きの柔らかさ)
       ((wash       float) 0.40)    ; 濃淡ムラ (だみ) の強さ
       ((wash-scale float) 7.0)     ; 濃淡ムラの空間周波数
       ;; ⚠ **`roughness` という名前にしない**。`sometsuke` (DR 版) と同じ .ssq に
       ;;   併記するので、共通名の param は両方に届いてしまう。DR の roughness は
       ;;   `specular()` の幅、PT の粗さは GGX の α で**意味も適正値も違う**
       ;;   (DR 0.016 を PT に渡すとほぼ完全鏡面になり曲面が延々とノイズる)。
       ;;   → PT 側だけ別名にして、互いの (param ..) を黙って無視させる。
       ((glaze-rough float) 0.045)  ; 釉のスペキュラ。磁器は狭く鋭い
       ((sharpen    float) 30.0)     ; トライプラナー混合の鋭さ
       ((crisp      float) 0.50))   ; 文様のコントラスト (0.5=ほぼ素通し)

  (enter (((Nf point) (normalize N))
          ((j float) 0)
          ((s1 float) 0) ((s2 float) 0)
          ((uu float) 0) ((vv float) 0) ((ww float) 0) ((nmax float) 1)
          ((xx float) 0) ((yy float) 0)
          ((fx float) 0) ((fy float) 0) ((up float) 0)
          ((ba float) 0) ((bb float) 0) ((bc float) 0)
          ((de float) 0) ((dm float) 0) ((dd float) 0)
          ((ln float) 0)
          ((acc float) 0) ((wsum float) 0) ((pat float) 0)
          ((wn float) 0) ((dens float) 0)
          ((dye color) (make-color 0 0 0))
          ((col color) (make-color 0 0 0)))

    ;; 支配軸の重み。正規化に使う (上の pow の注意を参照)
    (setvar nmax (max (abs (xcomp Nf)) (abs (ycomp Nf)) (abs (zcomp Nf))))
    (setvar nmax (max nmax 0.0001))

    ;; ── 麻の葉文様をトライプラナーで3面ぶん評価 ──────────────────────
    (repeat (j 3)
      ;; j=0 → xy面(法線z) / j=1 → yz面(法線x) / j=2 → zx面(法線y)
      ;; ⚠ **`mix` は color 専用** (mix-hook が verify-class 'color で弾く)。
      ;;   float の内挿は a+(b-a)t を自分で書く。
      (setvar s1 (step 0.5 j))
      (setvar s2 (step 1.5 j))
      (setvar uu (+ (xcomp Pg) (* (- (ycomp Pg) (xcomp Pg)) s1)))
      (setvar uu (+ uu (* (- (zcomp Pg) uu) s2)))
      (setvar vv (+ (ycomp Pg) (* (- (zcomp Pg) (ycomp Pg)) s1)))
      (setvar vv (+ vv (* (- (xcomp Pg) vv) s2)))
      (setvar ww (+ (abs (zcomp Nf)) (* (- (abs (xcomp Nf)) (abs (zcomp Nf))) s1)))
      (setvar ww (+ ww (* (- (abs (ycomp Nf)) ww) s2)))
      ;; ⚠ **最大成分で正規化してから pow する。** 素の |n| を累乗すると、
      ;;   法線が対角を向いた所で3軸とも 0.5^sharpen になり、sharpen を上げた
      ;;   途端に重みの和がアンダーフローして**文様が消える** (sharpen 40 で
      ;;   外套膜の一角が白く抜けるのを実測)。最大成分を 1 に正規化すれば
      ;;   支配軸の重みは常に 1 なので、いくら鋭くしても崩れない。
      (setvar ww (pow (/ ww nmax) sharpen))

      ;; 正三角格子へのスキュー変換 (菱形セル → 上下2つの正三角形)
      (setvar xx (- (/ uu scale) (/ vv (* scale 1.7320508))))
      (setvar yy (/ (* 2 vv) (* scale 1.7320508)))
      (setvar fx (- xx (floor xx)))
      (setvar fy (- yy (floor yy)))
      (setvar up (step 1.0 (+ fx fy)))
      ;; 重心座標 (下三角: (1-fx-fy, fx, fy) / 上三角: (1-fy, 1-fx, fx+fy-1))
      (setvar ba (- 1 (+ fx fy)))
      (setvar ba (+ ba (* (- (- 1 fy) ba) up)))
      (setvar bb (+ fx (* (- (- 1 fx) fx) up)))
      (setvar bc (+ fy (* (- (- (+ fx fy) 1) fy) up)))

      (setvar de (min ba bb bc))                             ; 三角格子の辺
      (setvar dm (min (abs (- ba bb)) (abs (- bb bc)) (abs (- bc ba))))
      (setvar dm (/ dm 1.7320508))                           ; ⚠ 中線の換算係数
      (setvar dd (min de dm))
      (setvar ln (- 1 (smoothstep line-width (+ line-width bleed) dd)))

      (setvar acc (+ acc (* ww ln)))
      (setvar wsum (+ wsum ww)))

    (setvar pat (/ acc (max wsum 0.0001)))
    ;; 被覆率のコントラスト。**二重写しの対処にはならない** — 0.50/0.30/0.22/0.12
    ;;   を振ってゴーストは1つも減らなかった (対処は上の sharpen)。線の太さを
    ;;   後段で締めたいときのための調整ノブとして残してある。0.5 でほぼ素通し。
    (setvar pat (smoothstep (- 0.5 crisp) (+ 0.5 crisp) pat))

    ;; ── 呉須の濃淡ムラ (だみ) ───────────────────────────────────────
    ;;   一様な青は印刷に見える。低周波ノイズで濃さを揺らすと手描きになる。
    (setvar wn (vfbm (* Pg wash-scale) 3))
    (setvar dens (clamp (+ (- 1 wash) (* wash (* 2 wn))) 0 1.15))
    (setvar dye (mix dye-color (* dye-color 1.45) (clamp (* 2 (- wn 0.5)) 0 1)))

    ;; 染付は釉の**下** → アルベドだけを文様で変える
    (setvar col (mix body-color dye (clamp (* pat dens) 0 1)))

    (setvar Cl col)
    ;; Oi = (roughness, metallic, transmission)。釉は誘電体なので metallic 0
    (setvar Oi (make-color glaze-rough 0.0 0.0))
    (setvar t 1.52)                 ; 釉のガラス層の IOR
)))

(compile-shader bsdfsometsuke-shader)
(append-shader bsdfsometsuke-shader)
