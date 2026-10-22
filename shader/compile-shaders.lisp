;;; compile-shaders (make standard shader)
;;;
;;; [Science Art Laboratory]:
;;;   Copyright (C) 1993 Magic Box Productions, Inc. (toshi@sala.sony.co.jp)

#+:CMU
(setq ext:*gc-verbose* nil)

(defvar *standard-shaders*
  '("constant"
    "matte"
    "metal"
    "plastic"
    "txtplastic"
    "anisotropy"
    "links"
    "clouds"
    "checker"
    "screen"
    "spotted"
    "bumpy"
    "bumpmap"
    "dimpled"
    "marble"
    "thunder"
    "wood"
    "water"
    "glass"
    "shiny"
    "mirror"
    "envmetal"
    "flame"
    "ramp"
    "rim"
    "depthcue"
    "fog"
    "ambientlight"
    "distantlight"
    "pointlight"
    "spotlight"
    "shadowlight"))


;;; Load DShader object files.

(dolist (a-shader *standard-shaders*)
  (load (concatenate 'string a-shader ".lisp")))
