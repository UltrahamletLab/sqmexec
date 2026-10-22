;;; bsdfraku — 黒楽釉 (パストレーシング用の材質シェーダー)
;;;
;;; 長次郎の黒楽茶碗を狙った材質。:volume クラスの PT 材質規約に従う
;;;   Cl = アルベド / Oi = (roughness, metallic, transmission) / Ci = 発光 / t = IOR
;;;
;;; ── 黒楽の見えを決めているもの ──────────────────────────────────────────
;;; 「黒さ」ではない。黒はどう転んでも黒にしかならず、色を凝っても効かない。
;;; 効くのは次の3つで、いずれも**面の中での差**である。
;;;
;;;   ① 艶のむら — 引き出し黒は窯から出して急冷するので釉が熔け切らず、
;;;      つや消しの地に、溜まった所だけ濡れたような光沢が斑に出る。
;;;   ② 釉だれ  — 釉は焼成中に縦へ流れる。流れは縦に伸びた筋になり、
;;;      裾で止まって**釉際 (くすりぎわ)** に厚い溜まりの帯を作る。
;;;   ③ 露胎    — 釉際より下は釉が掛からず素地が出る。ここは赤茶でつや消し。
;;;      高台まわりが土のままなのが楽茶碗の見どころのひとつ。
;;;
;;; ①だけだと「黒くて均一な椀」にしかならなかった (実測)。②③で縦の流れと
;;; 裾の変化が入って初めて楽らしくなる。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color 0.02 0.019 0.019) (kd 1) (bsdf bsdfraku)
;;;            (param low-y 0.05) (param high-y 0.98)
;;;            (param glaze-y 0.20) (param drip 0.10) (param bead 0.045)
;;;            (param flow-scale 5.0) (param flow-stretch 7.0)
;;;            (param mottle 0.55) (param contrast 2.4)
;;;            (param rough-matte 0.66) (param rough-wet 0.10) (param rough-clay 0.85))

(setq bsdfraku-shader

(make-shader bsdfraku :keyword :volume
      (((base-color   color) (make-color 0.020 0.019 0.019))  ; 熔けた釉の黒 (炭の黒)
       ((warm-color   color) (make-color 0.085 0.042 0.026))  ; 釉が薄い所に透ける赤茶
       ((clay-color   color) (make-color 0.150 0.082 0.052))  ; 露胎 (素地) の赤茶
       ((low-y        float) 0.05)   ; 釉溜まりの基準: この高さで最も溜まる
       ((high-y       float) 0.98)   ; この高さで最も薄い (口造り)
       ;; ── 釉だれ ──
       ((glaze-y      float) 0.20)   ; 釉際の基準高さ。これより下は露胎
       ((drip         float) 0.10)   ; 釉際の高さのばらつき (垂れの不揃い)
       ((bead         float) 0.045)  ; 釉際に溜まる帯の幅 (厚い所=濡れて黒い)
       ((flow-scale   float) 5.0)    ; 流れ筋の横方向の細かさ
       ((flow-stretch float) 7.0)    ; 縦への引き伸ばし (大きいほど筋が長い)
       ((flow         float) 0.45)   ; **流れ筋が艶に出る量**。0 だと縦の流れが見えない
       ;; ── 艶むら ──
       ((mottle       float) 0.55)   ; 艶むらの強さ (0=一様)
       ((mottle-scale float) 6.0)    ; 艶むらの空間スケール
       ((contrast     float) 2.4)    ; 斑のコントラスト (>1 で艶/つや消しが分かれる)
       ((rough-matte  float) 0.66)   ; 熔け切らない地のつや消し
       ((rough-wet    float) 0.10)   ; 溜まりの濡れた光沢
       ((rough-clay   float) 0.85)   ; 露胎 (土) のつや消し
       ((thin-warm    float) 0.22)   ; 釉が薄い所が赤茶に振れる量
       ;; ── 時代 (伝世の風合い) ──
       ((age          float) 0.0)    ; 全体の効き。0 = 焼き上がり / 1 = 伝世品
       ((craze-scale  float) 26.0)   ; 貫入の細かさ
       ((craze-width  float) 0.012)  ; 貫入の線の太さ。**太いと素焼きの鉢になる**
       ((craze-color  color) (make-color 0.115 0.085 0.062))  ; 茶が染みた貫入の色
       ((tea          float) 0.75)   ; 見込みの茶渋の濃さ
       ((tea-color    color) (make-color 0.135 0.088 0.058))  ; 茶渋の色
       ((wear         float) 0.6)    ; 口縁の擦れ (使い込みで釉が薄る)
       ;; ── 粒子 (土の砂・鉄粒・熔け残り) ──
       ((speckle       float) 0.0)    ; 粒の量。実物の黒楽は全面に細かい斑が散る
       ((speckle-scale float) 110.0)) ; 粒の細かさ

  (enter (((q     point) (make-point 0 0 0))
          ((h     float) 0.0)
          ((n1    float) 0.0)
          ((sk    float) 0.0)
          ((front float) 0.0)
          ((cov   float) 0.0)
          ((bd    float) 0.0)
          ((pool  float) 0.0)
          ((rg    float) 0.0)
          ((warm  float) 0.0)
          ((rad   point) (make-point 0 0 0))
          ((rr    float) 0.0)
          ((facing float) 0.0)
          ((inside float) 0.0)
          ((c1    float) 0.0)
          ((c2    float) 0.0)
          ((craze float) 0.0)
          ((stain float) 0.0)
          ((wr    float) 0.0)
          ((sp    float) 0.0)
          ((col   color) (make-color 0 0 0)))

    ;; 高さの正規化 0..1 (低い=釉が溜まる / 高い=薄い)
    (setvar h (clamp (/ (- (ycomp Pg) low-y) (- high-y low-y)) 0.0 1.0))

    ;; ── ② 釉だれ: y を縮めて標本すると筋が縦に伸びる ────────────────────
    (setvar q (make-point (* (xcomp Pg) flow-scale)
                          (* (ycomp Pg) (/ flow-scale flow-stretch))
                          (* (zcomp Pg) flow-scale)))
    (setvar sk (vfbm q 3))

    ;; 釉際の高さ: 筋ごとに上下する = 垂れが不揃いになる
    (setvar front (+ glaze-y (* drip (- sk 0.5))))

    ;; 被覆: 釉際より上が釉、下が露胎。境目は少しだけぼかす (釉は縁が丸い)
    (setvar cov (smoothstep (- front 0.012) (+ front 0.030) (ycomp Pg)))

    ;; 溜まりの帯: 釉際のすぐ上が最も厚い。ガウス状の山
    (setvar bd (exp (- 0.0 (* (/ (- (ycomp Pg) (+ front bead))
                                 bead)
                              (/ (- (ycomp Pg) (+ front bead))
                                 bead)))))
    (setvar bd (* bd cov))

    ;; ── ① 艶むら ────────────────────────────────────────────────────────
    (setvar n1 (vfbm (* Pg mottle-scale) 3))
    ;; **コントラストが要る**: 素の fBm は中央に寄るので艶が一様な半艶に潰れ、
    ;; 「熔けた所だけ濡れている」引き出し黒の見えにならなかった (実測)。
    (setvar n1 (clamp (+ 0.5 (* contrast (- n1 0.5))) 0.0 1.0))

    ;; 溜まり具合: 低い所ほど大きく、斑で乱し、**縦の流れ筋**で帯状に振れ、
    ;; 釉際の溜まりで最大になる。1=濡れた光沢 / 0=つや消し。
    ;; ★ sk (流れ筋) を釉際の位置にしか使わないと、胴は等方な斑だけになって
    ;;   「釉が流れた跡」が全く見えない。艶にも効かせるのが肝 (実測で判明)。
    (setvar pool (clamp (+ (+ (* (- 1.0 h) (- 1.0 mottle)) (* mottle n1))
                           (+ (* flow (- sk 0.5)) (* 0.85 bd))) 0.0 1.0))
    (setvar pool (smoothstep 0.0 1.0 pool))

    ;; ── 合成 ────────────────────────────────────────────────────────────
    ;; 釉の色: 薄い所 (高い所 × 斑の薄い側) だけ下地の赤茶へ寄せる
    (setvar warm (* thin-warm (clamp (* h (- 1.0 (* 0.8 n1))) 0.0 1.0)))
    (setvar col (mix base-color warm-color warm))
    ;; ③ 露胎へ: 釉際より下は素地の色
    (setvar col (mix clay-color col cov))

    (setvar rg (+ rough-matte (* (- rough-wet rough-matte) pool)))
    (setvar rg (+ rough-clay (* (- rg rough-clay) cov)))

    ;; ══ 時代 (伝世 400 年の風合い) ═════════════════════════════════════
    ;; 黒楽に時代がつくとは、色が褪せることではない。効くのは次の3つ。
    ;;   ① 貫入に茶が染みて**網目が浮く** — 新品では見えない微細な貫入が、
    ;;      使ううちに茶を吸って褐色の線になる。時代の最大の指標
    ;;   ② 見込みの茶渋 — 内側、とりわけ底の茶溜まりが褐色に染む
    ;;   ③ 口縁の擦れ — 唇と手が触れる所だけ釉が薄り、艶が落ちる
    ;;
    ;; ① 貫入: fBm の 0.5 等高線を細く取ると網目になる。2枚重ねて非周期に。
    ;;    (cnoise の F1 では稜線が出ないので等高線方式を採った)
    (setvar c1 (vfbm (* Pg craze-scale) 2))
    (setvar c2 (vfbm (* (+ Pg (make-point 13.7 5.1 9.3)) (* craze-scale 0.62)) 2))
    (setvar craze (+ (- 1.0 (smoothstep 0.0 craze-width (abs (- c1 0.5))))
                     (- 1.0 (smoothstep 0.0 craze-width (abs (- c2 0.5))))))
    (setvar craze (* (clamp craze 0.0 1.0) cov))   ; 釉のある所だけ

    ;; ② 内外の判別: 外壁は法線が軸から外を向き、内壁は内を向く。
    ;;    見込みの底は法線がほぼ +y なので、低い所の上向き面も内側に入れる。
    (setvar rr (sqrt (+ (* (xcomp Pg) (xcomp Pg)) (* (zcomp Pg) (zcomp Pg)))))
    (setvar rad (normalize (make-point (xcomp Pg) 0.0 (+ (zcomp Pg) 0.00001))))
    (setvar facing (dot (normalize N) rad))
    (setvar inside (smoothstep 0.12 (- 0.12) facing))
    ;; 見込みの底 (上向き かつ 低い) を足す
    (setvar inside (clamp (+ inside
                             (* (smoothstep 0.55 0.85 (ycomp (normalize N)))
                                (smoothstep 0.45 0.22 (ycomp Pg)))) 0.0 1.0))

    ;; 茶渋: 内側ほど、低いほど濃い。貫入にはさらに強く入る
    (setvar stain (* tea (* inside (+ 0.35 (* 0.65 (- 1.0 h))))))
    (setvar stain (clamp (+ stain (* 0.22 craze)) 0.0 1.0))

    ;; ③ 口縁の擦れ: 口の近く (h が高い) の外向き面ほど釉が薄る
    (setvar wr (* wear (smoothstep 0.82 1.0 h)))

    ;; 合成 — age で全部まとめて効かせる
    ;; **効かせすぎない**: 最初 craze 0.55 / stain 0.80 で掛けたら黒釉が消え、
    ;; 素焼きの鉢になった。時代は「黒の上に薄く乗る」もので、黒を置き換えない。
    (setvar col (mix col craze-color (* age (* 0.38 craze))))
    (setvar col (mix col tea-color   (* age (* 0.46 stain))))
    (setvar col (mix col warm-color  (* age (* 0.55 wr))))
    ;; 貫入と茶渋はつや消し寄り、擦れも艶を落とす
    (setvar rg (+ rg (* age (+ (* 0.10 craze) (+ (* 0.10 stain) (* 0.16 wr))))))
    (setvar rg (clamp rg 0.02 0.95))

    ;; ── 粒子 ────────────────────────────────────────────────────────────
    ;; 実物の黒楽は一様な黒でなく、土の砂粒や鉄の粒、熔け残りが全面に散る。
    ;; これが無いと「均一に塗った黒」に見えてしまう。明暗両方に振らせ、
    ;; 粒の所は艶も落とす (熔けていないので)。
    ;; ★ **乗算で振ること**。加算にしたらアルベド 0.0175 に ±0.068 を足す形になり、
    ;;   base の 5 倍まで跳ねて御影石のような灰色の石肌になった (実測)。
    ;;   暗い材質ほど加算は効きすぎる — 明度に比例させるのが正しい。
    (setvar sp (- (vnoise (* Pg speckle-scale)) 0.5))
    (setvar col (* col (+ 1.0 (* speckle (* 1.6 sp)))))
    (setvar rg (+ rg (* speckle (* 0.22 (abs sp)))))
    (setvar rg (clamp rg 0.02 0.95))

    (setvar Cl col)
    ;; Oi = (roughness, metallic, transmission)。釉は誘電体なので metallic 0
    (setvar Oi (make-color rg 0.0 0.0))
    (setvar t 1.52)                 ; 釉のガラス層の IOR
)))

(compile-shader bsdfraku-shader)
(append-shader bsdfraku-shader)
