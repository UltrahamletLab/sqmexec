;;; stucco.lisp — RenderMan stucco.sl port as true SQM SDF displacement.
(setq stucco-shader
(make-shader stucco :keyword :displacement
  (((Km float) 0.05) ((power float) 5.0) ((frequency float) 10.0))
  (enter (((n float) 0.0))
    (setvar n (vnoise (* P frequency)))
    (setvar disp (* Km (pow (clamp n 0.0 1.0) power))))))
(compile-shader stucco-shader)
(append-shader stucco-shader)
