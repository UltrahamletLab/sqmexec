;;; loopext.lisp — ループ拡張3点 (2026-08-03) の回帰テスト
;;;   ①テスト式の関数呼び出し (毎周再評価 — 旧 eval-while なら凍結ハング)
;;;   ②(repeat (j N) body..) 糖衣  ③(break)
;;; 期待値: 中心画素 0.96 (=0.03*27+0.05*3)。狂ったら interface/shader.lisp の
;;; eval-while / eval-repeat / BREAK を疑う。
(setq loopext-shader
(make-shader loopext :keyword :surface
  (((dummy float) 0))
  (enter (((ii float) 0) ((cnt float) 0) ((j float) 0) ((vv float) 0))
    ;; (a) 関数入りテスト式: sqrt を毎周再評価 (旧実装なら凍結→無限ループ)
    ;;     ii: 0,3,..,24→27 で停止 (sqrt(27)=5.196>=5)。ii=27
    (while (< (sqrt ii) 5)
      (setvar ii (+ ii 3)))
    ;; (b) repeat + break: j>2.5 で break → cnt=3
    (repeat (j 8)
      (if (> j 2.5) (break))
      (setvar cnt (+ cnt 1)))
    ;; 期待値 vv = 0.03*27 + 0.05*3 = 0.96
    (setvar vv (+ (* 0.03 ii) (* 0.05 cnt)))
    (setvar Oi Os)
    (setvar Ci (make-color vv vv vv)))))
(compile-shader loopext-shader)
(append-shader loopext-shader)
