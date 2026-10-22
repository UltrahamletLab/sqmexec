;;; snakescale — ヘビの鱗 (キール=竜骨つき・先の尖った瓦重ね)。
;;;   ヤマカガシの SVG 細密画 (2026-09-23) のアルゴリズムを移植
;;;
;;; 座標: (transform "shader" Pg) の x = 体軸 (頭が -x、尾が +x) / y = 体の周方向
;;;   (背の正中線が mid-y)。scale-size はワールド単位の鱗の長さ (体軸方向のピッチ)、
;;;   周方向ピッチは scale-size/aspect。向きは (shader-space ..) で合わせる。
;;;   ※平面投影なので、曲がった体 (sweep) では体に沿わない — 真っ直ぐな胴か、
;;;     shader-space で胴の向きに合わせた区間に使う。
;;;
;;; 鱗の格子: 列ピッチ 1 (体軸)、行ピッチ 1 (周方向)、奇数列は半行ずらす = 斜めの鱗列。
;;;   鱗の形は「尾側ほど細る」超楕円: |dx|^p + |dy*(1+taper*max(dx,0))|^p < 1 (p=1.6)
;;;   半径は体軸 ra=0.95・周方向 rb=0.62 → 隣と重なり、角の隙間に皮膚 (skin-color) が覗く。
;;;   **頭側 (列番号の小さい方) が上** — 前の鱗の自由縁が後ろの鱗の付け根を覆う。
;;;
;;; 見た目の要素:
;;;   ① キール: 鱗の中心線に沿った明るい稜 + 両脇の暗い溝 (keel)
;;;   ② 前の鱗が落とす影 (shadow)
;;;   ③ 鱗ごとのドーム法線 (bulge) — fishscale と同じ接線の取り方
;;;   ④ 模様 (ヤマカガシ型): 正中から band-lo..band-hi 行の帯に、左右で半周期ずれた
;;;      黒斑 (blotch-period 列ごと・duty 割合)。黒斑の間は accent-color (accent で強さ)
;;;   ⑤ 鱗ごとの色ムラ (jitter)
;;;
;;; パラメータ定義順 (shade_dr.cpp の snakescale_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 scale-size=4 aspect=5 base-color=6 blotch-color=7
;;;   accent-color=8 skin-color=9 mid-y=10 band-lo=11 band-hi=12 blotch-period=13
;;;   blotch-duty=14 accent=15 keel=16 bulge=17 jitter=18 shadow=19 taper=20

(setq snakescale-shader
(make-shader snakescale :keyword :surface
  (((Ka float) 0.2)
   ((Kd float) 0.8)
   ((Ks float) 0.5)
   ((roughness float) 0.1)
   ((scale-size float) 0.08)
   ((aspect float) 1.4)
   ((base-color   color) (make-color 0.42 0.40 0.26))
   ((blotch-color color) (make-color 0.06 0.05 0.04))
   ((accent-color color) (make-color 0.88 0.28 0.12))
   ((skin-color   color) (make-color 0.10 0.09 0.07))
   ((mid-y float) 0.0)
   ((band-lo float) 0.8)
   ((band-hi float) 6.0)
   ((blotch-period float) 3.0)
   ((blotch-duty float) 0.38)
   ((accent float) 0.0)
   ((keel float) 0.6)
   ((bulge float) 0.45)
   ((jitter float) 0.08)
   ((shadow float) 0.4)
   ((taper float) 0.5))
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
    ((aa float) 0) ((bb float) 0) ((cy0 float) 0)
    ((ra float) 0.95) ((rb float) 0.62) ((pe float) 1.6)
    ((ic0 float) 0) ((jc0 float) 0)
    ((ix float) 0) ((jy float) 0) ((off float) 0)
    ((cxx float) 0) ((cyy float) 0) ((dd float) 0)
    ((ex float) 0) ((ey float) 0)
    ((k float) 0) ((m float) 0)
    ((visi float) 1000000) ((visd float) 99)
    ((vcx float) 0) ((vcy float) 0) ((vcj float) 0)
    ((emin float) 99)
    ((dn float) 1) ((dx float) 0) ((dy float) 0)
    ((h1 float) 0)
    ((sh float) 1) ((kf float) 0) ((kg float) 0)
    ((lat float) 0) ((ph float) 0) ((inband float) 0)
    ((col color) (make-color 1 1 1))
    ((onscale float) 0))

    ;; ── 座標と接線 ──────────────────────────────────────────
    (setvar q0 (transform "shader" Pg))
    (setvar qx (transform "shader" (+ Pg (make-point hh 0 0))))
    (setvar qy (transform "shader" (+ Pg (make-point 0 hh 0))))
    (setvar qz (transform "shader" (+ Pg (make-point 0 0 hh))))
    (setvar ga (make-point (- (xcomp qx) (xcomp q0)) (- (xcomp qy) (xcomp q0)) (- (xcomp qz) (xcomp q0))))
    (setvar gb (make-point (- (ycomp qx) (ycomp q0)) (- (ycomp qy) (ycomp q0)) (- (ycomp qz) (ycomp q0))))
    (setvar Ta (normalize (- ga (* Nf (dot Nf ga)))))
    (setvar Tb (normalize (- gb (* Nf (dot Nf gb)))))
    (setvar aa (/ (xcomp q0) scale-size))
    (setvar bb (/ (- (ycomp q0) mid-y) (/ scale-size aspect)))

    ;; ── 見えている鱗 (頭側が上 / 同列なら超楕円距離の小さい方) ──
    (setvar ic0 (floor aa))
    (repeat (k 3)
      (setvar ix (+ ic0 (- k 1)))
      (setvar off (* 0.5 (- ix (* 2 (floor (* ix 0.5))))))
      (setvar cxx (+ ix 0.5))
      (setvar jc0 (floor (- bb off)))
      (repeat (m 3)
        (setvar jy (+ jc0 (- m 1)))
        (setvar cyy (+ jy 0.5 off))
        (setvar ex (/ (- aa cxx) ra))
        (setvar ey (* (/ (- bb cyy) rb) (+ 1 (* taper (clamp ex 0 1)))))
        (setvar dd (pow (+ (pow (abs ex) pe) (pow (abs ey) pe)) (/ 1 pe)))
        (if (and (< dd 1) (or (< ix visi) (and (= ix visi) (< dd visd))))
            (progn
              (setvar visi ix) (setvar visd dd)
              (setvar vcx cxx) (setvar vcy cyy) (setvar vcj jy)))))
    (setvar onscale 1)
    (if (> visi 999999) (setvar onscale 0))

    ;; ── 前の鱗の影 ───────────────────────────────────────────
    (repeat (k 3)
      (setvar ix (+ ic0 (- k 1)))
      (if (< ix visi)
          (progn
            (setvar off (* 0.5 (- ix (* 2 (floor (* ix 0.5))))))
            (setvar cxx (+ ix 0.5))
            (setvar jc0 (floor (- bb off)))
            (repeat (m 3)
              (setvar jy (+ jc0 (- m 1)))
              (setvar cyy (+ jy 0.5 off))
              (setvar ex (/ (- aa cxx) ra))
              (setvar ey (* (/ (- bb cyy) rb) (+ 1 (* taper (clamp ex 0 1)))))
              (setvar dd (- (pow (+ (pow (abs ex) pe) (pow (abs ey) pe)) (/ 1 pe)) 1))
              (if (< dd emin) (setvar emin dd))))))
    (setvar sh (- 1 (* shadow (- 1 (smoothstep 0 0.3 (clamp emin 0 1))))))

    (if (> onscale 0.5)
        (progn
          (setvar dn visd)
          (setvar dx (/ (- aa vcx) ra))
          (setvar dy (/ (- bb vcy) rb))
          (setvar h1 (vnoise (make-point (+ visi 0.37) (+ vcj 0.71) 3.13)))

          ;; ── 模様: 正中からの行数の帯に、左右で半周期ずれた斑 ──
          (setvar col base-color)
          (setvar lat (abs vcy))
          (setvar inband (* (step band-lo lat) (- 1 (step band-hi lat))))
          (setvar ph (/ visi blotch-period))
          (if (> vcy 0) (setvar ph (+ ph 0.5)))
          (setvar ph (- ph (floor ph)))
          (if (and (> inband 0.5) (< ph blotch-duty))
              (setvar col blotch-color)
              (if (and (> inband 0.5) (and (> ph (+ blotch-duty 0.08)) (< ph 0.92)))
                  (setvar col (mix base-color accent-color accent))))
          (setvar col (* col (+ 1 (* jitter (- (* 2 h1) 1)))))

          ;; ── キール: 中心線の明るい稜 + 両脇の暗い溝 ───────────
          (setvar kf (* keel (- 1 (smoothstep 0.05 0.13 (abs dy)))
                        (smoothstep -0.75 -0.35 dx) (- 1 (smoothstep 0.55 0.85 dx))))
          (setvar kg (* keel (smoothstep 0.1 0.16 (abs dy)) (- 1 (smoothstep 0.18 0.3 (abs dy)))
                        (smoothstep -0.75 -0.35 dx) (- 1 (smoothstep 0.55 0.85 dx))))
          (setvar col (* (+ (* col (+ 1 (* 0.6 kf))) (* 0.08 kf (make-color 1 1 1))) (- 1 (* 0.35 kg))))
          ;; 鱗の縁を少し暗く
          (setvar col (* col (- 1 (* 0.4 (smoothstep 0.85 1.0 dn))) sh))
          (setvar Nb (normalize (+ Nf (* bulge (+ (* Ta dx) (* Tb dy)))))))
        (progn
          (setvar col (* skin-color sh))
          (setvar Nb Nf)))

    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* col (+ (* Ka (ambient)) (* Kd (diffuse Nb))))
                        (* Ks onscale sh (specular Nb Ir roughness))))))))
(compile-shader snakescale-shader)
(append-shader snakescale-shader)
