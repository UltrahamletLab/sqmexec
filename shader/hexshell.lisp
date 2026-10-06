;; hexshell.lisp — 甲羅の六角タイル (亀甲)。世界座標の平面投影で六角格子を張り、
;; 目地を暗く・タイルごとに明度をばらつかせ・目地際のべベルで法線を倒す。
;;
;; 六角格子は「2つの矩形格子の最近接中心の min」(尖頭六角、外接半径 1):
;;   格子A: (i·√3, j·3) / 格子B: 半セルずらし (√3/2, 1.5)
;;   六角の距離ノルム h = max(|du|, |du|/2 + √3/2·|dv|)、境界は h = √3/2
;; ハッシュは frac ベース (mod は fmod で負側が死ぬ — storefront の教訓)。
;; axis: 0=x投影(u=z,v=y) / 1=y投影(u=x,v=z) / 2=z投影(u=x,v=y)
(setq hexshell-shader
(make-shader hexshell :keyword :surface
      (
       ((Ka float) 0.16)
       ((Kd float) 0.85)
       ((Ks float) 0.18)
       ((roughness float) 0.25)
       ((size float) 0.016)
       ((seam-width float) 0.22)
       ((seam-color color) (make-color 0.10 0.13 0.06))
       ((vary float) 0.18)
       ((bump float) 0.4)
       ((axis float) 0)
       ((phase float) 0)
      )
  (enter (
          ((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((ax0 float) 0) ((ax1 float) 0) ((ax2 float) 0)
          ((su float) 0) ((sv float) 0)
          ((cua float) 0) ((cva float) 0) ((dua float) 0) ((dva float) 0) ((ha float) 0)
          ((cub float) 0) ((cvb float) 0) ((dub float) 0) ((dvb float) 0) ((hb float) 0)
          ((wa float) 0) ((cu float) 0) ((cv float) 0) ((hn float) 0)
          ((gm float) 0) ((bnd float) 0) ((hsh float) 0) ((rl float) 0)
          ((eu point) (make-point 0 0 0)) ((ev point) (make-point 0 0 0))
          ((Np point) (make-point 0 0 0)) ((Ps point) (make-point 0 0 0))
          ((Ct color) (make-color 0 0 0))
         )
    (setvar ax0 (- 1 (min 1 (abs axis))))
    (setvar ax1 (max 0 (- 1 (abs (- axis 1)))))
    (setvar ax2 (max 0 (- 1 (abs (- axis 2)))))
    ;; ⚠ 投影は **shader 空間**で取る (2026-08-29)。world の Pg を直に使うと、
    ;;    模様が世界に固定されたまま甲羅だけが通り抜けて**動くと模様が流れる**
    ;;    (河童の歩行アニメで発覚。上下動のときに最も目立つ)。
    ;;    (shader-space ..) 未宣言なら transform は恒等なので静止シーンは不変。
    (setvar Ps (transform "shader" Pg))
    (setvar su (/ (+ phase (+ (* ax0 (zcomp Ps)) (* (+ ax1 ax2) (xcomp Ps)))) size))
    (setvar sv (/ (+ (* (+ ax0 ax2) (ycomp Ps)) (* ax1 (zcomp Ps))) size))
    ;; 格子A
    (setvar cua (* 1.7320508 (round (/ su 1.7320508))))
    (setvar cva (* 3.0 (round (/ sv 3.0))))
    (setvar dua (- su cua))
    (setvar dva (- sv cva))
    (setvar ha (max (abs dua) (+ (* 0.5 (abs dua)) (* 0.8660254 (abs dva)))))
    ;; 格子B (半セルずらし)
    (setvar cub (+ 0.8660254 (* 1.7320508 (round (/ (- su 0.8660254) 1.7320508)))))
    (setvar cvb (+ 1.5 (* 3.0 (round (/ (- sv 1.5) 3.0)))))
    (setvar dub (- su cub))
    (setvar dvb (- sv cvb))
    (setvar hb (max (abs dub) (+ (* 0.5 (abs dub)) (* 0.8660254 (abs dvb)))))
    ;; 勝った六角 (wa=1 なら A)
    (setvar wa (step ha hb))
    (setvar hn (/ (min ha hb) 0.8660254))
    ;; ⚠ DSL の mix は色専用 (rainbowsky の教訓) — float は算術で
    (setvar cu (+ (* wa cua) (* (- 1 wa) cub)))
    (setvar cv (+ (* wa cva) (* (- 1 wa) cvb)))
    (setvar dua (+ (* wa dua) (* (- 1 wa) dub)))
    (setvar dva (+ (* wa dva) (* (- 1 wa) dvb)))
    ;; タイルごとのハッシュ (frac 2段)
    (setvar hsh (+ (* 0.37113 cu) (+ (* 0.67991 cv) 0.1723)))
    (setvar hsh (- hsh (floor hsh)))
    (setvar hsh (* 43758.5453 hsh))
    (setvar hsh (- hsh (floor hsh)))
    ;; 目地と面の色
    (setvar gm (smoothstep (- 1 seam-width) (- 1 (* 0.3 seam-width)) hn))
    (setvar Ct (* Cs (+ 1 (* vary (- hsh 0.5)))))
    (setvar Ct (mix Ct seam-color gm))
    ;; べベル: 目地の内側の帯で法線を径方向外へ倒す (浅い彫りに見える)
    (setvar bnd (* (smoothstep (- 1 (* 1.6 seam-width)) 1 hn) (- 1 (* 0.6 gm))))
    (setvar eu (make-point (+ ax1 ax2) 0 ax0))
    (setvar ev (make-point 0 (+ ax0 ax2) ax1))
    (setvar rl (max 0.0001 (min ha hb)))
    (setvar Np (normalize (- Nf (* (* bump bnd)
                                   (normalize (+ (* eu (/ dua rl)) (* ev (/ dva rl))))))))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse Np))))
                        (* Ks (specular Np Ir roughness))))))))
(compile-shader hexshell-shader)
(append-shader hexshell-shader)
