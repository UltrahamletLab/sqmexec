;;; castucco — 北カリフォルニアの壁のスタッコ (変位シェーダー)
;;;
;;; 移植元: BMRT castucco.sl (+ noises.h の fBm / displace.h の Displace)
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;;   Pshad = freq * transform("shader", P)
;;;   disp  = fBm(Pshad, filterwidth, 3, 2, 0.6)     ← 符号つき fBm
;;;   disp  = Km * smoothstep(trough, peak, disp)    ← 谷とメサに二値化
;;;   N     = Displace(normalize(N), "shader", disp, 1)
;;;
;;; ── sqm 版の違い ────────────────────────────────────────────────
;;; ・:displacement クラスは距離関数から per-step 呼ばれ、入力は P・出力は高さ。
;;;   engine が d -= amp*disp するので法線もシルエットも付いてくる
;;;   (原典の Displace()/calculatenormal 相当は engine の中心差分)。
;;; ・**Km は シーンの (amp) に相当**するので param から外した。
;;;   出力 h は [0,1] (0=谷, 1=メサの天面)。原典の Km をそのまま (amp) に書く。
;;; ・`transform("shader", P)` は sqm に shader 空間が無いので**ワールド座標**。
;;;   オブジェクトに追従させたいときは (displace .. (local)) を使う。
;;; ・`filterwidthp` による帯域制限 (アンチエイリアス) は :displacement に
;;;   微分が無いので落とした。**freq を上げすぎると 1 周期が 1 画素を切って
;;;   ざらつく** (brickbump の pockfrequency と同じ罠) → 本番解像度で確認する。
;;; ・原典は `octaves` を宣言しているが **fBm の呼び出しには literal 3 を渡していて
;;;   使っていない**。ドキュメントどおり効くよう繋ぎ、**既定を 3** にしたので
;;;   既定では原典と同じ絵になる。lacunarity 2 / gain 0.6 も原典の literal のまま。
;;;   ※ 整数 lacunarity は格子が揃って縞が出ることがある (skill の注意)。
;;;     気になったら 2.17 前後に変えるとほぐれる (この定数はコード内)。
;;; ・fBm の素は符号つきノイズ。sqm の noise は [0,1] なので 2*n-1 で符号化する
;;;   (trough=-0.15 / peak=0.35 という既定は符号つき前提の値)。
;;;
;;; 使い方 (シーン):
;;;   (displace (amp 0.2) (mode dsl) (shader castucco) (lipschitz 24)
;;;             (param freq 1.0) (param octaves 3)
;;;             (param trough -0.15) (param peak 0.35))
;;;   ※ amp = 原典の Km。
;;;   ※ lipschitz の目安: (1.5/(peak-trough)) * freq * Σ(gain^i * lac^i) * |∇noise|
;;;        既定 (peak-trough=0.5, freq=1, 3オクターブ, gain0.6/lac2) なら
;;;        3.0 * 1 * 3.64 * 2 ≒ 22 → 24 程度。**freq に比例して上げる**。
;;;     小さすぎると球面追跡がメサの肩を突き抜ける → 掠める角度で確認すること。
;;; ※ per-step で octaves 回のノイズを引くので、オクターブを増やすと素直に重くなる。
;;;   下書きは (param octaves 1) で回すと速い。

(setq castucco-shader

(make-shader castucco :keyword :displacement
      (
       ((freq    float)  1.0)     ; 模様の基本周波数 (ワールド単位あたり)
       ((octaves float)  3.0)     ; fBm のオクターブ数 (原典は literal 3)
       ((trough  float) -0.15)    ; この値以下を谷 (平ら) にする
       ((peak    float)  0.35)    ; この値以上をメサの天面にする
       )

  (enter (((pp  point) (make-point 0 0 0))
          ((amp float) 1.0)
          ((sum float) 0.0)
          ((j   float) 0.0)
          ((h   float) 0.0))

    ;; Pshad = freq * P  (shader 空間 = ワールド)
    (setvar pp (* P freq))

    ;; 符号つき fBm: Σ amp * (2*noise(pp)-1),  amp *= 0.6,  pp *= 2
    (setvar amp 1.0)
    (setvar sum 0.0)
    (repeat (j octaves)
      (setvar sum (+ sum (* amp (- (* 2.0 (noise pp)) 1.0))))
      (setvar amp (* amp 0.6))
      (setvar pp  (* pp  2.0)))

    ;; 谷とメサに二値化 (Km はシーンの amp が担う)
    (setvar h (smoothstep trough peak sum))
    (setvar disp (clamp h 0.0 1.0))
)))

(compile-shader castucco-shader)
(append-shader castucco-shader)
