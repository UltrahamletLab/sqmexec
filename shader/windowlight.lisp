;;; windowlight
;;; Window light shader with crossbars.
;;;
;;; Converted from:
;;;   windowlight.sl + patterns.h (BMRT)
;;;   (c) 1990-2000 Exluna, Inc. / Larry Gritz
;;;
;;; RSL filteredpulse(e0,e1,x,dx):
;;;   max(0, (min(x+dx/2, e1) - max(x-dx/2, e0)) / dx)
;;;   Approximated with smoothstep in DR:
;;;   smoothstep(e0, e0+fuzz, x) - smoothstep(e1-fuzz, e1, x)
;;;
;;; Bounds check (if offset>0 && offset/size < npanes):
;;;   Replaced with smoothstep-based clamp multiplier.
;;;
;;; mix(a, b, t) for colors works in DR natively.

(setq windowlight-shader

(make-shader windowlight :keyword :light
      (((intensity   float)  1.0)
       ((light-color color)  (make-color 1.0 0.90 0.60))
       ((dark-color  color)  (make-color 0.05 0.15 0.10))
       ((from        point)  (make-point 0 0 0))
       ((to          point)  (make-point 0 1 0))
       ((center      point)  (make-point 0 0 0))
       ((up          point)  (make-point 0 0 1))   ; window's up direction
       ((in          point)  (make-point 0 1 0))   ; window's inward-facing normal
       ((hpanes      float)  2.0)
       ((vpanes      float)  3.0)
       ((panewidth   float)  6.0)
       ((paneheight  float)  6.0)
       ((framewidth  float)  0.1)
       ((frameheight float)  0.1)
       ((fuzz        float)  0.25))

  (enter (
    ;; --- Coordinate frame ---
    ;; path = normalize(to - from)  ← DR solar direction: light travels from→to
    ;;   RSL 原典の path は (from - to) で solar(-path,0) なので向きは同一。
    ((path  point) (normalize (- to from)))
    ;; inv = faceforward(normalize(in), from - to)
    ;;   原典 in2 = faceforward(normalize(in), path_rsl)。in が光の進行方向を向くよう
    ;;   自動で反転する = シーン側で in の符号を間違えても窓が裏返らない。
    ((inv   point) (faceforward (normalize in) (- from to)))
    ;; right = cross(up, inv)  [tentative]
    ((right-tmp point) (cross up inv))
    ;; upv = normalize(cross(inv, right))
    ((upv   point) (normalize (cross inv right-tmp)))
    ;; right = cross(upv, inv)  [corrected]
    ((right point) (cross upv inv))

    ;; --- Derived constants ---
    ((path-dot-inv  float) (dot path inv))
    ((half-vh float) (* paneheight (* 0.5 vpanes)))
    ((half-hw float) (* panewidth  (* 0.5 hpanes)))
    ((max-yoff float) (* paneheight vpanes))
    ((max-xoff float) (* panewidth  hpanes))
    ;; 窓の左下隅 (原典 corner = center - right*xorder*panewidth/2
    ;;                              - up2*yorder*paneheight/2)
    ((corner point) (- (- center (* right half-hw)) (* upv half-vh)))

    ;; --- Per-pane edge values ---
    ((ya float) (* 0.5 frameheight))
    ((yb float) (- paneheight (* 0.5 frameheight)))
    ((xa float) (* 0.5 framewidth))
    ((xb float) (- panewidth  (* 0.5 framewidth)))

    ;; Placeholder vars (set in solar block)
    ((d      float) 0.0)
    ((PLx    float) 0.0)
    ((PLy    float) 0.0)
    ((PLz    float) 0.0)
    ((PL     point) (make-point 0 0 0))
    ((PLc    point) (make-point 0 0 0))   ; PL - center
    ((yoff   float) 0.0)
    ((xoff   float) 0.0)
    ((ymod   float) 0.0)
    ((xmod   float) 0.0)
    ((yfract float) 0.0)
    ((xfract float) 0.0)
    ((yin    float) 0.0)
    ((xin    float) 0.0)
    ((side   float) 0.0)
    ((outd   float) 0.0)
    ((blend  float) 0.0))

  (solar (path 0)
    ;; d = inv . (P - center)
    (setvar d (dot inv (- P center)))

    ;; PL = P - path * (d / (path . inv))
    (setvar PL (- P (* path (/ d path-dot-inv))))
    (setvar PLc (- PL center))

    ;; Y offset on window grid
    (setvar yoff (+ (dot PLc upv) half-vh))

    ;; X offset on window grid
    (setvar xoff (+ (dot PLc right) half-hw))

    ;; filteredpulse for Y: smoothstep(ya, ya+fuzz) - smoothstep(yb-fuzz, yb)
    (setvar ymod   (mod yoff paneheight))
    (setvar yfract (- (smoothstep ya (+ ya fuzz) ymod)
                      (smoothstep (- yb fuzz) yb ymod)))

    ;; bounds check Y: 0..max-yoff
    (setvar yin (* (smoothstep 0.0 fuzz yoff)
                   (- 1.0 (smoothstep (- max-yoff fuzz) max-yoff yoff))))
    (setvar yfract (* yfract yin))

    ;; filteredpulse for X
    (setvar xmod   (mod xoff panewidth))
    (setvar xfract (- (smoothstep xa (+ xa fuzz) xmod)
                      (smoothstep (- xb fuzz) xb xmod)))

    ;; bounds check X: 0..max-xoff
    (setvar xin (* (smoothstep 0.0 fuzz xoff)
                   (- 1.0 (smoothstep (- max-xoff fuzz) max-xoff xoff))))
    (setvar xfract (* xfract xin))

    ;; --- 屋外判定 (原典: if (path.PtoC <= 0) xfract = yfract = 1) ---
    ;; PtoC = corner - Ps, path_rsl = from - to なので
    ;;   path_rsl・(corner - P) <= 0  ⟺  path・(P - corner) <= 0
    ;; = P が窓面より光源側 (屋外) → 桟に遮られず全面照明。
    ;; DSL の if は使わず smoothstep で滑らかに切り替える。
    (setvar side (dot path (- P corner)))
    (setvar outd (- 1.0 (smoothstep 0.0 fuzz side)))

    ;; blend = mix(yfract*xfract, 1, outd)
    (setvar blend (+ outd (* (- 1.0 outd) (* yfract xfract))))

    ;; Cl = intensity * mix(darkcolor, lightcolor, blend)
    (setvar Cl (* intensity (mix dark-color light-color blend)))))))

(compile-shader windowlight-shader)
(append-shader windowlight-shader)
