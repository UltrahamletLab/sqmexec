;;; treefrogskin — アカメアマガエル (Agalychnis callidryas) の肌
;;;
;;; 狙いは「緑のプラスチック」にしないこと。実物の肌で効いているのは4つ:
;;;   ① 背は鮮やかな緑・腹はクリーム。分けるのは**法線の上向き成分**。
;;;      ⚠ 最初は world y (高さ) で分けたが**四肢が全部クリームになった** —
;;;        四肢は体より低いので「腹の高さ」に入ってしまう。法線なら
;;;        「上を向いている面が背」という意味そのものなので位置に依らない。
;;;   ② その境目に**青とクリームの縦縞**が並ぶ = この種の identity
;;;   ③ 肌が常に濡れている → **狭くて強いハイライト** + 掠め角の白い艶
;;;   ④ 薄い皮膚が光を透かす → 縁が黄緑〜橙に暖まる (疑似SSS)
;;;
;;; ⚠ 縞は**脇腹だけ**に出す。全身に回すと縞模様のカエルになる。
;;;   高さの blend 係数 gg が 0.5 付近 (= 背と腹の境目) でだけ縞を立てる。
;;;
;;; ⚠ 四肢は同じシェーダーに朱色を渡して使う (bar-amp 0 で縞を切る)。

(setq treefrogskin-shader

(make-shader treefrogskin :keyword :surface
      (((Ka        float) 0.22)
       ((Kd        float) 0.80)
       ((Ks        float) 0.55)
       ((roughness float) 0.035)
       ((back-color  color) (make-color 0.235 0.620 0.145))  ; 背の緑
       ((belly-color color) (make-color 0.880 0.870 0.720))  ; 腹のクリーム
       ((bar-color   color) (make-color 0.130 0.230 0.760))  ; 脇腹の青
       ((bar-freq  float) 5.5)    ; 縦縞の本数 (z 方向の周期)
       ((bar-amp   float) 1.0)    ; 縞の強さ (0 = 縞なし → 四肢用)
       ((bar-sharp float) 0.35)   ; 縞の縁の締まり (小さいほど硬い)
       ((flank-lo  float) -0.30)  ; 法線の上向き成分がこれ以下 = 腹の色
       ((flank-hi  float) 0.40)   ; これ以上 = 背の色
       ((ventral   float) 1.0)    ; 腹の塗り分けの強さ (0 = 全面 back-color)
       ((mottle    float) 0.10)   ; 背のむら
       ((sss       float) 0.45)   ; 疑似SSS (縁の透け)
       ((sss-color color) (make-color 0.95 0.62 0.20))
       ((wet       float) 0.55)   ; 濡れの艶 (掠め角の白)
       ;; ⚠ **新しい param は必ず末尾に足す** — 途中に挿すと以降の index が全部
       ;;   ずれ、shade_dr.cpp のテーブルと食い違って param が黙って効かなくなる
       ;;   (ventral を途中に入れて一度やらかした)。
       ((bar-zmin  float) -9.9)   ; 縞を出す world z の範囲。頭には出さない
       ((bar-zmax  float)  9.9)
       ;; ⚠ 縞の帯は**腹の塗り分けとは別に**決める。gg (背↔腹の係数) に
       ;;   ひもづけていたら、腹の閾値を下げた途端に縞が腹の底へ落ちた。
       ;;   脇腹は「法線がほぼ水平〜やや下向き」の帯 = ny で直接指定する。
       ((bar-nlo   float) -0.60)  ; 縞を出す法線 y の下限
       ((bar-nhi   float)  0.12)) ; 上限

  (enter (((nf   point) (faceforward (normalize N) I))
          ((ir   point) (normalize (- I)))
          ((yy   float) 0.0) ((zz   float) 0.0)
          ((gg   float) 0.0) ((band float) 0.0)
          ((bsin float) 0.0) ((bmask float) 0.0)
          ((mot  float) 0.0) ((fres float) 0.0)
          ((base color) (make-color 0 0 0))
          ((barc color) (make-color 0 0 0)) ((Ps point) (make-point 0 0 0)))

    (setvar yy (ycomp nf))       ; 法線の上向き成分 (-1 下 .. +1 上)
    ;; ⚠ 模様は **shader 空間**で取る (2026-08-29)。world の Pg を直に使うと
    ;;    アニメで体が動いたとき斑が体の上を流れる (hexshell と同じ穴)。
    ;;    (shader-space ..) 未宣言なら恒等なので静止シーンは不変。
    (setvar Ps (transform "shader" Pg))
    (setvar zz (zcomp Ps))       ; 縞の位置は体軸に沿った位置

    ;; ① 背↔腹 — 上を向いている面ほど背の色。ventral 0 で塗り分けを切る
    (setvar gg (- 1.0 (* ventral (- 1.0 (smoothstep flank-lo flank-hi yy)))))

    ;; 背のむら (共有値格子ノイズ。ジオメトリ側の fbm と同系統)
    (setvar mot (* mottle (- (vfbm (* Ps 7.0) 3) 0.5)))
    (setvar base (mix belly-color (+ back-color (make-color mot (* mot 1.3) (* mot 0.5)))
                      gg))

    ;; ② 脇腹の縦縞 — 境目の帯 (gg≈0.5) にだけ立てる
    (setvar band (* (smoothstep bar-nlo (+ bar-nlo 0.20) yy)
                    (- 1.0 (smoothstep (- bar-nhi 0.20) bar-nhi yy))))
    (setvar band (* bar-amp band))
    ;; 縞は胴の脇腹だけ。頭に回すと目の下をぐるりと巻く輪になる (実測)
    (setvar band (* band (* (smoothstep bar-zmin (+ bar-zmin 0.10) zz)
                            (- 1.0 (smoothstep (- bar-zmax 0.10) bar-zmax zz)))))
    (setvar bsin (sin (* zz bar-freq 6.2831853)))
    ;; 青とクリームが交互に並ぶ (片方だけだと縞に見えない)
    (setvar barc (mix belly-color bar-color
                      (smoothstep (- 0 bar-sharp) bar-sharp bsin)))
    (setvar bmask (* band 0.85))
    (setvar base (mix base barc bmask))

    ;; ③④ 濡れ + 疑似SSS
    (setvar fres (clamp (- 1.0 (dot nf ir)) 0.0 1.0))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse nf))))
                        ;; 濡れた膜のハイライト (狭い) + 掠め角の白い艶
                        (* (make-color 1.0 1.0 0.97)
                           (+ Ks (* wet (* fres (* fres fres))))
                           (specular nf ir roughness))
                        ;; 皮膚を透かした暖色 (縁ほど強い)
                        (* sss-color sss (* fres fres) (ambient)))))
)))

(compile-shader treefrogskin-shader)
(append-shader treefrogskin-shader)
