;;; dfprod — blob deform の DSL 模様: 積 sin·sin·sin (解析 mode 0 の複製)
;;;
;;; 用途は dfgyroid / dfridge と同じく **検証用の基準線**。
;;; mode 0 は `(deform amp freq phase)` で mode を省略したときの**既定値**であり、
;;; 実際のシーンで使われている deform blob のほぼ全てがこれ (1062/1080)。
;;; にもかかわらず DSL 複製が無く、Lipschitz 中点包囲が**一番使われている模様に対して
;;; 一度も検証されていない**穴が空いていた (2026-08-01)。それを埋めるためのもの。
;;;
;;; 積は和 (mode 1) や gyroid (mode 2) と勾配の分布が違う: 3つの sin の積なので
;;; 大半の領域で値が 0 近くに潰れ、格子の交点付近だけが立つ。包囲の緩みが効く場所が
;;; 他のモードとずれるため、ここを通しておく意味がある。
;;;
;;;   g = sin(f·x+ph) · sin(f·y+ph) · sin(f·z+ph)
;;;
;;; Lipschitz (厳密):
;;;   ∂g/∂x = f·cos(f·x+ph)·sy·sz   →  |∂g/∂x| <= f   (各成分同様)
;;;   |∇g| = f·√(cx²sy²sz² + sx²cy²sz² + sx²sy²cz²) <= √3·f ≈ 1.733·f
;;;   → (lipschitz (* 1.74 freq)) を書けば安全側。
;;;
;;; 使い方 (シーン):
;;;   (deform (mode dsl)(shader dfprod)(amp 0.30)(lipschitz 15.6)
;;;           (param freq 9.0)(param phase 0.0))
;;;   ↑ これは (deform 0.30 9.0 0) および (deform 0.30 9.0 0 0) と同じ絵になる。

(setq dfprod-shader

(make-shader dfprod :keyword :displacement
      (((freq  float) 3.0)     ; 空間周波数 (ローカル座標)
       ((phase float) 0.0))    ; 位相オフセット

  (enter (((sx float) 0.0) ((sy float) 0.0) ((sz float) 0.0))

    (setvar sx (sin (+ (* freq (xcomp P)) phase)))
    (setvar sy (sin (+ (* freq (ycomp P)) phase)))
    (setvar sz (sin (+ (* freq (zcomp P)) phase)))

    (setvar disp (* (* sx sy) sz))
)))

(compile-shader dfprod-shader)
(append-shader dfprod-shader)
