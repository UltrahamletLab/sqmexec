;;; oakplank.lisp — BMRT oakplank.sl port for SQM floors and panels.
;;; Projected on world X-Z, plank length along Z (SQM's usual horizontal floor).
;;; The original has more params than the 24 surface-argument slots SQM had at
;;; porting time; secondary variation/blur/eta controls are stable internal
;;; constants in this port.
;;; 2026-08-09 追記: BMRT 原典との再突き合わせ (oak.h/oakplank.sl 移植依頼) —
;;;   スロット上限は現在 32 (bsdfraku で拡張済み) なので varyhue/varysat/varylum,
;;;   edgewidth, groovedepth, varnishlump 等は**末尾追加で復元可能**になっている。
;;;   ただし現行の内部定数の絵で運用中のため、必要が出るまで据え置き (意図的)。
;;;   差分の全リストは docs/2026-08-09_oak_移植状況.md。

(setq oakplank-shader
(make-shader oakplank :keyword :surface
  (((Ka float) 1.0) ((Kd float) 1.0) ((Ks float) 0.75) ((roughness float) 0.1)
   ((Kr float) 0.35)
   ((ringfreq float) 8.0) ((ringunevenness float) 0.5)
   ((ringnoise float) 0.02) ((ringnoisefreq float) 1.0) ((grainfreq float) 25.0)
   ((trunkwobble float) 0.15) ((trunkwobblefreq float) 0.025)
   ((angularwobble float) 1.0) ((angularwobblefreq float) 1.5)
   ((divotdepth float) 0.012)
   ((Clightwood color) (make-color 0.5 0.2 0.067))
   ((Cdarkwood color) (make-color 0.15 0.077 0.028))
   ((Cgroove color) (make-color 0.02 0.02 0.02))
   ((ringy float) 1.0) ((grainy float) 1.0)
   ((plankwidth float) 2.0) ((planklength float) 30.0)
   ((groovewidth float) 0.05) ((grooveheight float) 0.05))
  (enter (
    ((Nf point) (faceforward (normalize N) I)) ((Ir point) (normalize (- I)))
    ((ss float) 0) ((tt float) 0) ((si float) 0) ((ti float) 0)
    ((spl float) 0) ((tpl float) 0) ((shift float) 0) ((pidx float) 0)
    ((se float) 0) ((te float) 0) ((inplank float) 0)
    ((pr point) Pg) ((gp point) Pg) ((off float) 0) ((tw float) 0)
    ((rad float) 0) ((phase float) 0) ((band float) 0)
    ((g1 float) 0) ((g2 float) 0) ((grain float) 0) ((wood float) 0)
    ((vary float) 1) ((edge float) 0) ((bumpx float) 0) ((bumpz float) 0)
    ((Nw point) (make-point 0 1 0)) ((Cwood color) (make-color 0 0 0))
    ((refl point) (make-point 0 0 0)) ((hitp float) 0))

  ;; plankpattern(): stagger each column by a deterministic cell noise
  (setvar ss (xcomp Pg)) (setvar tt (zcomp Pg))
  (setvar si (floor (/ ss plankwidth)))
  (setvar spl (- ss (* si plankwidth)))
  (setvar shift (* planklength (noise (make-point si 17.3 4.1))))
  (setvar tt (+ tt shift))
  (setvar ti (floor (/ tt planklength)))
  (setvar tpl (- tt (* ti planklength)))
  (setvar pidx (+ si (* 13 ti)))
  (setvar se (min spl (- plankwidth spl)))
  (setvar te (min tpl (- planklength tpl)))
  (setvar inplank (* (smoothstep 0 groovewidth se)
                      (smoothstep 0 grooveheight te)))

  ;; shift each plank's oak volume independently, as in the source Ppat
  (setvar pr (make-point (- spl (* 0.5 plankwidth))
                          (+ (ycomp Pg) (* 4 (- (noise (make-point pidx 2 8)) 0.5)))
                          (+ tpl (* 8 (- (noise (make-point pidx 5 3)) 0.5)))))
  (setvar off (* ringnoise (- (* 2 (turbulence (* pr ringnoisefreq) 4)) 1)))
  (setvar tw (* trunkwobble (- (* 2 (noise (* (zcomp pr) trunkwobblefreq))) 1)))
  (setvar pr (+ pr (make-point (+ off tw) (+ off tw) 0)))
  (setvar rad (* ringfreq (sqrt (+ (* (xcomp pr) (xcomp pr))
                                     (* (ycomp pr) (ycomp pr))))))
  (setvar rad (+ rad (* angularwobble (smoothstep 0 5 rad)
                       (- (* 2 (noise (* pr angularwobblefreq
                                         (make-point 1 1 0.1)))) 1))))
  (setvar rad (+ rad (* ringunevenness
                       (- (* 2 (noise (make-point (* rad 0.35) 7.1 2.3))) 1))))
  (setvar phase (- rad (floor rad)))
  (setvar band (* ringy (- (smoothstep 0.08 0.28 phase)
                            (smoothstep 0.58 0.82 phase))))
  (setvar gp (* pr grainfreq (make-point 1 1 0.05)))
  (setvar g1 (pow (clamp (- 0.8 (- (* 2 (noise gp)) 1)) 0 1) 2))
  (setvar gp (* gp 2))
  (setvar g2 (pow (clamp (- 0.8 (* 0.5 (- (* 2 (noise gp)) 1))) 0 1) 2))
  (setvar grain (* grainy (max (smoothstep 0.50 0.90 g1)
                                 (smoothstep 0.58 0.94 g2))))
  (setvar grain (* grain (+ 0.3 (* 0.7 band))))
  (setvar wood (clamp (max band grain) 0 1))

  ;; plank-to-plank luminosity variation and dark recessed grooves
  (setvar vary (+ 0.75 (* 0.50 (noise (make-point pidx 11.7 6.2)))))
  (setvar Cwood (* (mix Clightwood Cdarkwood wood) vary))
  (setvar Cwood (mix Cgroove Cwood inplank))

  ;; groove and grain bump; keeps geometry unchanged and therefore sphere tracing safe
  (setvar edge (- 1 inplank))
  (setvar bumpx (+ (* divotdepth (- (noise (+ pr (make-point 0.04 0 0)))
                                      (noise (- pr (make-point 0.04 0 0)))))
                    (* edge (- spl (* 0.5 plankwidth)))))
  (setvar bumpz (+ (* divotdepth (- (noise (+ pr (make-point 0 0 0.04)))
                                      (noise (- pr (make-point 0 0 0.04)))))
                    (* edge (- tpl (* 0.5 planklength)) 0.08)))
  (setvar Nw (normalize (- Nf (make-point bumpx 0 bumpz))))

  ;; varnished shiny-plastic approximation: direct highlight + traced reflection
  (setvar refl (reflect I Nw))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ (* Cwood (+ (* Ka (ambient)) (* Kd (diffuse Nw))))
                      (* Ks (+ 0.2 wood) inplank (specular Nw Ir roughness))
                      (* Kr (+ 0.2 (* 0.8 inplank)) (trace P refl hitp)))))))
)

(compile-shader oakplank-shader)
(append-shader oakplank-shader)
