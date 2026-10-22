;;; bsdfwine — 赤ワイン: 光路長で色が深まる半透明液体 (PT -Q 材質, 2026-08-02)
;;;
;;; I ブリッジの**距離情報**の本命実証。I = 前のパス頂点→P の全長ベクトルなので、
;;; 液体の射出面 (内側からのヒット) では **|I| = 液体内部の光路長そのもの**。
;;; Beer-Lambert をチャンネル毎に適用する:
;;;   T_k = exp(−absorb_k · L)     (L = 内部光路長)
;;;   Cl = T                        (透過ティント: t=−IOR のオプトインで
;;;                                  Dielectric の透過 beta に Cl が乗る)
;;;   transmission ≈ 0.97 (澄んだ液体) — 拡散枝はごく僅かで、直進透過が
;;;   光路長ぶん染まる。→ 薄い縁は明るい透けた赤、厚い胴は深く沈んだ赤。
;;; ※ 透過ティント機構は同日エンジン追加 (path_trace.cpp / shade_dr.cpp io[10])。
;;;   t≥0 の既存材質は従来どおり無色透過 (ビット一致)。
;;;
;;; 内外判定: dot(N̂g, I) > 0 = 内側から当たった射出面 (I は視点→面の向き)。
;;; 入射面 (外から) は L=0 扱い = ほぼ素通し (吸収は射出面ヒットでまとめて払う)。
;;; |I|=0 (SPPM/BDPT/VCM) の退避: trans=0.6 / wine-color の一様な半透明。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color 0.75 0.10 0.14) (kd 1) (bsdf bsdfwine)
;;;            (param wine-color 0.80 0.09 0.12)
;;;            (param absorb-r 0.35) (param absorb-g 3.0) (param absorb-b 3.6)
;;;            (param entry-trans 0.96) (param ior 1.33) (param rough 0.04))

(setq bsdfwine-shader

(make-shader bsdfwine :keyword :volume
      (((absorb-r float) 0.30)   ; 吸収係数 /単位長 (赤は生き残る)
       ((absorb-g float) 2.6)
       ((absorb-b float) 3.2)
       ((clarity float) 0.97)    ; transmission (澄み。残りが拡散の濁り)
       ((ior   float) 1.33)
       ((rough float) 0.04))

  ;; ※ローカル名は SGV グローバル (u v s t N P L I E ..) と衝突不可 — L は不可!
  (enter (((ln float) 0.0) ((vd float) 0.0)
          ((inw float) 0.0) ((pl float) 0.0)
          ((wtr float) 0.0) ((wtg float) 0.0) ((wtb float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))

    ;; 射出面 (内側からのヒット) か: dot(N̂g, I) > 0
    (setvar inw (smoothstep 0.0 0.0000001
                  (dot (normalize Ng) I)))
    (setvar pl (* ln inw))

    (setvar wtr (exp (- 0.0 (* absorb-r pl))))
    (setvar wtg (exp (- 0.0 (* absorb-g pl))))
    (setvar wtb (exp (- 0.0 (* absorb-b pl))))

    ;; Cl = チャンネル毎透過率 (射出面で光路長ぶんの吸収を一括して払う)。
    ;; |I|=0 (双方向系) は薄赤の固定ティントに退避
    (setvar Cl (mix (make-color 0.85 0.30 0.35)
                    (make-color wtr wtg wtb) vd))
    (setvar Oi (make-color rough 0.0 clarity))
    ;; 負の IOR = 透過ティントのオプトイン (s は DSL で書き込み禁止のため
    ;; t の符号に畳む規約。エンジン側 shade_dr.cpp io[10])
    (setvar t (- 0.0 ior))
)))

(compile-shader bsdfwine-shader)
(append-shader bsdfwine-shader)
