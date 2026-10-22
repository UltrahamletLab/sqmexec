;;; yamamayu — ヤママユ (Antheraea yamamai) の翅: 鱗粉の瓦重ね + 帯 + 目玉模様
;;;   (SVG 細密画 2026-09-23 の移植)
;;;
;;; 座標: (transform "shader" Pg) の原点 = 翅の付け根、x = 付け根から外へ、
;;;       y = 翅の面内で x に直交。向きは (shader-space ..)。
;;;   模様は付け根からの距離 r = |(x,y)|/wing-length で決まる (帯は付け根を中心とした弧)。
;;;
;;; 鱗粉: 列 (x 方向) ピッチ scale-size、行 (y 方向) ピッチ scale-size*aspect、奇数列は半行ずらす。
;;;   1 枚は「付け根側が細く、先が丸くて 3 つの歯がある」細長い板で、長さ約 1.75 列ぶん
;;;   → 隣の列に重なる。**付け根側 (列番号の小さい方) が上** — 実物の鱗粉は先端が
;;;   外側の鱗粉の付け根を覆う。見えるのは各鱗粉の先端寄りだけになり、瓦の列ができる。
;;;   **模様の色は鱗粉の中心で 1 回だけ評価する** → 1 枚 1 色のモザイク (SVG 版と同じ)。
;;;   目玉の窓 (e<0.36) だけは鱗粉が無く、window-color の半透明 (Oi=window-opacity)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の yamamayu_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 scale-size=4 aspect=5 wing-length=6 eye-x=7 eye-y=8
;;;   eye-radius=9 base-color=10 dark-color=11 cream-color=12 pink-color=13
;;;   lilac-color=14 eye-yellow=15 eye-red=16 window-color=17 window-opacity=18
;;;   jitter=19 shadow=20

(setq yamamayu-shader
(make-shader yamamayu :keyword :surface
  (((Ka float) 0.3)
   ((Kd float) 0.8)
   ((Ks float) 0.12)
   ((roughness float) 0.3)
   ((scale-size float) 0.012)
   ((aspect float) 0.62)
   ((wing-length float) 1.0)
   ((eye-x float) 0.5)
   ((eye-y float) 0.0)
   ((eye-radius float) 0.07)
   ((base-color  color) (make-color 0.80 0.57 0.22))
   ((dark-color  color) (make-color 0.36 0.18 0.08))
   ((cream-color color) (make-color 0.98 0.92 0.75))
   ((pink-color  color) (make-color 0.78 0.38 0.36))
   ((lilac-color color) (make-color 0.70 0.58 0.52))
   ((eye-yellow  color) (make-color 0.98 0.80 0.25))
   ((eye-red     color) (make-color 0.62 0.22 0.12))
   ((window-color color) (make-color 0.95 0.90 0.80))
   ((window-opacity float) 0.35)
   ((jitter float) 0.1)
   ((shadow float) 0.3))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((q0 point) (make-point 0 0 0))
    ((xx float) 0) ((yy float) 0)
    ((aa float) 0) ((bb float) 0)
    ((ic0 float) 0) ((jc0 float) 0) ((ix float) 0) ((jy float) 0) ((off float) 0)
    ((cxx float) 0) ((cyy float) 0) ((ddx float) 0) ((ddy float) 0)
    ((wd float) 0) ((tip float) 0)
    ((k float) 0) ((m float) 0)
    ((visi float) 1000000) ((vdx float) 0) ((vdy float) 0) ((vcx float) 0) ((vcy float) 0) ((vtip float) 0)
    ((emin float) 99) ((ee float) 0)
    ((pcx float) 0) ((pcy float) 0) ((rr float) 0) ((sa float) 0) ((dd float) 0)
    ((am float) 0) ((pm float) 0) ((sm float) 0)
    ((ex float) 0) ((ey float) 0) ((eyd float) 0) ((epx float) 0)
    ((h1 float) 0)
    ((col color) (make-color 0 0 0))
    ((sh float) 1) ((str float) 1) ((edge float) 0)
    ((win float) 0))

    (setvar q0 (transform "shader" Pg))
    (setvar xx (xcomp q0))
    (setvar yy (ycomp q0))

    ;; 目玉の窓 (点そのもので判定 → 窓は鱗粉の段々にならず丸い)
    (setvar ex (/ (- xx eye-x) eye-radius))
    (setvar ey (/ (- yy eye-y) (* 1.25 eye-radius)))
    (setvar epx (sqrt (+ (* ex ex) (* ey ey))))
    (if (< epx 0.36) (setvar win 1))

    ;; ── 見えている鱗粉 (付け根側=列番号の小さい方が上) ────────────
    (setvar aa (/ xx scale-size))
    (setvar bb (/ yy (* scale-size aspect)))
    (setvar ic0 (floor aa))
    (repeat (k 4)
      (setvar ix (+ ic0 (- k 1)))
      (setvar off (* 0.5 (- ix (* 2 (floor (* ix 0.5))))))
      (setvar cxx (+ ix 0.5))
      (setvar jc0 (floor (- bb off)))
      (repeat (m 3)
        (setvar jy (+ jc0 (- m 1)))
        (setvar cyy (+ jy 0.5 off))
        (setvar ddx (- aa cxx))
        (setvar ddy (- bb cyy))
        (setvar wd (* 0.56 (+ 0.45 (* 0.55 (smoothstep -1.3 -0.2 ddx)))))
        (setvar tip (- (+ 0.45 (* 0.15 (sqrt (clamp (- 1 (* (/ ddy 0.56) (/ ddy 0.56))) 0 1))))
                       (* 0.07 (abs (sin (* 4.712 (+ (/ ddy 0.56) 1)))))))
        (if (and (< ix visi) (and (> ddx -1.3) (and (< ddx tip) (< (abs ddy) wd))))
            (progn (setvar visi ix) (setvar vdx ddx) (setvar vdy ddy)
                   (setvar vcx cxx) (setvar vcy cyy) (setvar vtip tip)))))

    ;; 付け根側の鱗粉が落とす影: その先端のすぐ外側
    (repeat (k 4)
      (setvar ix (+ ic0 (- k 1)))
      (if (< ix visi)
          (progn
            (setvar off (* 0.5 (- ix (* 2 (floor (* ix 0.5))))))
            (setvar cxx (+ ix 0.5))
            (setvar jc0 (floor (- bb off)))
            (repeat (m 3)
              (setvar jy (+ jc0 (- m 1)))
              (setvar cyy (+ jy 0.5 off))
              (setvar ddx (- aa cxx))
              (setvar ddy (- bb cyy))
              (setvar tip (- (+ 0.45 (* 0.15 (sqrt (clamp (- 1 (* (/ ddy 0.56) (/ ddy 0.56))) 0 1))))
                             (* 0.07 (abs (sin (* 4.712 (+ (/ ddy 0.56) 1)))))))
              (setvar ee (- ddx tip))
              (if (and (> ee 0) (and (< ee emin) (< (abs ddy) 0.56))) (setvar emin ee))))))
    (setvar sh (- 1 (* shadow (- 1 (smoothstep 0 0.3 emin)))))

    ;; ── 模様: 鱗粉の中心で評価 (1 枚 1 色) ──────────────────────
    (if (> visi 999999) (progn (setvar vcx aa) (setvar vcy bb)))
    (setvar pcx (* vcx scale-size))
    (setvar pcy (* vcy scale-size aspect))
    (setvar dd (sqrt (+ (* pcx pcx) (* pcy pcy))))
    (setvar rr (/ dd wing-length))
    (setvar sa (/ pcy (+ dd 0.0001)))
    (setvar h1 (vnoise (make-point (+ visi 0.37) (+ vcy 0.71) 6.13)))
    (setvar col (* base-color (+ 1 (* 0.16 (- (vnoise (make-point (* pcx 6) (* pcy 6) 0.5)) 0.5)))))
    (if (< rr 0.2) (setvar col (mix col dark-color (* 0.25 (- 1 (/ rr 0.2))))))
    ;; 内横線
    (setvar am (+ 0.30 (* 0.03 (sin (* sa 6)))))
    (if (< (abs (- rr am)) 0.011)
        (setvar col cream-color)
        (if (and (> (- rr am) -0.04) (< (- rr am) -0.011))
            (setvar col (mix col dark-color 0.6))))
    ;; 外横線 + 外側の桃色 + 亜外縁の灰紫と波線
    (setvar pm (+ 0.70 (* 0.035 (sin (* sa 7)))))
    (if (< (abs (- rr pm)) 0.011)
        (setvar col cream-color)
        (if (and (> (- rr pm) 0.011) (< (- rr pm) 0.045))
            (setvar col (mix col pink-color 0.7))
            (if (and (> (- rr pm) -0.03) (< (- rr pm) -0.011))
                (setvar col (mix col dark-color 0.65))
                (if (> (- rr pm) 0.045)
                    (progn
                      (setvar col (mix col lilac-color 0.28))
                      (setvar sm (+ 0.885 (* 0.014 (sin (* sa 55)))))
                      (if (< (abs (- rr sm)) 0.009) (setvar col (mix col dark-color 0.6)))
                      (if (> rr 0.975) (setvar col (mix col dark-color 0.3))))))))
    ;; 目玉 (鱗粉中心で)
    (setvar ex (/ (- pcx eye-x) eye-radius))
    (setvar ey (/ (- pcy eye-y) (* 1.25 eye-radius)))
    (setvar eyd (sqrt (+ (* ex ex) (* ey ey))))
    (if (< eyd 1.0)
        (if (< eyd 0.56)
            (setvar col eye-yellow)
            (if (< eyd 0.72)
                (setvar col (make-color 0.08 0.05 0.04))
                (if (< eyd 0.84)
                    (if (> ey 0) (setvar col (make-color 0.92 0.90 0.88)) (setvar col eye-red))
                    (setvar col (mix col dark-color 0.4))))))
    (setvar col (* col (+ 1 (* jitter (- (* 2 h1) 1)))))

    ;; ── 鱗粉 1 枚の陰影: 縦の条・先端の縁線・影 ─────────────────
    (setvar str (- 1 (* 0.08 (+ 0.5 (* 0.5 (cos (* vdy 40)))))))
    (setvar edge (- 1 (smoothstep 0.0 0.1 (- vtip vdx))))
    (setvar col (* col str (- 1 (* 0.35 edge)) sh))

    (if (> win 0.5)
        (progn
          (setvar Oi (* Os window-opacity))
          (setvar Ci (* Oi (* window-color (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))))
        (progn
          (setvar Oi Os)
          (setvar Ci (* Oi (+ (* col (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                              (* Ks (specular Nf Ir roughness))))))))))
(compile-shader yamamayu-shader)
(append-shader yamamayu-shader)
