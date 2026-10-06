;;; dented — 使い込まれた凹み (変位シェーダー)
;;;
;;; 移植元: BMRT dented.sl (+ noises.h の turbulence / pshad.h)
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;;   magnitude = turbulence(Pshad, maxoctaves, 2, 0.5)      ← Σ gain^i·|snoise|
;;;   magnitude = pow(magnitude/(2*shadingfreq), power)
;;;   N = Displace(normalize(N), space, -Km*magnitude, truedisp)   ← **内側に掘る**
;;;
;;;   power 1 ≈ くしゃくしゃにした紙/布、power 3 ≈ すり減った金属 (原典コメント)。
;;;
;;; ── sqm 版の違い ────────────────────────────────────────────────
;;; ・:displacement クラス。入力は P のみ・出力は高さ disp。
;;;   **出力は負** (disp = -h, h∈[0,1]) — engine の d -= amp*disp で表面が沈む。
;;;   node displace の axisramp と同じ符号つき出力の作法。**amp には原典の Km**。
;;; ・shadingspace は world (オブジェクト追従は (displace .. (local)))。
;;; ・turbulence はフックでなくループでインライン (maxoctaves/lac 2/gain 0.5 を
;;;   原典どおり制御するため)。|2*noise-1| の絶対値和なので **折り目 (谷) に
;;;   無限周波数の稜線が立つ** — これが「凹み」の看板 (smooth な fBm との違い)。
;;; ・原典の /(2*shadingfreq) 正規化 (freq を上げると浅くなる) も忠実に写した。
;;;
;;; パラメータ定義順 (shade_dr.cpp の dented_dparams[] と一致必須):
;;;   power=0 maxoctaves=1 shadingfreq=2
;;;
;;; 使い方 (シーン):
;;;   (displace (amp 0.05) (mode dsl) (shader dented) (lipschitz 40)
;;;             (param power 3) (param maxoctaves 6) (param shadingfreq 1.5))
;;;   ※ amp = 原典の Km。lipschitz の目安:
;;;       |∇turb| ≈ 2·maxoctaves·shadingfreq,  dh/dt ≤ power/2
;;;       → L ≈ power·maxoctaves·shadingfreq (既定 3·6·1=18 → 24 前後を申告)。
;;;     freq/power を上げたら比例で上げる。マーチ上限による「大きすぎ」の罠は
;;;     docs/2026-08-09_castucco_スタッコ変位.md 参照。
;;;   ※ per-step × maxoctaves 回の noise なので下書きは (param maxoctaves 3)。

(setq dented-shader

(make-shader dented :keyword :displacement
      (
       ((power       float) 3.0)   ; 1=紙のしわ / 3=すり減った金属
       ((maxoctaves  float) 6.0)   ; turbulence のオクターブ数
       ((shadingfreq float) 1.0)   ; 凹みの周波数 (ワールド単位あたり)
       )

  (enter (((pp   point) (make-point 0 0 0))
          ((famp float) 1.0)
          ((turb float) 0.0)
          ((j    float) 0.0)
          ((h    float) 0.0))

    ;; turbulence: Σ 0.5^i · |2·noise(p·2^i) − 1|
    (setvar pp (* P shadingfreq))
    (setvar famp 1.0)
    (setvar turb 0.0)
    (repeat (j maxoctaves)
      (setvar turb (+ turb (* famp (abs (- (* 2.0 (noise pp)) 1.0)))))
      (setvar famp (* famp 0.5))
      (setvar pp (* pp 2.0)))

    ;; magnitude = pow(turb/(2·freq), power) — [0,1] に収まる (turb ≤ 2)
    (setvar h (pow (clamp (/ turb (* 2.0 shadingfreq)) 0.0 1.0) power))

    ;; 内側に掘る (原典の -Km·magnitude)
    (setvar disp (- 0.0 h))
)))

(compile-shader dented-shader)
(append-shader dented-shader)
