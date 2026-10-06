;;; oak.lisp — BMRT oak.sl/oak.h procedural solid oak, ported to DR DSL.
;;; Rings surround the world Z axis, matching the RenderMan source.
;;; Derivative-filtered noise is approximated with smooth analytic bands because
;;; this DSL does not expose filterwidth.  divotdepth perturbs the shading normal.

(setq oak-shader
(make-shader oak :keyword :surface
  (((Ka float) 1.0) ((Kd float) 1.0) ((Ks float) 0.25) ((roughness float) 0.2)
   ((ringfreq float) 8.0) ((ringunevenness float) 0.5) ((grainfreq float) 25.0)
   ((ringnoise float) 0.02) ((ringnoisefreq float) 1.0)
   ((trunkwobble float) 0.15) ((trunkwobblefreq float) 0.025)
   ((angularwobble float) 1.0) ((angularwobblefreq float) 1.5)
   ((divotdepth float) 0.05)
   ((Clightwood color) (make-color 0.5 0.2 0.067))
   ((Cdarkwood color) (make-color 0.15 0.077 0.028))
   ((ringy float) 1.0) ((grainy float) 1.0))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((pp point) Pg) ((pr point) Pg) ((gp point) Pg)
    ((off float) 0) ((tw float) 0) ((rad float) 0) ((phase float) 0)
    ((band float) 0) ((grain float) 0) ((g1 float) 0) ((g2 float) 0)
    ((wood float) 0) ((eps float) 0.035) ((wx float) 0) ((wy float) 0)
    ((Nw point) (make-point 0 0 1)) ((Cwood color) (make-color 0 0 0)))

  ;; oak.h domain warp + wandering trunk axis
  (setvar off (* ringnoise (- (* 2 (turbulence (* pp ringnoisefreq) 4)) 1)))
  (setvar tw (* trunkwobble (- (* 2 (noise (* (zcomp pp) trunkwobblefreq))) 1)))
  (setvar pr (+ pp (make-point (+ off tw) (+ off tw) 0)))
  (setvar rad (* ringfreq (sqrt (+ (* (xcomp pr) (xcomp pr))
                                     (* (ycomp pr) (ycomp pr))))))
  (setvar rad (+ rad (* angularwobble (smoothstep 0 5 rad)
                       (- (* 2 (noise (* pr angularwobblefreq
                                         (make-point 1 1 0.1)))) 1))))
  (setvar rad (+ rad (* ringunevenness
                       (- (* 2 (noise (make-point (* rad 0.35) 7.1 2.3))) 1))))
  (setvar phase (- rad (floor rad)))
  ;; smooth pulse train: dark latewood occupies two shoulders of each ring
  (setvar band (* (- (smoothstep 0.08 0.28 phase)
                       (smoothstep 0.58 0.82 phase)) ringy))

  ;; two elongated grain octaves, stronger in the latewood ring
  (setvar gp (* pp grainfreq (make-point 1 1 0.05)))
  (setvar g1 (pow (clamp (- 0.8 (- (* 2 (noise gp)) 1)) 0 1) 2))
  (setvar gp (* gp 2))
  (setvar g2 (pow (clamp (- 0.8 (* 0.5 (- (* 2 (noise gp)) 1))) 0 1) 2))
  (setvar grain (* grainy (max (smoothstep 0.50 0.90 g1)
                                 (smoothstep 0.58 0.94 g2))))
  (setvar grain (* grain (+ 0.3 (* 0.7 band))))
  (setvar wood (clamp (max band grain) 0 1))
  (setvar Cwood (mix Clightwood Cdarkwood wood))

  ;; inexpensive bump analogue for oak divots (true displacement is not a surface operation)
  (setvar wx (- (noise (+ (* pp grainfreq) (make-point eps 0 0)))
                    (noise (- (* pp grainfreq) (make-point eps 0 0)))))
  (setvar wy (- (noise (+ (* pp grainfreq) (make-point 0 eps 0)))
                    (noise (- (* pp grainfreq) (make-point 0 eps 0)))))
  (setvar Nw (normalize (- Nf (* divotdepth (make-point wx wy 0)))))

  (setvar Oi Os)
  (setvar Ci (* Oi (+ (* Cwood (+ (* Ka (ambient)) (* Kd (diffuse Nw))))
                      (* (- 1 (* 0.5 wood)) Ks
                         (specular Nw Ir roughness)))))))
)

(compile-shader oak-shader)
(append-shader oak-shader)
