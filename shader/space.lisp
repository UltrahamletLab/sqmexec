;;; space.lisp — 宇宙空間ドームシェーダー (全球対応)
;;;
;;; シーンを囲む大球の内側に貼る。上下全方向に星が広がり、
;;; 任意の方向に太陽ディスク + グローを描く。
;;;
;;; パラメータ定義順 (shade_dr.c の space_params[] と一致必須):
;;;   Ka=0 star-density=1 star-sharp=2 star-brightness=3
;;;   sun-dir=4 sun-color=5 sun-size=6 sun-glow=7 sun-intensity=8

(setq space-shader
(make-shader space :keyword :surface
  (((Ka             float) 0.0)
   ((star-density   float) 80.0)   ; ノイズ周波数 (大=星が多く小さい)
   ((star-sharp     float) 40.0)   ; 星の点鋭さ (大=シャープ)
   ((star-brightness float) 3.0)   ; 星の輝度スケール
   ((sun-dir        point) (make-point 0.6 0.3 -0.5))
   ((sun-color      color) (make-color 1.00 0.95 0.85))
   ((sun-size       float) 2000.0) ; 太陽ディスクの鋭さ
   ((sun-glow       float) 5.0)    ; グロー減衰指数
   ((sun-intensity  float) 3.0))   ; 太陽の輝度スケール
  (enter (
    ((dir   point) (normalize N))
    ((sd    point) (normalize sun-dir))
    ((mu    float) 0)
    ((sn1   float) 0) ((sn2 float) 0) ((stars float) 0)
    ((sundisk float) 0) ((glow float) 0)
    ((scol  color) (make-color 0 0 0))
    ((col   color) (make-color 0 0 0)))

  ;; ── 星フィールド: ノイズを高周波でサンプルし、べき乗で点化 ──
  ;; [0,1] に正規化してから sharp 乗 → 峰だけが輝く点星になる
  (setvar sn1 (* 0.5 (+ 1.0 (noise (* dir star-density)))))
  (setvar sn1 (pow sn1 star-sharp))

  ;; 低周波レイヤ: 少数の明るい大きめの星
  (setvar sn2 (* 0.5 (+ 1.0 (noise (* dir (* 0.35 star-density))))))
  (setvar sn2 (pow sn2 (* 0.7 star-sharp)))

  (setvar stars (* star-brightness (+ sn1 (* 0.4 sn2))))

  ;; 星に微妙な色温度差 (青白い星 / 暖色の星)
  (setvar scol (make-color (* stars 0.90) (* stars 0.92) (* stars 1.10)))

  ;; ── 背景: ほぼ黒い宇宙空間 ──
  (setvar col (make-color 0.003 0.003 0.010))
  (setvar col (+ col scol))

  ;; ── 太陽ディスク + グロー ──
  (setvar mu (clamp (dot dir sd) 0 1))
  (setvar sundisk (pow mu sun-size))
  (setvar glow    (pow mu sun-glow))
  (setvar col (+ col (* sun-color (* sun-intensity (+ sundisk (* 0.25 glow))))))

  (setvar Oi Os)
  (setvar Ci (* Oi col))
)))

(compile-shader space-shader)
(append-shader space-shader)
