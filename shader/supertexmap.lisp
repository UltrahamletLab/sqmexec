;;; supertexmap.lisp — practical SQM port of supertexmap.sl.
;;; Supports color, opacity and specularity maps. dispmap is a shading-normal bump;
;;; use a :displacement shader when silhouette displacement is required.
;;;
;;; 2026-08-09: 原典の売り (投影の柔軟性 per-map projection/space/mx) は当時全部
;;;   落とされていた。shader 空間の新設で一部を復元:
;;;     (param projection 1) = **shader 空間の平面投影** (xy)。UV の無い SDF に
;;;     デカールを貼り、(surface .. (shader-space (translate/rotate/scale ..))) で
;;;     位置決め・回転・拡縮できる。既定 0 = 従来の st (ビット一致)。
;;;   投影は全マップ共有 (原典の per-map とは違う — 簡約)。原典の Os マップが
;;;   Ct を基底に取るのは BMRT のバグなので踏襲しない (Ot 基底のまま)。
(setq supertexmap-shader
(make-shader supertexmap :keyword :surface
  (((Ka float) 1.0) ((Kd float) 0.5) ((Ks float) 0.5)
   ((roughness float) 0.1) ((specularcolor color) (make-color 1 1 1))
   ((Csmapname string) "") ((Osmapname string) "")
   ((Ksmapname string) "") ((dispmapname string) "")
   ((dispamount float) 0.0) ((maps-scale float) 1.0)
   ((projection float) 0.0))   ; 0=st / 1=shader空間xy / 2=world dominant-axis box mapping
  (enter (((Nf point) (faceforward (normalize N) I)) ((Nw point) Nf)
          ((Vdir point) (normalize (- I))) ((Ct color) Cs) ((Ot color) Os)
          ((ksv float) Ks) ((uvp point) (make-point 0 0 0))
          ((anx float) (abs (xcomp Nf))) ((any float) (abs (ycomp Nf)))
          ((anz float) (abs (zcomp Nf)))
          ((eps float) 0.002) ((h0 float) 0) ((hu float) 0) ((hv float) 0))
    (if (< projection 0.5)
        (setvar uvp (make-point (* s maps-scale) (* t maps-scale) 0))
      (if (< projection 1.5)
          (progn
            (setvar uvp (transform "shader" Pg))
            (setvar uvp (make-point (* (xcomp uvp) maps-scale)
                                    (* (ycomp uvp) maps-scale) 0)))
          ;; Dominant-axis box mapping for towers and tiered/sloped roofs.
          ;; X face -> zy, Y face -> xz, Z face -> xy.
          (if (> any (max anx anz))
              (setvar uvp (make-point (* (xcomp Pg) maps-scale)
                                      (* (zcomp Pg) maps-scale) 0))
            (if (> anx anz)
                (setvar uvp (make-point (* (zcomp Pg) maps-scale)
                                        (* (ycomp Pg) maps-scale) 0))
                (setvar uvp (make-point (* (xcomp Pg) maps-scale)
                                        (* (ycomp Pg) maps-scale) 0))))))
    (if (string/= Csmapname "") (setvar Ct (* Ct (texture Csmapname (xcomp uvp) (ycomp uvp)))))
    (if (string/= Osmapname "") (setvar Ot (* Ot (texture Osmapname (xcomp uvp) (ycomp uvp)))))
    (if (string/= Ksmapname "")
        (setvar ksv (* Ksv (comp (texture Ksmapname (xcomp uvp) (ycomp uvp)) 0))))
    (if (string/= dispmapname "")
      (progn
        (setvar h0 (comp (texture dispmapname (xcomp uvp) (ycomp uvp)) 0))
        (setvar hu (comp (texture dispmapname (+ (xcomp uvp) eps) (ycomp uvp)) 0))
        (setvar hv (comp (texture dispmapname (xcomp uvp) (+ (ycomp uvp) eps)) 0))
        (setvar Nw (normalize (- Nf (* dispamount (make-point (- hu h0) (- hv h0) 0)))))))
    (setvar Oi Ot)
    (setvar Ci (* Oi (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse Nw))))
                         (* specularcolor ksv (specular Nw Vdir roughness))))))))
(compile-shader supertexmap-shader)
(append-shader supertexmap-shader)
