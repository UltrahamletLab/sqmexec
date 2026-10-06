;;; osamushi — オサムシ (オオルリオサムシ風) の上翅 (SVG 細密画 2026-09-23 の移植)
;;;
;;; 座標: (transform "shader" Pg) の x = 横 (縫合線 x=0、左右対称に |x|)
;;;       y = 縦 (体軸)。向きは (shader-space ..)。uu = |x|/half-width (縫合線 0 → 外縁 1)。
;;;
;;; 見た目の要素:
;;;   ① 金属色の横グラデーション: 縫合線の深緑 → 緑 → 黄 → 橙 → 外縁の赤銅
;;;   ② 条線 (striae): uu 方向に n-striae 本。通常の条は点刻の縦列
;;;      (y 方向ピッチ pit-pitch の円い穴、暗い)
;;;   ③ 4 本おきの一次間室: 長さのばらつく隆起 (tubercle) の鎖 — 光る楕円粒 +
;;;      法線を粒の中心から外へ倒す (盛り上がり)
;;;   ④ 条の間の細かい光る粒 (granule)
;;;   ⑤ 外縁の明るい縁取り (rim-color)
;;;
;;; パラメータ定義順 (shade_dr.cpp の osamushi_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 Kr=4 half-width=5 suture-color=6 green-color=7
;;;   yellow-color=8 margin-color=9 rim-color=10 tubercle-color=11 n-striae=12
;;;   pit-pitch=13 tub-len=14 bulge=15 granule=16

(setq osamushi-shader
(make-shader osamushi :keyword :surface
  (((Ka float) 0.2)
   ((Kd float) 0.65)
   ((Ks float) 0.7)
   ((roughness float) 0.06)
   ((Kr float) 0.2)
   ((half-width float) 0.5)
   ((suture-color color) (make-color 0.03 0.30 0.20))
   ((green-color  color) (make-color 0.20 0.72 0.32))
   ((yellow-color color) (make-color 0.70 0.74 0.20))
   ((margin-color color) (make-color 0.62 0.14 0.08))
   ((rim-color    color) (make-color 1.00 0.60 0.28))
   ((tubercle-color color) (make-color 0.55 1.00 0.62))
   ((n-striae float) 15.0)
   ((pit-pitch float) 0.018)
   ((tub-len float) 0.045)
   ((bulge float) 0.5)
   ((granule float) 0.5))
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
    ((sc float) 0) ((kc float) 0) ((du float) 0) ((colw float) 0)
    ((dxw float) 0) ((seg float) 0) ((sf float) 0) ((segl float) 0) ((hs float) 0)
    ((ey float) 0) ((ex float) 0) ((er float) 0) ((tub float) 0)
    ((cellp float) 0) ((fy float) 0) ((pr float) 0) ((pit float) 0)
    ((gn float) 0) ((rimf float) 0)
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
    (setvar Nb Nf)

    ;; ① 金属色の横グラデーション
    (setvar col (mix suture-color green-color (smoothstep 0.0 0.3 uu)))
    (setvar col (mix col yellow-color (smoothstep 0.55 0.8 uu)))
    (setvar col (mix col (mix rim-color margin-color 0.5) (smoothstep 0.8 0.92 uu)))
    (setvar col (mix col margin-color (smoothstep 0.92 1.0 uu)))

    ;; ② ③ 条線: 最寄りの条番号 kc と、条からの横ずれ (ワールド単位 dxw)
    (setvar sc (* uu (+ n-striae 1)))
    (setvar kc (floor (+ sc 0.5)))
    (setvar du (- sc kc))
    (setvar colw (/ half-width (+ n-striae 1)))
    (setvar dxw (* du colw))
    (if (and (> kc 0.5) (< kc (+ n-striae 0.5)))
        (if (< (- kc (* 4 (floor (* kc 0.25)))) 0.5)
            ;; 一次間室: 隆起の鎖 (長さは節ごとのハッシュでばらつく)
            (progn
              (setvar seg (floor (+ (/ yy tub-len) (* 3.7 kc))))
              (setvar segl (+ 0.62 (* 0.3 (vnoise (make-point seg kc 4.1)))))
              (setvar sf (- (+ (/ yy tub-len) (* 3.7 kc)) seg))
              (setvar ey (/ (- sf 0.5) (* 0.5 segl)))
              (setvar ex (/ dxw (* 0.34 colw)))
              (setvar er (sqrt (+ (* ex ex) (* ey ey))))
              (setvar tub (- 1 (smoothstep 0.8 1.0 er)))
              (setvar col (mix col (mix tubercle-color (* col 0.6) (clamp er 0 1)) tub))
              (setvar col (* col (- 1 (* 0.5 (smoothstep 0.85 1.0 er) (- 1 (smoothstep 1.0 1.2 er))))))
              (setvar Nb (normalize (+ Nf (* bulge tub
                                             (+ (* Ta (* sgn ex 0.8)) (* Tb (* ey 0.8))))))))
            ;; 通常の条: 点刻の縦列
            (progn
              (setvar cellp (/ yy pit-pitch))
              (setvar fy (* (- cellp (floor cellp) 0.5) pit-pitch))
              (setvar pr (* 0.22 colw (+ 0.8 (* 0.4 (- 1 uu)))))
              (setvar pit (- 1 (smoothstep (* 0.6 pr) pr (sqrt (+ (* dxw dxw) (* fy fy))))))
              (setvar col (* col (- 1 (* 0.55 pit))))
              (setvar Nb (normalize (- Nf (* 0.6 pit (+ (* Ta (* sgn (/ dxw pr))) (* Tb (/ fy pr))))))))))

    ;; ④ 条の間の細かい光る粒
    (setvar gn (vnoise (* Pg 260)))
    (setvar col (+ col (* granule (smoothstep 0.78 0.9 gn) 0.25 (make-color 0.8 1.0 0.85))))

    ;; ⑤ 外縁の縁取り
    (setvar rimf (* (smoothstep 0.955 0.975 uu) (- 1 (smoothstep 0.99 1.0 uu))))
    (setvar col (mix col rim-color (* 0.8 rimf)))

    (setvar cosv (clamp (dot Nb Ir) 0 1))
    (setvar fr (+ 0.05 (* 0.95 (pow (- 1 cosv) 5))))
    (setvar refl (make-color 0 0 0))
    (if (> Kr 0)
        (progn
          (setvar rdir (reflect I Nb))
          (setvar refl (trace P rdir hitf))))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* col (+ (* Ka (ambient)) (* Kd (diffuse Nb))))
                        (* Ks (specular Nb Ir roughness))
                        (* Kr fr (+ (make-color 0.3 0.3 0.3) (* 0.7 col)) refl)))))))
(compile-shader osamushi-shader)
(append-shader osamushi-shader)
