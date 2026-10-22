;;; rhinoskin — 犀の皮膚 (変位シェーダー)
;;;
;;; 2つの成分を足す:
;;;  ①皺帯 (fold) — 首/肩後/股の3本の深い溝。x の帯を smoothstep 2枚で
;;;    平底の溝にし、位置は低周波ノイズで揺らす (真っ直ぐな溝は機械に見える)。
;;;    z の窓で胴だけに限定 (脚まで折れ線が降りると不自然)。
;;;  ②肌理 (wrinkle) — 値ノイズ2オクターブ。x を waniso 倍に圧縮した
;;;    異方性ノイズ = ひび割れが上下方向に伸びる (等方だと砂利になる。
;;;    furlay と同じ理屈)。
;;;
;;;  h = 0.5 + wamt*(wrinkle-0.5) - Σ fold_i   → clamp [0,1]
;;;
;;; lipschitz (シーンが申告):
;;;   wrinkle: ~2 × (wfreq×waniso) × wamt ≈ 2×22×0.55 ≈ 24
;;;   fold: fold-amt × 1.5/(0.85×fold-w) ≈ 0.8×1.5/0.076 ≈ 16 (3本は重ならない)
;;;   → 40 を申告 (過大申告はステップ予算切れで縞になるので盛らない)
;;;
;;; 座標: displace は object 空間で評価される。grid は SDF ツリー内の (rotate ..) で
;;; +Y up に立てているので、**高さは ycomp**・体軸は xcomp (回転で不変)。

(setq rhinoskin-shader

(make-shader rhinoskin :keyword :displacement
      (((wfreq    float) 11.0)    ; 肌理の周波数 (1/m)
       ((wamt     float) 0.55)    ; 肌理の振幅 (h の振れ幅)
       ((waniso   float) 2.0)     ; x 方向の圧縮 = ひびの縦伸び
       ((fold-w   float) 0.10)    ; 皺帯の半幅 (m)
       ((fold-amt float) 0.80)    ; 皺帯の深さ (h 単位)
       ((fold1    float) 0.98)    ; 首の皺帯の x
       ((fold2    float) 0.05)    ; 肩後の皺帯の x
       ((fold3    float) -0.62)   ; 股前の皺帯の x
       ((fold-zlo float) 0.45))   ; これ未満の高さでは皺帯を消す (脚)

  (enter (((q  point) (make-point 0 0 0))
          ((n1 float) 0.0)
          ((n2 float) 0.0)
          ((h  float) 0.0)
          ((px float) 0.0)
          ((wob float) 0.0)
          ((zw float) 0.0)
          ((dx float) 0.0)
          ((g  float) 0.0))

    ;; ── ② 肌理: 異方性2オクターブ。値ノイズは格子が軸整列なので、
    ;;    (y,z) を 27° 回してから引く (回さないと等値線が正方形に出る —
    ;;    脇腹の同心矩形アーティファクトの正体)。周波数比 2.17 = 非整数。
    (setvar q (make-point (* (xcomp P) (* wfreq waniso))
                          (* (- (* 0.891 (ycomp P)) (* 0.454 (zcomp P))) wfreq)
                          (* (+ (* 0.454 (ycomp P)) (* 0.891 (zcomp P))) wfreq)))
    (setvar n1 (vnoise q))
    (setvar q (make-point (+ (* (xcomp P) (* (* wfreq waniso) 2.17)) 7.31)
                          (* (+ (* 0.891 (ycomp P)) (* 0.454 (zcomp P))) (* wfreq 2.17))
                          (* (- (* 0.454 (zcomp P)) (* 0.891 (ycomp P))) (* wfreq 2.17))))
    (setvar n2 (vnoise q))
    (setvar h (+ 0.5 (* wamt (- (+ (* 0.65 n1) (* 0.35 n2)) 0.5))))

    ;; ── ① 皺帯: 位置を低周波ノイズで ±0.05 揺らし、z 窓で胴に限定 ──
    ;; 揺らぎも回した域から引く + 振幅は控えめ (0.035)。軸整列のまま使うと
    ;; 皺帯の縁が正方格子をなぞる
    (setvar q (make-point (+ (* (- (* 0.891 (ycomp P)) (* 0.454 (zcomp P))) 2.3) 3.7)
                          (* (+ (* 0.454 (ycomp P)) (* 0.891 (zcomp P))) 2.3)
                          1.7))
    (setvar wob (* 0.035 (- (* 2.0 (vnoise q)) 1.0)))
    (setvar px (+ (xcomp P) wob))
    (setvar zw (smoothstep fold-zlo (+ fold-zlo 0.18) (ycomp P)))

    ;; fold1 (首)
    (setvar dx (- px fold1))
    (setvar g (* (smoothstep (- 0.0 fold-w) (* fold-w -0.2) dx)
                 (- 1.0 (smoothstep (* fold-w 0.2) fold-w dx))))
    (setvar h (- h (* (* fold-amt zw) g)))
    ;; fold2 (肩後)
    (setvar dx (- px fold2))
    (setvar g (* (smoothstep (- 0.0 fold-w) (* fold-w -0.2) dx)
                 (- 1.0 (smoothstep (* fold-w 0.2) fold-w dx))))
    (setvar h (- h (* (* fold-amt zw) g)))
    ;; fold3 (股前)
    (setvar dx (- px fold3))
    (setvar g (* (smoothstep (- 0.0 fold-w) (* fold-w -0.2) dx)
                 (- 1.0 (smoothstep (* fold-w 0.2) fold-w dx))))
    (setvar h (- h (* (* fold-amt zw) g)))

    (setvar disp (clamp h 0.0 1.0))
)))

(compile-shader rhinoskin-shader)
(append-shader rhinoskin-shader)
