;;; bsdftitanium — 焼けチタン (酸化膜の干渉色) PT -Q 材質 (2026-08-02)
;;;
;;; 加熱したチタン/バイクマフラーの焼け色。表面の酸化膜 (TiO2, n≈2.2〜2.5) が
;;; 熱で厚く育ち、薄膜干渉で 金→紫→青→水色→緑 と色が回る。
;;;   膜厚 d = thick-min + (thick-max−thick-min)·heat   (heat = Pg の高さランプ)
;;;   OPD = 2·n·d·cosθt → RGB 3波長の干渉 (bsdfsoap と同式)
;;; **場所 (熱勾配) と角度 (視線) の両方で色が回る**のが実物の焼け色の要点。
;;;
;;; |I|=0 の退避: cosθt=1 (垂直入射) — 熱勾配の色は残る。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (kd 1) (bsdf bsdftitanium)
;;;            (param low-y 0.0) (param high-y 1.7)   ; 熱勾配の範囲 (low=冷/high=熱)
;;;            (param thick-min 40) (param thick-max 520)
;;;            (param rough 0.28) (param metallic 0.9))

(setq bsdftitanium-shader

(make-shader bsdftitanium :keyword :volume
      (((ti-color   color) (make-color 0.62 0.60 0.57))  ; 素地 (未加熱チタン)
       ((low-y      float) 0.0)     ; 冷側 (素地のまま)
       ((high-y     float) 1.7)     ; 熱側 (膜が厚い)
       ((thick-min  float) 40.0)    ; nm
       ((thick-max  float) 520.0)   ; nm
       ((oxide-n    float) 2.2)     ; TiO2 の屈折率
       ((strength   float) 0.85)
       ((rough      float) 0.28)
       ((metallic   float) 0.90))

  (enter (((ln float) 0.0) ((vd float) 0.0) ((cv float) 0.0)
          ((hh float) 0.0) ((dd float) 0.0) ((ct float) 0.0)
          ((opd float) 0.0) ((mw float) 0.0)
          ((ir float) 0.0) ((ig float) 0.0) ((ib float) 0.0))

    (setvar ln (sqrt (dot I I)))
    (setvar vd (clamp (* ln 100000.0) 0.0 1.0))
    (setvar cv (/ (abs (dot (normalize N) I))
                  (clamp ln 0.000001 1000000.0)))
    (setvar cv (clamp cv 0.0 1.0))

    ;; 熱勾配: 高いほど熱い → 膜が厚い (smoothstep で遷移帯を柔らかく)
    (setvar hh (smoothstep low-y high-y (ycomp Pg)))
    (setvar dd (+ thick-min (* (- thick-max thick-min) hh)))

    (setvar ct (sqrt (clamp (- 1.0 (/ (- 1.0 (* cv cv))
                                      (* oxide-n oxide-n))) 0.0 1.0)))
    (setvar ct (+ 1.0 (* vd (- ct 1.0))))
    (setvar opd (* 2.0 (* oxide-n (* dd ct))))
    (setvar ir (- 0.5 (* 0.5 (cos (/ (* 6.283185 opd) 650.0)))))
    (setvar ig (- 0.5 (* 0.5 (cos (/ (* 6.283185 opd) 532.0)))))
    (setvar ib (- 0.5 (* 0.5 (cos (/ (* 6.283185 opd) 450.0)))))

    ;; 冷側 (hh→0) は素地のまま、熱側ほど干渉色。metallic 高 → 反射色に載る
    (setvar mw (* strength (* hh (+ 0.55 (* 0.45 (- 1.0 (* cv vd)))))))
    (setvar Cl (mix ti-color (make-color ir ig ib) (clamp mw 0.0 1.0)))
    (setvar Oi (make-color rough metallic 0.0))
)))

(compile-shader bsdftitanium-shader)
(append-shader bsdftitanium-shader)
