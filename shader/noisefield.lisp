;;; noisefield
;;;
;;; 共有値格子ノイズ hook (vfbm) のデモ。SDF/ボリューム/fbmsdf と同一系統の
;;; IQ式 fBm を Lisp シェーダーから呼び、Cs を fBm 値で変調する。
;;; param順 = Ka, Kd, nf-scale, nf-octaves (shade_dr.c の noisefield_params と一致させる)

(setq noisefield-shader

(make-shader noisefield :keyword :surface
      (
       ((Ka float) 0.3)
       ((Kd float) 0.9)
       ((nf-scale float) 3.0)
       ((nf-octaves float) 6)
       )
  (enter (((Nf point) (faceforward (normalize N) I)))
    (setvar Ci (* Cs (vfbm (* nf-scale Pg) nf-octaves)))
    (setvar Oi Os)
    (setvar Ci (* Os Ci (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))

)))

(compile-shader noisefield-shader)
(append-shader noisefield-shader)
