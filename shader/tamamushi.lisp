;;; tamamushi — ヤマトタマムシの上翅 (SVG 細密画 2026-09-23 の移植)
;;;
;;; 座標: (transform "shader" Pg) の x = 横 (正中線=縫合線が x=0、左右対称に |x| を使う)
;;;       y = 縦 (上翅の付け根が stripe-y0 側・翅端が stripe-y1 側)。向きは (shader-space ..)。
;;;   uu = |x|/half-width を「縫合線 0 → 外縁 1」の横位置として使う。
;;;
;;; 見た目の要素:
;;;   ① 横位置による構造色: 縫合線の深緑 → 盛り上がりの黄緑 (金) → 外縁の青
;;;   ② 赤紫の縦縞 (uu が stripe-lo..hi、y が stripe-y0..y1、両端は丸く細る) + 金の縁取り
;;;   ③ 点刻: 平面をジッタ付きセルで割り、最寄りの穴の中を暗く + 法線を穴の中心へ倒す (凹み)
;;;   ④ 縦の細い隆条 (costa) — uu=0.16/0.25/0.74/0.86 の明るい筋
;;;   ⑤ 見る角度で青紫へずれる (iridescence) — 構造色の角度依存
;;;   ⑥ 光沢: 鋭い specular + Schlick フレネル × trace の映り込み (Kr)
;;;
;;; パラメータ定義順 (shade_dr.cpp の tamamushi_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 Kr=4 half-width=5 inner-color=6 crest-color=7
;;;   edge-color=8 stripe-color=9 stripe-color2=10 border-color=11 stripe-lo=12
;;;   stripe-hi=13 stripe-y0=14 stripe-y1=15 pit-freq=16 pit-depth=17 costa=18
;;;   iridescence=19 iri-color=20

(setq tamamushi-shader
(make-shader tamamushi :keyword :surface
  (((Ka float) 0.2)
   ((Kd float) 0.6)
   ((Ks float) 0.9)
   ((roughness float) 0.04)
   ((Kr float) 0.35)
   ((half-width float) 0.5)
   ((inner-color  color) (make-color 0.05 0.36 0.20))
   ((crest-color  color) (make-color 0.52 0.76 0.22))
   ((edge-color   color) (make-color 0.06 0.20 0.42))
   ((stripe-color  color) (make-color 0.80 0.18 0.36))
   ((stripe-color2 color) (make-color 0.36 0.10 0.52))
   ((border-color  color) (make-color 0.95 0.75 0.25))
   ((stripe-lo float) 0.31)
   ((stripe-hi float) 0.62)
   ((stripe-y0 float) -0.85)
   ((stripe-y1 float) 0.7)
   ((pit-freq float) 90.0)
   ((pit-depth float) 0.35)
   ((costa float) 0.35)
   ((iridescence float) 0.6)
   ((iri-color color) (make-color 0.25 0.20 0.85)))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((q0 point) (make-point 0 0 0))
    ((qx point) (make-point 0 0 0))
    ((qy point) (make-point 0 0 0))
    ((qz point) (make-point 0 0 0))
    ((ga point) (make-point 1 0 0))
    ((gb point) (make-point 0 1 0))
    ((Ta point) (make-point 1 0 0))
    ((Tb point) (make-point 0 1 0))
    ((Nb point) (make-point 0 0 1))
    ((hh float) 0.001)
    ((xx float) 0) ((yy float) 0) ((uu float) 0) ((sgn float) 1)
    ((col color) (make-color 0 0 0))
    ((tt float) 0) ((half float) 0) ((cc float) 0) ((lo float) 0) ((hi float) 0)
    ((ins float) 0) ((bord float) 0)
    ((px float) 0) ((py float) 0) ((ix float) 0) ((jy float) 0)
    ((k float) 0) ((m float) 0) ((cxx float) 0) ((cyy float) 0) ((dd float) 0)
    ((best float) 99) ((bx float) 0) ((by float) 0)
    ((pit float) 0) ((cst float) 0)
    ((cosv float) 0) ((fr float) 0)
    ((rdir point) (make-point 0 0 1))
    ((refl color) (make-color 0 0 0))
    ((hitf float) 0))

    (setvar q0 (transform "shader" Pg))
    (setvar qx (transform "shader" (+ Pg (make-point hh 0 0))))
    (setvar qy (transform "shader" (+ Pg (make-point 0 hh 0))))
    (setvar qz (transform "shader" (+ Pg (make-point 0 0 hh))))
    (setvar ga (make-point (- (xcomp qx) (xcomp q0)) (- (xcomp qy) (xcomp q0)) (- (xcomp qz) (xcomp q0))))
    (setvar gb (make-point (- (ycomp qx) (ycomp q0)) (- (ycomp qy) (ycomp q0)) (- (ycomp qz) (ycomp q0))))
    (setvar Ta (normalize (- ga (* Nf (dot Nf ga)))))
    (setvar Tb (normalize (- gb (* Nf (dot Nf gb)))))
    (setvar xx (xcomp q0))
    (setvar yy (ycomp q0))
    (setvar sgn 1)
    (if (< xx 0) (setvar sgn -1))
    (setvar uu (clamp (/ (abs xx) half-width) 0 1))

    ;; ① 横位置の構造色 (縫合線 → 盛り上がり → 外縁)
    (setvar col (mix inner-color crest-color (smoothstep 0.05 0.35 uu)))
    (setvar col (mix col (* crest-color 0.75) (smoothstep 0.45 0.72 uu)))
    (setvar col (mix col edge-color (smoothstep 0.78 1.0 uu)))

    ;; ② 縦縞 + 金の縁
    (setvar tt (/ (- yy stripe-y0) (- stripe-y1 stripe-y0)))
    (if (and (> tt 0) (< tt 1))
        (progn
          (setvar half (* 0.5 (- stripe-hi stripe-lo)
                          (sqrt (clamp (/ (- 1 tt) 0.12) 0 1))
                          (sqrt (clamp (/ tt 0.04) 0 1))))
          (setvar cc (+ (* 0.5 (+ stripe-lo stripe-hi)) (* 0.02 (sin (* tt 7)))))
          (setvar lo (- cc half))
          (setvar hi (+ cc half))
          (setvar ins (* (smoothstep (- lo 0.004) (+ lo 0.004) uu)
                         (- 1 (smoothstep (- hi 0.004) (+ hi 0.004) uu))))
          (setvar bord (* (- 1 (smoothstep 0.004 0.012 (abs (- uu lo))))
                          (step 0.001 half)))
          (setvar bord (+ bord (* (- 1 (smoothstep 0.004 0.012 (abs (- uu hi)))) (step 0.001 half))))
          (setvar col (mix col (mix stripe-color stripe-color2 (smoothstep lo hi uu)) ins))
          (setvar col (mix col border-color (clamp bord 0 1)))))

    ;; ③ 点刻 (ジッタ付きセル、最寄りの穴)
    (setvar px (* xx pit-freq))
    (setvar py (* yy pit-freq))
    (repeat (k 3)
      (repeat (m 3)
        (setvar ix (+ (floor px) (- k 1)))
        (setvar jy (+ (floor py) (- m 1)))
        (setvar cxx (+ ix 0.5 (* 0.7 (- (vnoise (make-point (+ ix 0.37) (+ jy 0.11) 1.7)) 0.5))))
        (setvar cyy (+ jy 0.5 (* 0.7 (- (vnoise (make-point (+ ix 3.1) (+ jy 5.3) 2.9)) 0.5))))
        (setvar dd (sqrt (+ (* (- px cxx) (- px cxx)) (* (- py cyy) (- py cyy)))))
        (if (< dd best) (progn (setvar best dd) (setvar bx cxx) (setvar by cyy)))))
    (setvar pit (- 1 (smoothstep 0.16 0.3 best)))
    (setvar col (* col (- 1 (* 0.45 pit))))

    ;; ④ 縦の隆条
    (setvar cst (* costa (+ (exp (* -1 (pow (/ (- uu 0.16) 0.008) 2)))
                            (exp (* -1 (pow (/ (- uu 0.25) 0.008) 2)))
                            (exp (* -1 (pow (/ (- uu 0.74) 0.008) 2)))
                            (exp (* -1 (pow (/ (- uu 0.86) 0.008) 2))))))
    (setvar col (+ col (* cst 0.35 (make-color 0.8 1.0 0.6))))

    ;; 法線: 穴の中心へ倒す (凹み)
    (setvar Nb (normalize (- Nf (* pit-depth pit
                                   (+ (* Ta (* (- px bx) 3)) (* Tb (* (- py by) 3)))))))

    ;; ⑤ 角度で青紫へずれる構造色
    (setvar cosv (clamp (dot Nb Ir) 0 1))
    (setvar col (mix col iri-color (* iridescence (pow (- 1 cosv) 1.5))))

    ;; ⑥ 光沢: specular + フレネル映り込み
    (setvar fr (+ 0.06 (* 0.94 (pow (- 1 cosv) 5))))
    (setvar refl (make-color 0 0 0))
    (if (> Kr 0)
        (progn
          (setvar rdir (reflect I Nb))
          (setvar refl (trace P rdir hitf))))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* col (+ (* Ka (ambient)) (* Kd (diffuse Nb))))
                        (* Ks (- 1 (* 0.7 pit)) (specular Nb Ir roughness))
                        (* Kr fr (+ (make-color 0.4 0.4 0.4) (* 0.6 col)) refl)))))))
(compile-shader tamamushi-shader)
(append-shader tamamushi-shader)
