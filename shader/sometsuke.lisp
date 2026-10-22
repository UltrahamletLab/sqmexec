;;; sometsuke — 有田焼の染付 (青花)。白磁の素地に呉須 (コバルト) の麻の葉文様を
;;;   描き、その上から透明釉をかけた状態を1枚で出す。
;;;
;;; ■ 文様 = 麻の葉 (あさのは)
;;;   正三角格子の **辺** と、各三角形の **3本の中線** の合併。
;;;   重心座標 (a,b,c), a+b+c=1 で書くと
;;;       辺   : a=0 / b=0 / c=0        → min(a,b,c)
;;;       中線 : a=b / b=c / c=a        → min(|a-b|,|b-c|,|c-a|)
;;;   の2つだけで表せる (格子点に12本が放射する、あの形になる)。
;;;   ⚠ **中線の距離は √3 で割る**。重心座標の差から実距離への換算係数が
;;;     辺 (=a·h) と中線 (=|a-b|·h/√3) で違うので、割らないと中線だけ約1.7倍
;;;     太い別の文様になる。
;;;
;;; ■ 投影 = トライプラナー
;;;   SDF の器物には UV が無く、球面 s,t に落ちると腕や脚で文様が伸びて潰れる。
;;;   xy / yz / zx の3面に投影して法線の2乗で混ぜる (継ぎ目が出にくい定番)。
;;;   ⚠ 混合の重みは **鋭くする** (pow)。素の |n| だと3面が広く重なって
;;;     文様が二重写しにボケる。
;;;
;;; ■ 釉薬
;;;   染付は**釉の下**にあるので、**拡散色だけ**を文様で変え、**スペキュラは一様**に
;;;   保つ。これが「絵の上にガラスが乗っている」に見えるかどうかの分かれ目で、
;;;   文様側にも光沢を乗せると絵具が盛り上がって見える。
;;;   掠め角のフレネルで濡れた艶を足す (磁器は縁がよく光る)。
;;;
;;;   params: Ka=0 Kd=1 Ks=2 roughness=3 body-color=4 dye-color=5 scale=6
;;;           line-width=7 bleed=8 wash=9 wash-scale=10 sheen=11 spec-color=12
;;;           sharpen=13

(setq sometsuke-shader

(make-shader sometsuke :keyword :surface
      (
       ((Ka float) 0.22)
       ((Kd float) 0.72)
       ((Ks float) 0.85)
       ((roughness float) 0.018)                            ; 磁器釉 = 狭く鋭い艶
       ((body-color color) (make-color 0.945 0.950 0.930))  ; 白磁 (わずかに温白)
       ((dye-color  color) (make-color 0.075 0.230 0.640))  ; 呉須 (コバルト)
       ((scale float) 0.085)        ; 文様1格子の world 寸法
       ((line-width float) 0.055)   ; 線の太さ (重心座標での半幅)
       ((bleed float) 0.030)        ; 線の縁のにじみ (手描きの柔らかさ)
       ((wash float) 0.35)          ; 濃淡ムラ (だみ) の強さ
       ((wash-scale float) 9.0)     ; 濃淡ムラの空間周波数
       ((sheen float) 0.85)         ; 掠め角の濡れ艶
       ((spec-color color) (make-color 1.0 0.99 0.96))
       ((sharpen float) 30.0)        ; トライプラナー混合の鋭さ
       ((crisp float) 0.50)         ; 文様のコントラスト (0.5=ほぼ素通し)
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
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
          ((fres float) 0)
          ((base color) (make-color 0 0 0))
          ((dye color) (make-color 0 0 0)))

    ;; 支配軸の重み。正規化に使う (上の pow の注意を参照)
    (setvar nmax (max (abs (xcomp Nf)) (abs (ycomp Nf)) (abs (zcomp Nf))))
    (setvar nmax (max nmax 0.0001))

    ;; ── 麻の葉文様をトライプラナーで3面ぶん評価 ──────────────────────
    (repeat (j 3)
      ;; j=0 → xy面(法線z) / j=1 → yz面(法線x) / j=2 → zx面(法線y)
      ;; ⚠ **`mix` は color 専用** (interface/shader.lisp の mix-hook が
      ;;   verify-class 'color で弾く)。float の内挿は a+(b-a)t を自分で書く。
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
      ;; セル内のどちらの三角形か (fx+fy>=1 なら上側)
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

    ;; 染付は釉の**下** → 拡散色だけを文様で変える
    (setvar base (mix body-color dye (clamp (* pat dens) 0 1)))

    ;; ── 釉薬の艶 (スペキュラは文様に依らず一様) ─────────────────────
    (setvar fres (- 1 (clamp (dot Nf Ir) 0 1)))
    (setvar fres (* fres (* fres fres)))          ; Schlick 風に立ち上げる

    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* spec-color
                           (* Ks (+ 1 (* sheen fres)))
                           (specular Nf Ir roughness)))))))
)

(compile-shader sometsuke-shader)
(append-shader sometsuke-shader)
