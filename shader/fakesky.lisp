;;; fakesky
;;; Fake sky shader — altitude-based blue gradient on a sphere dome.
;;;
;;; Converted from RenderMan SL fakesky.sl (BMRT 版と式同一 — 2026-08-09 比較確認)
;;; DynamicRender Lisp conversion: 2026
;;;
;;; 2026-08-09: BMRT fakesky.sl の移植依頼で再確認 — 式は完全に同一のため本版を残す。
;;;   既定 up は原典の z-up (0,0,1) を sqm の y-up (0,1,0) に適応済み (意図的)。
;;;   max(0,d) の (d+|d|)/2 は max フックが壊れていた時代 (〜2026-08-03) の回避策
;;;   だったので (max 0.0 d) に現代化 (値はビット等価・balloon_dog で一致確認)。
;;;   あわせて build-all.lisp 未登録 (フルリビルドで core から落ちる) を解消。
;;;
;;; Place on a large sphere enclosing the scene.
;;; up = world-space up vector (default Y-up).
;;; Brightness = 0.5 at horizon, 1.0 at zenith.

(setq fakesky-shader

(make-shader fakesky :keyword :surface
      (((up       point) (make-point 0 1 0))
       ((skycolor color) (make-color 0.5 0.6 1.0)))

  (enter (
    ((Nf    point) (make-point 0 0 0))
    ((d     float) 0.0)
    ((dc    float) 0.0))

    ;; d = dot(up, normalize(N)) — altitude factor
    (setvar Nf (normalize N))
    (setvar d  (dot up Nf))

    (setvar dc (max 0.0 d))

    (setvar Oi Os)
    (setvar Ci (* Os (* 1.8 skycolor) (+ 0.5 (* 0.5 dc)))))))

(compile-shader fakesky-shader)
(append-shader fakesky-shader)
