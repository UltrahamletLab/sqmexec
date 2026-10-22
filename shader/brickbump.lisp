;;; brickbump — レンガ壁の変位シェーダー
;;;
;;; 移植元: BMRT brickbump.sl (+ patterns.h の basicbrick())
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;; 原典は displacement シェーダーで、目地の溝 (水平/垂直) を掘り、レンガ面に
;;; ピット (あばた) を刻んで P を法線方向に動かす。
;;;
;;; ── sqm 版の違い ────────────────────────────────────────────────
;;; ・:displacement クラスは**距離関数の中から1マーチステップ毎**に呼ばれ、
;;;   入力は3D点 P だけ・出力は高さ `disp`。P を動かすのでも N を作るのでもない
;;;   (engine が d -= amp*disp するので法線もシルエットも付いてくる)。
;;; ・**s,t は渡ってこない** → 平面投影で復元する。`axis` で投影面を選ぶ:
;;;     axis 0 → (s,t) = (Pz, Py)   x を向く壁
;;;     axis 1 → (s,t) = (Px, Pz)   床/天井
;;;     axis 2 → (s,t) = (Px, Py)   z を向く壁 (既定)
;;;   **原典の s,t は 0..1 のパラメータ空間だが、ここでは s,t = ワールド長**。
;;;   したがって brickwidth 等はワールド単位でそのまま指定する
;;;   (壁幅 4.0 に brickwidth 0.25 なら 16 枚並ぶ)。
;;; ・原典の disp は 0 以下 (掘る方向) だが、sqm の慣習は h∈[0,1] + シーンの amp。
;;;   h = 1 + disp/(groovedepth+pitting) に正規化した。形は同一で、
;;;   **シーンの (amp) には groovedepth+pitting を入れる** (既定なら 0.02)。
;;; ・RSL の mod は floor 基準で負でも [0,1) だが C の fmod は符号が残る。
;;;   行ずらしは (- q (floor q)) で書く (原点より下の行で崩れるのを防ぐ)。
;;; ・原典が宣言だけして使っていない `rowvary` を、basicbrick の
;;;   rowstaggervary (原典はリテラル 0.2 を直接渡している) に繋いだ。
;;;   **既定値を 0.2 にしてあるので既定では原典と同じ絵**になる
;;;   (原典の宣言側の既定 0.25 ではない)。brick.sl 側も同じ穴を持つ。
;;;
;;; 使い方 (シーン):
;;;   (displace (amp 0.02) (mode dsl) (shader brickbump) (lipschitz 210)
;;;             (param brickwidth 0.25) (param brickheight 0.08)
;;;             (param mortarthickness 0.01) (param groovedepth 0.01)
;;;             (param pitting 0.01) (param pockfrequency 10)
;;;             (param jagged 0.006) (param rowvary 0.2) (param axis 2))
;;;
;;;   ※ lipschitz の目安 (溝の壁が支配する):
;;;        L ≈ 4*groovedepth/(mortarthickness*(groovedepth+pitting))
;;;      既定値なら 4*0.01/(0.01*0.02) = 200。ピットの項が
;;;        pitting*pockfrequency/min(BMWIDTH,BMHEIGHT) 程度乗るので少し上乗せする。
;;;      **溝を細く深くするほど急増する**。小さすぎると球面追跡が目地に穴を開ける
;;;      → 掠める角度で5倍拡大して確認すること。

(setq brickbump-shader

(make-shader brickbump :keyword :displacement
      (
       ((jagged          float) 0.006)  ; レンガ形状のゆらぎ (ノイズで s,t を歪める)
       ((brickwidth      float) 0.25)   ; レンガ幅   (ワールド単位)
       ((brickheight     float) 0.08)   ; レンガ高さ (ワールド単位)
       ((mortarthickness float) 0.01)   ; 目地の厚み (ワールド単位)
       ((rowvary         float) 0.2)    ; 行ごとのランダムな横ずれ
       ((pitting         float) 0.01)   ; レンガ面のあばたの深さ
       ((pockfrequency   float) 10.0)   ; あばたの周波数
       ((groovedepth     float) 0.01)   ; 目地の溝の深さ
       ((axis            float) 2.0)    ; 投影面 0=yz 1=zx 2=xy
       )

  (enter (((BMWIDTH  float) (+ brickwidth  mortarthickness))
          ((BMHEIGHT float) (+ brickheight mortarthickness))
          ((MWF float) (/ (* mortarthickness 0.5) (+ brickwidth  mortarthickness)))
          ((MHF float) (/ (* mortarthickness 0.5) (+ brickheight mortarthickness)))
          ((hmax float) (+ groovedepth pitting))
          ((sc  float) 0.0) ((tc  float) 0.0)
          ((xt  float) 0.0) ((yt  float) 0.0)
          ((ss  float) 0.0) ((tt  float) 0.0)
          ((sb  float) 0.0) ((tb  float) 0.0)
          ((row float) 0.0) ((q   float) 0.0)
          ((jx  float) 0.0) ((jy  float) 0.0)
          ((d   float) 0.0) ((fct float) 0.0) ((pk float) 0.0)
          ((a   float) 0.0) ((b   float) 0.0))

    ;; ── 投影面から (s,t) を復元 ───────────────────────────────
    (setvar sc (xcomp P))
    (setvar tc (ycomp P))
    (if (< axis 0.5) (setvar sc (zcomp P)))                        ; axis 0: (z, y)
    (if (and (> axis 0.5) (< axis 1.5)) (setvar tc (zcomp P)))     ; axis 1: (x, z)

    ;; ── basicbrick() (patterns.h) ─────────────────────────────
    ;; jaggedfreq = 1 固定 (原典の呼び出し)。RSL の point noise(x,y) は 2D 入力
    ;; なので z=0 の3D点で呼ぶ。3成分は非相関で、sqm の pnoisep は
    ;;   x成分 = perlin(u, v, 0) / y成分 = perlin(u+17.3, v, 0)
    ;; なので、スカラー noise を同じオフセットで2回呼べば**同じ値**になる
    ;; (:displacement では点を返す noise が使えないため)。
    (setvar jx (noise (make-point (/ sc BMWIDTH) (/ tc BMHEIGHT) 0.0)))
    (setvar jy (noise (make-point (+ (/ sc BMWIDTH) 17.3) (/ tc BMHEIGHT) 0.0)))
    (setvar sc (+ sc (* jagged jx)))
    (setvar tc (+ tc (* jagged jy)))

    (setvar xt (/ sc BMWIDTH))
    (setvar yt (/ tc BMHEIGHT))
    (setvar row (floor yt))                    ; 何段目か
    ;; 行ごとに半枚ずらす: mod(0.5*row, 1) — floor 基準 (負の段でも [0,1))
    (setvar q (* 0.5 row))
    (setvar xt (+ xt (- q (floor q))))
    ;; 行ごとのランダムずらし (原典は rowstaggervary=0.2 のリテラル)
    (setvar xt (+ xt (* rowvary (- (noise (+ row 0.5)) 0.5))))
    (setvar sb (floor xt))                     ; 何枚目か (列)
    (setvar ss (- xt sb))                      ; レンガ内 s 0..1
    (setvar tb row)
    (setvar tt (- yt row))                     ; レンガ内 t 0..1

    ;; ── 目地の溝 (原典どおり二次曲線) ──────────────────────────
    (setvar d 0.0)
    (if (< tt MHF)
        (setvar d (* groovedepth (- (* (/ tt MHF) (/ tt MHF)) 1.0)))
        (if (> tt (- 1.0 MHF))
            (setvar d (* groovedepth
                         (- (* (/ (- 1.0 tt) MHF) (/ (- 1.0 tt) MHF)) 1.0)))))
    ;; 縦目地は 0.85 倍 (横目地より浅い = 原典の意匠)
    (if (< ss MWF)
        (setvar d (min d (* 0.85 groovedepth (- (* (/ ss MWF) (/ ss MWF)) 1.0))))
        (if (> ss (- 1.0 MWF))
            (setvar d (min d (* 0.85 groovedepth
                                 (- (* (/ (- 1.0 ss) MWF) (/ (- 1.0 ss) MWF)) 1.0))))))

    ;; ── レンガ面のあばた ───────────────────────────────────────
    ;; 縁に近いほど弱める (fct)。目地の中でも 0.25 倍は残る。
    (setvar a (- (smoothstep 0.0 (* 1.3 MHF) tt)
                 (smoothstep (- 1.0 (* 1.3 MHF)) 1.0 tt)))
    (setvar b (- (smoothstep 0.0 (* 1.3 MWF) ss)
                 (smoothstep (- 1.0 (* 1.3 MWF)) 1.0 ss)))
    (setvar fct (* pitting (+ (* 0.75 (* a b)) 0.25)))
    ;; ※ 原典は BMHEIGHT と BMWIDTH が入れ替わっている (s 側を BMHEIGHT で割る)。
    ;;   意図的かタイポか判断できないので**そのまま**写した。
    (setvar pk (noise (make-point (/ (* (+ ss sb) pockfrequency) BMHEIGHT)
                                (/ (* (+ tt tb) pockfrequency) BMWIDTH)
                                0.0)))
    (setvar d (- d (* fct (pow (max pk 0.0) 0.25))))

    ;; ── sqm の慣習へ: h∈[0,1] (1=レンガ面, 0=溝の底)。amp = groovedepth+pitting
    (setvar disp (clamp (+ 1.0 (/ d (max hmax 0.000001))) 0.0 1.0))
)))

(compile-shader brickbump-shader)
(append-shader brickbump-shader)
