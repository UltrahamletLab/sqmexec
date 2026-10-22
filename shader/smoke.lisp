;;; smoke
;;; Volume smoke shader using trapezoidal ray-marching integration.
;;;
;;; Converted from:
;;;   smoke.sl (BMRT) (c) 1990-2000 Exluna, Inc. / Larry Gritz
;;;
;;; DR adaptations:
;;;   - illuminance → smoke-color param (no per-light gather in DR volumes)
;;;   - snoise/fBm  → noise stacked manually (smokeoctaves は現状 2 固定 — 既存絵の互換)
;;;   - colorexp    → inlined
;;;
;;; 2026-08-09 (BMRT smoke.sl 再突き合わせ):
;;;   - min/max の abs 恒等式は**フック壊れ時代 (〜2026-08-03) の遺物** → 現代化
;;;     (値は厳密等価 — smoke_column でビット一致確認)。
;;;   - 原典の **scatter (チャンネル別消散色)** を末尾追加で復元。既定 (1,1,1) =
;;;     従来のスカラー消散とビット一致。空の色は (param scatter 1 2.25 21) —
;;;     青が強く消散 = 透過が赤く、散乱寄与が青く(レイリー風)。
;;;     ※ sqm の atmosphere は Ci しか読み戻さないが、(1-Ov)·Ci の透過が
;;;       チャンネル別になるので効果は出る。

(setq smoke-shader

(make-shader smoke :keyword :volume
      (((opacdensity  float) 1.0)
       ((lightdensity float) 1.0)
       ((integstart   float) 0.0)
       ((integend     float) 100.0)
       ((stepsize     float) 0.5)
       ((smoke-color  color) (make-color 0.75 0.75 0.75))
       ((smokefreq    float) 1.0)
       ((smokeoctaves float) 0.0)
       ((smokevary    float) 1.0)
       ((scatter      color) (make-color 1 1 1)))   ; チャンネル別消散 (空=1,2.25,21)

  (enter (
    ;; Ray setup
    ((WIN     point) (normalize I))
    ((ray-len float) (length I))

    ((end     float) (- (min ray-len integend) 0.0001))
    ((Worigin point) (+ P (- I)))     ; camera = P - I

    ((span    float) (- end integstart))
    ((ss0     float) (min stepsize span))

    ;; Mutable loop variables
    ((d        float) integstart)
    ((ss       float) ss0)
    ((Cv       color) (make-color 0 0 0))
    ((Ov       color) (make-color 0 0 0))     ; チャンネル別 (scatter 対応)

    ;; Per-step reuse vars
    ((Pcur     point) (make-point 0 0 0))
    ((Psmoke   point) (make-point 0 0 0))
    ((dens     float) 0.0)
    ((last-dens float) 0.0)
    ((tau      float) 0.0)
    ((one-ov   color) (make-color 1 1 1))
    ((ext      color) (make-color 0 0 0))
    ((n1       float) 0.0)
    ((n2       float) 0.0)
    ((snv      float) 0.0)
    ((rem      float) 0.0)   ; remaining = end - d
    ((ss-hi    float) 0.0))

  ;; --- Initial sample at d=integstart ---
  (setvar Pcur   (+ Worigin (* WIN d)))
  (setvar Psmoke (* Pcur smokefreq))
  (setvar n1  (noise Psmoke))
  (setvar snv (* smokevary (- (* 2.0 n1) 1.0)))
  (setvar n2  (noise (* Psmoke 2.0)))
  (setvar snv (+ snv (* 0.5 (- (* 2.0 n2) 1.0))))
  (setvar last-dens (clamp (+ 0.5 (* 0.5 snv)) 0.0 1.0))

  ;; --- Ray march ---
  (while (< d end)
    ;; ss = clamp(ss, 0.005, end-d)
    (setvar rem (- end d))
    (setvar ss (min (max ss 0.005) rem))

    (setvar d (+ d ss))

    ;; Sample at new position
    (setvar Pcur   (+ Worigin (* WIN d)))
    (setvar Psmoke (* Pcur smokefreq))
    (setvar n1  (noise Psmoke))
    (setvar snv (* smokevary (- (* 2.0 n1) 1.0)))
    (setvar n2  (noise (* Psmoke 2.0)))
    (setvar snv (+ snv (* 0.5 (- (* 2.0 n2) 1.0))))
    (setvar dens (clamp (+ 0.5 (* 0.5 snv)) 0.0 1.0))

    ;; tau = opacdensity * ss/2 * (dens + last-dens)
    (setvar tau (* opacdensity (* (* 0.5 ss) (+ dens last-dens))))
    (setvar one-ov (- 1.0 Ov))
    ;; ext = 1 - colorexp(-tau·scatter)  (チャンネル別消散)
    (setvar ext (make-color (- 1.0 (exp (- (* tau (comp scatter 0)))))
                            (- 1.0 (exp (- (* tau (comp scatter 1)))))
                            (- 1.0 (exp (- (* tau (comp scatter 2)))))))

    ;; Cv += (1-Ov) * lightdensity * tau * smoke-color
    (setvar Cv (+ Cv (* (* one-ov (* lightdensity tau)) smoke-color)))
    ;; Ov += (1-Ov) * (1 - colorexp(-tau·scatter))
    (setvar Ov (make-color (clamp (+ (comp Ov 0) (* (comp one-ov 0) (comp ext 0))) 0.0 1.0)
                           (clamp (+ (comp Ov 1) (* (comp one-ov 1) (comp ext 1))) 0.0 1.0)
                           (clamp (+ (comp Ov 2) (* (comp one-ov 2) (comp ext 2))) 0.0 1.0)))

    (setvar last-dens dens))

  ;; --- Composite ---
  (setvar one-ov (- 1.0 Ov))
  (setvar Ci (+ Cv (* one-ov Ci)))
  (setvar Oi (+ Ov (* one-ov Oi))))))

(compile-shader smoke-shader)
(append-shader smoke-shader)
