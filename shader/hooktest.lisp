;;; hooktest.lisp — distance / min / max フック修正 (2026-08-03) の回帰テスト
;;;   distance: format ディレクティブ欠落で第2引数が捨てられ1引数Cコールになっていた
;;;   min/max:  objリスト直印字+クラス名印字+閉じ括弧不足で C が壊れていた
;;; 期待値: 全画素 0.74 (= 0.10*distance((0,0,0),(3,4,0)) + 0.25*min(0.7,0.4,0.9)
;;;                       + 0.40*max(0.1,0.35,0.2) = 0.5 + 0.1 + 0.14)。
;;; 狂ったら interface/shader.lisp の distance-hook / min-hook / max-hook を疑う。
(setq hooktest-shader
(make-shader hooktest :keyword :surface
  (((dummy float) 0))
  (enter (((pa point) (make-point 0 0 0))
          ((pb point) (make-point 3 4 0))
          ((dd float) (distance pa pb))
          ((mn float) (min 0.7 0.4 0.9))
          ((mx float) (max 0.1 0.35 0.2))
          ((vv float) 0))
    (setvar vv (+ (+ (* 0.10 dd) (* 0.25 mn)) (* 0.40 mx)))
    (setvar Oi Os)
    (setvar Ci (make-color vv vv vv)))))
(compile-shader hooktest-shader)
(append-shader hooktest-shader)
