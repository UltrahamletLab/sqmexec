;;; snowterrain.lisp -- thin snow over procedural mountain rock
;;;
;;; Original SQM/DR shader. It uses height, slope, and procedural noise to
;;; place a modest snow layer on upward-facing terrain while leaving exposed
;;; rock on steep sides.

(setq snowterrain-shader
(make-shader snowterrain :keyword :surface
  (((Ka float) 0.28) ((Kd float) 0.82) ((Ks float) 0.18) ((roughness float) 0.18)
   ((rock-color color) (make-color 0.30 0.27 0.24))
   ((dirt-color color) (make-color 0.42 0.34 0.25))
   ((snow-color color) (make-color 0.78 0.82 0.90))
   ((snow-line float) 1.20)
   ((snow-softness float) 1.00)
   ((slope-thresh float) 0.66)
   ((slope-softness float) 0.22)
   ((noise-scale float) 0.17)
   ((noise-amount float) 0.95)
   ((grain float) 0.28)
   ((Kr float) 0.10)
   ((fade-far float) 40.0))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((dir point) (reflect I Nf))
    ((hitp float) 0)
    ((px float) (xcomp Pg)) ((py float) (ycomp Pg)) ((pz float) (zcomp Pg))
    ((up float) 0) ((dist float) 0) ((fade float) 0) ((invf float) 1)
    ((large float) 0) ((fine float) 0) ((snownoise float) 0)
    ((hmask float) 0) ((smask float) 0) ((sidewind float) 0) ((snowmask float) 0)
    ((rockmix float) 0) ((roughmask float) 0)
    ((rock color) (make-color 0 0 0))
    ((snow color) (make-color 0 0 0))
    ((base color) (make-color 0 0 0))
    ((refl color) (make-color 0 0 0))
    ((fres float) 0))
  ;; Distance LOD for tiny noise and sparkle.
  (setvar dist (length (- E Pg)))
  (setvar fade (smoothstep (* fade-far 0.55) fade-far dist))
  (setvar invf (- 1 fade))

  ;; Rock color breakup. Large scale chooses warm/cool rock; fine scale gives grit.
  (setvar large (turbulence (make-point (* px noise-scale) (* pz noise-scale) (* py 0.09)) 5))
  (setvar fine (noise (make-point (* px noise-scale 9) (* pz noise-scale 9) (* py 0.8))))
  (setvar rockmix (smoothstep 0.28 0.82 large))
  (setvar rock (mix rock-color dirt-color rockmix))
  (setvar roughmask (+ (- 1 (* grain invf 0.55)) (* grain invf fine)))
  (setvar rock (* rock roughmask))

  ;; Snow prefers high/upward surfaces, with broken wind-scoured edges.
  (setvar up (clamp (ycomp Nf) 0 1))
  (setvar snownoise (turbulence (make-point (* px noise-scale 1.8) (* pz noise-scale 1.8) 4.7) 4))
  (setvar hmask (smoothstep snow-line (+ snow-line snow-softness)
                            (+ py (* noise-amount (- snownoise 0.5)))))
  (setvar smask (smoothstep slope-thresh (+ slope-thresh slope-softness) up))
  (setvar sidewind (smoothstep -0.15 0.55 (+ (xcomp Nf) (* hmask hmask))))
  (setvar snowmask (clamp (* hmask smask (+ 0.45 (* 0.55 sidewind))) 0 1))

  ;; Slight blue-gray snow with small granular variation.
  (setvar snow (* snow-color (+ 0.86 (* 0.20 fine))))
  (setvar base (mix rock snow (smoothstep 0.08 0.78 snowmask)))

  ;; A little grazing reflection keeps snow cold and crystalline, but stays subtle.
  (setvar fres (pow (clamp (- 1 (dot Nf Ir)) 0 1) 4))
  (setvar refl (* Kr fres (trace P dir hitp)))

  (setvar Oi Os)
  (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                      (* (+ snowmask 0.35) Ks (specular Nf Ir roughness))
                      refl)))))
)

(compile-shader snowterrain-shader)
(append-shader  snowterrain-shader)
