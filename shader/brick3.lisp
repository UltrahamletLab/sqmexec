;;; brick3 - cylindrical brick shader (Y-axis)
;;; Horizontal: atan2(Pz, Px) — angle around Y axis, wraps continuously
;;; Vertical:   world Py — uniform brick rows at constant Y levels
;;; Seam: one vertical line at the back (Px<0, Pz=0)

(setq brick3-shader
(make-shader brick3 :keyword :surface
      (
        ((Kd float) 0.80)
        ((Ka float) 0.25)
        ((Ks float) 0.20)
        ((roughness float) 0.05)
        ((Cbrick color) (make-color 0.76 0.24 0.10))
        ((Cmortar color) (make-color 0.80 0.76 0.70))
        ((HBRICKS float) 12)      ; bricks around circumference
        ((BRICKHEIGHT float) 0.18) ; brick height in world units
        ((MORTARFRAC float) 0.08)  ; mortar as fraction of brick size
       )
  (enter (
          ((NN point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ;; world position components
          ((Px float) (xcomp Pg))
          ((Py float) (ycomp Pg))
          ((Pz float) (zcomp Pg))
          ;; cylindrical angle around Y
          ((theta float) 0)
          ((sign_pz float) 0)
          ;; brick pattern
          ((BMHEIGHT float) (+ BRICKHEIGHT (* BRICKHEIGHT MORTARFRAC)))
          ((MWF float) (* MORTARFRAC 0.5))
          ((MHF float) (* MORTARFRAC 0.5))
          ((ss float) 0) ((tt float) 0)
          ((sbrick float) 0) ((tbrick float) 0)
          ((w float) 0) ((h float) 0)
          ((Ct color) Cs)
          )

        ;; ── atan2(Pz, Px): angle around Y axis ──────────────────
        (setvar theta (atan (/ Pz (+ (abs Px) 0.0001))))
        (setvar sign_pz (- (* 2 (step 0 Pz)) 1))
        (if (< Px 0)
            (setvar theta (- (* sign_pz PI) theta)))

        ;; ── cylindrical UV ───────────────────────────────────────
        ;; ss: 0..HBRICKS around full circumference
        (setvar ss (+ (* theta (/ HBRICKS (* 2 PI))) (* HBRICKS 0.5)))
        ;; tt: world Y / brick height (uniform rows)
        (setvar tt (/ Py BMHEIGHT))

        ;; ── brick pattern ────────────────────────────────────────
        (if (> (mod (* tt 0.5) 1) 0.5)
            (setvar ss (+ ss 0.5)))
        (setvar sbrick (floor ss))
        (setvar tbrick (floor tt))
        (setvar ss (- ss sbrick))
        (setvar tt (- tt tbrick))
        (setvar w (- (step MWF ss) (step (- 1 MWF) ss)))
        (setvar h (- (step MHF tt) (step (- 1 MHF) tt)))
        (setvar Ct (mix Cmortar Cbrick (* w h)))

        ;; ── shading ──────────────────────────────────────────────
        (setvar Oi Os)
        (setvar Ci (* Oi (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse NN))))
                            (* Ks (specular NN Ir roughness)))))
)))

(compile-shader brick3-shader)
(append-shader brick3-shader)
