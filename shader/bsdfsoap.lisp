;;; bsdfsoap — シャボン玉/オイルスリック: 薄膜干渉の厳密式 (PT -Q 材質, 2026-08-02)
;;;
;;; bsdfiridescent (位相を角度の一次近似で回す装飾版) の物理化。
;;;   光路差 OPD = 2·n·d·cosθt   (θt = 膜内の屈折角。Snell から
;;;   cosθt = sqrt(1 − (1−cos²θi)/n²))
;;;   反射強度_λ = 0.5 − 0.5·cos(2π·OPD/λ)  — 空気→膜の反射の半波長シフト込み
;;;   → d→0 で全波長が打ち消し合う「黒膜」(実物の石鹸膜の頂部) が出る。
;;; 膜厚 d は Pg の高さで流す (重力で上が薄い): d = thick-nm·(1 − thick-grad·h)。
;;;
;;; |I|=0 (SPPM/BDPT/VCM) の退避: cosθt=1 (垂直入射) — 干渉色は残り角度依存だけ消える。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdfsoap)
;;;            (param low-y 0.0) (param high-y 1.7)     ; 膜厚勾配の高さ範囲 (world y)
;;;            (param thick-nm 420) (param thick-grad 0.65)
;;;            (param film-n 1.33) (param strength 0.9)
;;;            (param rough 0.10) (param metallic 0.65))

(setq bsdfsoap-shader

(make-shader bsdfsoap :keyword :volume
      (((base-color color) (make-color 0.02 0.02 0.03))
       ((low-y      float) 0.0)     ; h=0 (膜が厚い側)
       ((high-y     float) 1.7)     ; h=1 (膜が薄い側 = 上)
       ((thick-nm   float) 420.0)   ; 基準膜厚 (nm)
       ((thick-grad float) 0.65)    ; 上端での薄化率 (0=一様, 0.9=上端ほぼゼロ)
       ((film-n     float) 1.33)    ; 膜の屈折率 (石鹸水 1.33 / 油膜 1.45)
       ((strength   float) 0.9)
       ((rough      float) 0.10)
       ((metallic   float) 0.65))

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((hh float) 0.0) ((dd float) 0.0) ((ct float) 0.0)
          ((opd float) 0.0) ((mw float) 0.0)
          ((ir float) 0.0) ((ig float) 0.0) ((ib float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    (setvar cv (clamp cv 0.0 1.0))

    ;; 膜厚: 高さ h で上ほど薄い
    (setvar hh (clamp (/ (- (ycomp Pg) low-y) (- high-y low-y)) 0.0 1.0))
    (setvar dd (* thick-nm (- 1.0 (* thick-grad hh))))

    ;; Snell: cosθt = sqrt(1 − (1−cos²θi)/n²)。|I|=0 → 1 (垂直入射扱い)
    (setvar ct (sqrt (clamp (- 1.0 (/ (- 1.0 (* cv cv))
                                      (* film-n film-n))) 0.0 1.0)))
    (setvar ct (+ 1.0 (* vd (- ct 1.0))))

    ;; OPD = 2·n·d·cosθt (nm)。半波長シフト → d→0 で暗転 (黒膜)
    (setvar opd (* 2.0 (* film-n (* dd ct))))
    (setvar ir (- 0.5 (* 0.5 (cos (/ (* 6.283185 opd) 650.0)))))
    (setvar ig (- 0.5 (* 0.5 (cos (/ (* 6.283185 opd) 532.0)))))
    (setvar ib (- 0.5 (* 0.5 (cos (/ (* 6.283185 opd) 450.0)))))

    ;; 掠め角ほど反射が立つ (穏やかに)。|I|=0 でも垂直入射の干渉色は残す
    (setvar mw (* strength (+ 0.35 (* 0.65 (- 1.0 (* cv vd))))))
    (setvar Cl (mix base-color (make-color ir ig ib) (clamp mw 0.0 1.0)))
    (setvar Oi (make-color rough metallic 0.0))
)))

(compile-shader bsdfsoap-shader)
(append-shader bsdfsoap-shader)
