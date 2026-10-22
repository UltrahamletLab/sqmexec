;;; donut — ドーナツ (アイシング + スプリンクル + ドリズル + 焼きムラ生地)。
;;;   トーラス上のチューブ高さ比 (Pg.y - icing-y)/minor と波打つ縁ノイズで
;;;   上面をアイシングに分け、生地=マット / アイシング=濡れつや (フレネル)。
;;;   スプリンクルは floor 格子のセルハッシュ (jitter + 存続 + 6色パレット)。
;;;   drizzle は sprinkle-color の細い斜め縞がけ (青ドーナツの白線)。
;;;   ココナッツは sprinkle-mono 1 + 高 density。

(setq donut-shader

(make-shader donut :keyword :surface
      (
       ((Ka float) 0.24)
       ((Kd float) 0.8)
       ((Ks float) 0.6)
       ((roughness float) 0.03)
       ((icing-color color) (make-color 0.95 0.45 0.60))
       ((dough-color color) (make-color 0.82 0.60 0.38))
       ((icing-y float) 0.6)           ; トーラス中心の高さ (world y)
       ((minor float) 0.2)             ; チューブ半径
       ((edge float) -0.25)            ; アイシング下端しきい (-1=全周, 1=なし)
       ((wave-amp float) 0.35)         ; 縁の波打ち振幅
       ((wave-freq float) 2.6)         ; 縁の波打ち周波数
       ((sprinkle-density float) 0.0)  ; セル密度 (0=スプリンクルなし, 例 26)
       ((sprinkle-radius float) 0.30)  ; セル内の粒半径 (0..0.5)
       ((sprinkle-keep float) 0.45)    ; 存続しきい (小=粒が多い)
       ((sprinkle-mono float) 0.0)     ; 1=単色 (ココナッツ/白) 0=6色パレット
       ((sprinkle-color color) (make-color 1 1 1))  ; 単色粒 & drizzle の色
       ((drizzle float) 0.0)           ; 細線がけの強度 (0=なし)
       ((drizzle-freq float) 9.0)      ; 縞の周波数
       ((spec-color color) (make-color 1 1 1))
       ((sprinkle-bump float) 0.55)    ; 粒の半球隆起の強さ (法線バンプ)
       ((drizzle-bump float) 0.35)     ; ドリズル線の盛り上がり
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((wave float) 0)
          ((hh float) 0)
          ((icing float) 0)
          ((doughtex float) 0)
          ((base color) (make-color 0 0 0))
          ((q point) 0)
          ((cell point) 0)
          ((jx float) 0)
          ((jy float) 0)
          ((jz float) 0)
          ((rnd float) 0)
          ((hue float) 0)
          ((d2 float) 0)
          ((sm float) 0)
          ((scol color) (make-color 1 1 1))
          ((dr float) 0)
          ((fres float) 0)
          ((ksx float) 0)
          ((arg float) 0)
          ((dgrad float) 0)
          ((bmp point) 0)
          ((Nb point) 0))
    ;; ── アイシング被覆: チューブ高さ比 + 波打つ縁 ──
    (setvar wave (* wave-amp (- (vnoise (* wave-freq Pg)) 0.5)))
    (setvar hh (/ (- (ycomp Pg) icing-y) minor))
    (setvar icing (smoothstep edge (+ edge 0.22) (+ hh wave)))
    ;; ── 生地: 焼きムラ ──
    (setvar doughtex (+ 0.88 (* 0.24 (vfbm (* 5 Pg) 2))))
    (setvar base (mix (* dough-color doughtex) icing-color icing))
    ;; ── スプリンクル: floor 格子セルハッシュ ──
    (setvar q (* Pg sprinkle-density))
    (setvar cell (make-point (floor (xcomp q)) (floor (ycomp q)) (floor (zcomp q))))
    (setvar rnd (vnoise (+ (* cell 0.1371) (make-point 7.31 3.17 9.23))))
    ;; セル中心からのずれ (jitter ±0.24)
    (setvar jx (- (- (xcomp q) (+ (xcomp cell) 0.5))
                  (* 0.48 (- (vnoise (+ (* cell 0.2317) (make-point 1.7 9.2 4.4))) 0.5))))
    (setvar jy (- (- (ycomp q) (+ (ycomp cell) 0.5))
                  (* 0.48 (- (vnoise (+ (* cell 0.2317) (make-point 6.2 0.9 3.8))) 0.5))))
    (setvar jz (- (- (zcomp q) (+ (zcomp cell) 0.5))
                  (* 0.48 (- (vnoise (+ (* cell 0.2317) (make-point 4.9 7.7 1.2))) 0.5))))
    (setvar d2 (+ (* jx jx) (+ (* jy jy) (* jz jz))))
    (setvar sm (* (step d2 (* sprinkle-radius sprinkle-radius))  ; 粒内 (radius^2 >= d2)
                  (* (step sprinkle-keep rnd)                    ; セル存続
                     (* icing (step 0.5 sprinkle-density)))))    ; アイシング上のみ / density 0=off
    ;; 6色パレット (hue ハッシュを step で段階選択)
    (setvar hue (* 6 (vnoise (+ (* cell 0.3719) (make-point 5.1 2.9 8.7)))))
    (setvar scol (make-color 1.00 0.96 0.94))                       ; 白
    (setvar scol (mix scol (make-color 0.95 0.28 0.33) (step 1 hue))) ; 赤
    (setvar scol (mix scol (make-color 1.00 0.74 0.20) (step 2 hue))) ; 橙黄
    (setvar scol (mix scol (make-color 0.32 0.78 0.36) (step 3 hue))) ; 緑
    (setvar scol (mix scol (make-color 0.30 0.55 0.95) (step 4 hue))) ; 青
    (setvar scol (mix scol (make-color 0.92 0.45 0.85) (step 5 hue))) ; 桃紫
    (setvar scol (mix scol sprinkle-color sprinkle-mono))
    (setvar base (mix base scol sm))
    ;; ── ドリズル: 斜め方向の細い縞 (アイシング上のみ) ──
    (setvar arg (+ (* drizzle-freq (+ (xcomp Pg) (* 0.55 (zcomp Pg))))
                   (* 2.5 (vnoise (* 2.2 Pg)))))
    (setvar dr (* drizzle
                  (* (smoothstep 0.10 0.45 hh)
                     (step 0.94 (abs (sin arg))))))
    (setvar base (mix base sprinkle-color dr))
    ;; ── 法線バンプ: 粒の半球隆起 + ドリズル線の盛り上がり ──
    (setvar bmp (* (make-point jx jy jz)
                   (* sm (/ sprinkle-bump (clamp sprinkle-radius 0.05 1)))))
    (setvar dgrad (* (cos arg) (sign (sin arg))))
    (setvar bmp (+ bmp (* (make-point 1 0 0.55)
                          (* dr (* drizzle-bump dgrad)))))
    (setvar Nb (normalize (+ Nf bmp)))
    ;; ── 照明: アイシング=濡れつや / 生地=マット ──
    (setvar fres (- 1 (clamp (dot Nb Ir) 0 1)))
    (setvar ksx (* Ks (+ 0.12 (* 0.88 icing))))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nb))))
                        (+ (* spec-color
                              (* ksx (+ 1 (* 0.8 (* fres icing))))
                              (specular Nb Ir roughness))
                           (* spec-color (* 0.10 (* (* fres fres) icing)))))))
)))

(compile-shader donut-shader)
(append-shader donut-shader)
