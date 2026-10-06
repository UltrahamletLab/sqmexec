;;; hologram.lisp — SF風ホログラム投影 (自己発光・走査線・リムグロー・グリッチ)
;;;
;;; 「ライトに依存せず自ら光る半透明の投影体」を狙う。透過はDRシェーダーだと屈折
;;; レイがblob内部で死んで暗くなるだけなので、見た目の透け感は *リムグロー優位の
;;; 自己発光* で作る (中心は淡く、シルエットほど強く光る = 幽霊的なホログラム)。
;;;   - 走査線: 世界Yの正弦で水平の縞。scan-phase でスクロール (CRT/投影線)
;;;   - リムグロー: フレネルでシルエットを glow-color に持ち上げ (透け感の核)
;;;   - グリッチ: 走査線ブロック単位のランダム明滅 + 全体フリッカ (scan-phase駆動)
;;;   - 回折の虹: 視線依存の薄い虹を holo-color に混ぜる (iridescent 流)
;;;   - emission: 全体の自己発光強度。ライト非依存なので影の中でも光る
;;;
;;; パラメータ定義順 (shade_dr.c の hologram_params[] と一致必須, 最大16):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 holo-color=4 glow-color=5 scan-freq=6
;;;   scan-phase=7 scan-sharp=8 rim-power=9 rim-boost=10 flicker=11
;;;   rainbow=12 emission=13

(setq hologram-shader
(make-shader hologram :keyword :surface
  (((Ka float) 0.10) ((Kd float) 0.25) ((Ks float) 0.40) ((roughness float) 0.05)
   ((holo-color color) (make-color 0.20 0.85 1.00))   ; ベースのシアン
   ((glow-color color) (make-color 0.70 1.00 1.00))   ; 走査線/リムの明色
   ((scan-freq  float) 26.0)    ; 走査線の密度 (世界Y)
   ((scan-phase float) 0.0)     ; 走査線スクロール + 明滅の位相 (アニメ用)
   ((scan-sharp float) 0.55)    ; 走査線のコントラスト (0..1)
   ((rim-power  float) 2.4)     ; フレネル指数 (大=縁が細い)
   ((rim-boost  float) 1.8)     ; リムグロー強度
   ((flicker    float) 0.35)    ; グリッチ/明滅量
   ((rainbow    float) 0.28)    ; 回折の虹 (視線依存)
   ((emission   float) 1.4))    ; 自己発光の全体強度
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((fres float) 0) ((rim float) 0)
    ((py float) 0) ((scan float) 0) ((band float) 0)
    ((gl float) 0) ((flk float) 0)
    ((phase float) 0) ((rr float) 0) ((gg float) 0) ((bb float) 0)
    ((base color) (make-color 0 0 0))
    ((rbow color) (make-color 0 0 0))
    ((emit color) (make-color 0 0 0)))
  ;; --- フレネル/リム: 正面=0, 縁=1 ---
  (setvar fres (- 1 (clamp (dot Nf Ir) 0 1)))
  (setvar rim (pow fres rim-power))
  ;; --- 走査線 (世界Yの正弦, scan-phase でスクロール) ---
  (setvar py (ycomp Pg))
  (setvar scan (+ 0.5 (* 0.5 (sin (- (* scan-freq py) (* scan-phase 6.2832))))))
  (setvar band (- 1 (* scan-sharp (- 1 scan))))
  ;; --- グリッチ: 走査線ブロック単位の明滅 + 全体フリッカ ---
  (setvar flk (- 1 (* flicker (noise (make-point (floor (* py 6)) (* scan-phase 3) 0.5)))))
  (setvar flk (* flk (- 1 (* 0.4 flicker (noise (make-point (* scan-phase 5) 1.7 0.3))))))
  ;; --- 回折の虹 (視線依存, RGBを120度位相シフト) ---
  (setvar phase (+ (* 8 fres) (* 4 (noise (* 1.5 Pg)))))
  (setvar rr (+ 0.5 (* 0.5 (sin phase))))
  (setvar gg (+ 0.5 (* 0.5 (sin (+ phase 2.0944)))))
  (setvar bb (+ 0.5 (* 0.5 (sin (+ phase 4.1888)))))
  (setvar rbow (make-color rr gg bb))
  ;; --- ベース色: holo に虹を少量, リムで glow へ ---
  (setvar base (mix holo-color rbow rainbow))
  (setvar base (mix base glow-color (clamp (* rim-boost rim) 0 1)))
  ;; --- 自己発光合成: 走査線 * フリッカ * (1+リム持ち上げ) ---
  (setvar gl (* band flk (+ 1 (* rim-boost rim))))
  (setvar emit (* emission gl base))
  ;; 微かな diffuse 形状 + 走査線のきらめきスペキュラ
  (setvar Oi Os)
  (setvar Ci (* Oi (+ emit
                      (* Kd holo-color (diffuse Nf) 0.3)
                      (* Ks glow-color (specular Nf Ir roughness))))))))

(compile-shader hologram-shader)
(append-shader hologram-shader)
