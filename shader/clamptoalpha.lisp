;;; clamptoalpha — Ci を [0, alpha] にクランプする imager シェーダー
;;;
;;; 移植元: BMRT clamptoalpha.sl
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;;   imager clamptoalpha () { Ci = clamp (Ci, color 0, color alpha); }
;;;
;;; premultiplied-alpha 合成の前提 (各成分 ≤ α) を最終画像に強制する。
;;; RenderMan では合成用出力の整合性担保が目的。
;;;
;;; ── sqm での意味 ────────────────────────────────────────────────
;;; :imager クラス (2026-08-09 新設)。alpha = 画素の被覆率 (pix.col[3]):
;;;   前景で埋まった画素 = 1 → クランプは実質無効 (出力段の [0,1] クランプと同じ)
;;;   背景画素          = 0 → **黒に落ちる** (シーンの背景色を消す)
;;;   AA のエッジ画素    = 端数 → 被覆率に比例して暗くなる
;;; つまり「前景だけを黒地に premultiplied で焼く」後処理になる。合成素材の
;;; 書き出し向け (sqm の PNG は 3ch なので α 自体は出ない — 全画素 α=1 の
;;; 黒地 premultiplied として扱えば外部合成できる)。
;;;
;;; ※ パストレーシング (-Q/-U/-J) は被覆率を常に 1 で返すので**効かない**
;;;   (background.lisp と同じ制限)。
;;;
;;; パラメータ無し → C 側のテーブルも不要 (imager は _sym_ 解決)。
;;; シーン記法:  (imager (shader clamptoalpha))

(setq clamptoalpha-shader

(make-shader clamptoalpha :keyword :imager
      ()

  (enter ()
    (setvar Ci (make-color (clamp (comp Ci 0) 0.0 alpha)
                           (clamp (comp Ci 1) 0.0 alpha)
                           (clamp (comp Ci 2) 0.0 alpha))))))

(compile-shader clamptoalpha-shader)
(append-shader clamptoalpha-shader)
