;;; veinedmarble.lisp — procedural veined marble derived from veinedmarble.sl.
;;; 2026-08-09: BMRT 原典と再突き合わせ — 本版は sin 縞の翻案 (地層風)。原典の
;;;   **3D 鉱脈ネットワーク** (|snoise| 閾値化 + (1-turbsum) 合成 + freq×3 縦列 —
;;;   gmarbtile_polish に移植した式と同族) を (param network 1) の opt-in で追加。
;;;   既定 0 = 従来の sin 縞 (suite の絵を変えない)。

(setq veinedmarble-shader
(make-shader veinedmarble :keyword :surface
  (((Ka float) 0.5) ((Kd float) 0.8) ((Ks float) 0.4)
   ((roughness float) 0.075) ((specularcolor color) (make-color 1 1 1))
   ((veinfreq float) 1.0) ((veinlevels float) 2.0)
   ((warpfreq float) 1.0) ((warping float) 0.5)
   ((veincolor color) (make-color 0.6 0.5 0.1)) ((sharpness float) 8.0)
   ((network float) 0.0))
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Vdir point) (normalize (- I))) ((pp point) Pg)
          ((warp float) 0.0) ((phase float) 0.0) ((vein float) 0.0)
          ((lev float) 0.0) ((freq float) 1.0) ((amp float) 1.0)
          ((marble color) (make-color 1 1 1)))
    (if (< network 0.5)
        ;; ── 従来: sin 縞 (地層風) ──
        (progn
          (setvar warp (* warping (- (* 2.0 (turbulence (* pp warpfreq) 5)) 1.0)))
          (setvar phase (+ (* veinfreq (+ (xcomp pp) (* 0.35 (zcomp pp)))) warp))
          (while (< lev veinlevels)
            (setvar vein (+ vein (* amp (pow (clamp (- 1.0 (abs (sin (* phase freq)))) 0 1) sharpness))))
            (setvar freq (* freq 2.0))
            (setvar amp (* amp 0.5))
            (setvar lev (+ lev 1.0))))
        ;; ── 原典: 3D 鉱脈ネットワーク (ドメインワープ + |snoise| 閾値化) ──
        (progn
          ;; PP += 0.5 * vfBm(PP, 6oct)  — 3成分は w_pnoisep 式のオフセット
          (setvar amp 0.5) (setvar warp 0.0) (setvar phase 0.0) (setvar freq 0.0)
          (setvar lev 0.0)
          (while (< lev 6.0)
            (setvar warp  (+ warp  (* amp (- (* 2.0 (noise pp)) 1.0))))
            (setvar phase (+ phase (* amp (- (* 2.0 (noise (+ pp (make-point 17.3 0 0)))) 1.0))))
            (setvar freq  (+ freq  (* amp (- (* 2.0 (noise (+ pp (make-point 0 31.7 0)))) 1.0))))
            (setvar amp (* amp 0.5))
            (setvar pp (* pp 2.0))
            (setvar lev (+ lev 1.0)))
          (setvar pp (* (+ Pg (make-point warp phase freq)) veinfreq))
          ;; turbsum += (1-turbsum)·pow(smoothstep(.8,1,1-|snoise|), sharpness) / freq, freq×3
          (setvar freq 1.0)
          (setvar lev 0.0)
          (setvar vein 0.0)
          (while (< lev veinlevels)
            (setvar warp (abs (- (* 2.0 (noise (* pp freq))) 1.0)))
            (setvar warp (/ (pow (smoothstep 0.8 1.0 (- 1.0 warp)) sharpness) freq))
            (setvar vein (+ vein (* (- 1.0 vein) warp)))
            (setvar freq (* freq 3.0))
            (setvar pp (* pp 3.0))
            (setvar lev (+ lev 1.0)))))
    (setvar vein (clamp vein 0 1))
    (setvar marble (mix Cs veincolor vein))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* marble (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                         (* specularcolor Ks (specular Nf Vdir roughness))))))))
(compile-shader veinedmarble-shader)
(append-shader veinedmarble-shader)
