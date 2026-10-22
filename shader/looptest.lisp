;;; looptest.lisp — DSL の WHILE ループ検証 (2026-08-03)
;;; 眠っていた special form WHILE で fbm をループ実装できるか確かめる。
;;; body は複文可 / テスト式は「純粋式」(変数比較) のみ安全。
(setq looptest-shader
(make-shader looptest :keyword :surface
  (((Kd float) 0.9)
   ((octaves float) 4.0)
   ((freq float) 3.0))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((acc float) 0)
          ((amp float) 0.5)
          ((ff float) 1.0)
          ((oct float) 0))
    (while (< oct octaves)
      (setvar acc (+ acc (* amp (vnoise (* Pg ff freq)))))
      (setvar amp (* amp 0.5))
      (setvar ff (* ff 2.02))
      (setvar oct (+ oct 1)))
    (setvar Oi Os)
    (setvar Ci (* Oi Cs Kd acc (diffuse Nf))))))
(compile-shader looptest-shader)
(append-shader looptest-shader)
