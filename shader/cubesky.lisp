;;; cubesky
;;; Cube-map sky dome. Place on a large (invert)ed, (no_shadow) sphere
;;; enclosing the scene. Samples the cube map along the view-ray direction I,
;;; so the texture reads as an infinitely-far skybox regardless of dome radius.
;;;
;;; map-name = directory holding 6 faces posX/negX/posY/negY/posZ/negZ.png
;;; (resolved engine-side in sqm_environment -> cubemap_sample).

(setq cubesky-shader

(make-shader cubesky :keyword :surface
      (((map-name string) ""))

  (enter (((dir point) (normalize I)))

    (setvar Oi Os)
    (if (string/= map-name "")
        (setvar Ci (environment map-name dir))
        (setvar Ci Cs)))))

(compile-shader cubesky-shader)
(append-shader cubesky-shader)
