;;; fishscale — 魚の鱗 (円鱗の瓦重ね)。マダイの SVG 細密画 (2026-09-23) のアルゴリズムを移植
;;;
;;; 座標: (transform "shader" Pg) の x = 体軸 (頭が -x、尾が +x) / y = 背腹 (背が +y)。
;;;   向き・位置はシーンの (shader-space ..) で合わせる。scale-size はワールド単位の鱗ピッチ。
;;;
;;; 鱗の格子: 列 (x 方向) ピッチ 1、行 (y 方向) ピッチ 1、奇数列は半行ずらす (六方格子)。
;;;   各鱗は半径 rad=0.78 の円。隣と重なるので、ある点を覆う候補は近傍 3列×3行 = 9 枚。
;;;   **頭側 (列番号が小さい) の鱗が上** — 魚の鱗は前の鱗の後縁が後ろの鱗の付け根を覆う。
;;;   同じ列なら中心に近い方。どれにも入らない点は無い (rad 0.78 > 六方格子の被覆半径)。
;;;
;;; 見た目の要素 (SVG 版と同じ):
;;;   ① 見えている鱗の後縁 (尾側) だけ明るい縁取り + その外側の暗い縁線
;;;   ② 同心の成長線 (circuli) を薄く
;;;   ③ 上に重なる前の鱗が落とす影 (前の鱗の円周からの距離で減衰)
;;;   ④ 背→腹の色グラデーション (shader 空間の y) と鱗ごとの色ムラ
;;;   ⑤ マダイの青い斑点 (鱗ごとのハッシュで spot-density の割合、spot-min-y より背側)
;;;   ⑥ 鱗ごとのドーム状の法線 (bulge) — 鱗の中心から外へ法線を倒す。接線は
;;;      shader 空間の x,y 軸をワールドへ戻したもの (transform の差分でヤコビアンを取る)
;;;   ⑦ 銀の照り (sheen × フレネル) — 鱗の銀色の反射層の代わり
;;;
;;; パラメータ定義順 (shade_dr.cpp の fishscale_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 scale-size=4 back-color=5 belly-color=6
;;;   belly-y=7 back-y=8 spot-color=9 spot-density=10 spot-min-y=11
;;;   bulge=12 rim=13 jitter=14 sheen=15 shadow=16

(setq fishscale-shader
(make-shader fishscale :keyword :surface
  (((Ka float) 0.25)
   ((Kd float) 0.75)
   ((Ks float) 0.6)
   ((roughness float) 0.08)
   ((scale-size float) 0.1)
   ((back-color  color) (make-color 0.80 0.22 0.26))
   ((belly-color color) (make-color 0.96 0.84 0.82))
   ((belly-y float) -0.3)
   ((back-y  float) 0.5)
   ((spot-color color) (make-color 0.35 0.80 1.0))
   ((spot-density float) 0.15)
   ((spot-min-y float) 0.0)
   ((bulge float) 0.35)
   ((rim float) 0.55)
   ((jitter float) 0.08)
   ((sheen float) 0.35)
   ((shadow float) 0.35))
  (enter (
    ((Nn point) (normalize N))
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
    ((aa float) 0) ((bb float) 0) ((yy float) 0)
    ((rad float) 0.78)
    ((ic0 float) 0) ((jc0 float) 0)
    ((ix float) 0) ((jy float) 0) ((off float) 0)
    ((cxx float) 0) ((cyy float) 0) ((dd float) 0)
    ((k float) 0) ((m float) 0)
    ((visi float) 1000000) ((visd float) 99)
    ((vcx float) 0) ((vcy float) 0) ((vcj float) 0)
    ((emin float) 99)
    ((dn float) 0) ((dx float) 0) ((dy float) 0)
    ((h1 float) 0) ((h2 float) 0)
    ((sh float) 1) ((ring float) 1) ((rimf float) 0) ((edg float) 0)
    ((sd float) 0) ((spf float) 0)
    ((col color) (make-color 1 1 1))
    ((fres float) 0))

    ;; ── 座標と接線 (shader 空間 x,y のワールド勾配) ──────────────
    (setvar q0 (transform "shader" Pg))
    (setvar qx (transform "shader" (+ Pg (make-point hh 0 0))))
    (setvar qy (transform "shader" (+ Pg (make-point 0 hh 0))))
    (setvar qz (transform "shader" (+ Pg (make-point 0 0 hh))))
    (setvar ga (make-point (- (xcomp qx) (xcomp q0)) (- (xcomp qy) (xcomp q0)) (- (xcomp qz) (xcomp q0))))
    (setvar gb (make-point (- (ycomp qx) (ycomp q0)) (- (ycomp qy) (ycomp q0)) (- (ycomp qz) (ycomp q0))))
    (setvar Ta (normalize (- ga (* Nf (dot Nf ga)))))
    (setvar Tb (normalize (- gb (* Nf (dot Nf gb)))))
    (setvar yy (ycomp q0))
    (setvar aa (/ (xcomp q0) scale-size))
    (setvar bb (/ (ycomp q0) scale-size))

    ;; ── 見えている鱗を探す (頭側=列番号の小さい方が上) ─────────
    (setvar ic0 (floor aa))
    (repeat (k 3)
      (setvar ix (+ ic0 (- k 1)))
      (setvar off (* 0.5 (- ix (* 2 (floor (* ix 0.5))))))
      (setvar cxx (+ ix 0.5))
      (setvar jc0 (floor (- bb off)))
      (repeat (m 3)
        (setvar jy (+ jc0 (- m 1)))
        (setvar cyy (+ jy 0.5 off))
        (setvar dd (sqrt (+ (* (- aa cxx) (- aa cxx)) (* (- bb cyy) (- bb cyy)))))
        (if (and (< dd rad) (or (< ix visi) (and (= ix visi) (< dd visd))))
            (progn
              (setvar visi ix) (setvar visd dd)
              (setvar vcx cxx) (setvar vcy cyy) (setvar vcj jy)))))
    (if (> visi 999999)
        (progn (setvar visi ic0) (setvar visd rad)
               (setvar vcx (+ ic0 0.5)) (setvar vcy bb) (setvar vcj (floor bb))))

    ;; ── 前の鱗が落とす影: 自分より頭側の円周までの距離 ─────────
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
              (setvar dd (- (sqrt (+ (* (- aa cxx) (- aa cxx)) (* (- bb cyy) (- bb cyy)))) rad))
              (if (< dd emin) (setvar emin dd))))))
    (setvar sh (- 1 (* shadow (- 1 (smoothstep 0 0.25 (clamp emin 0 1))))))

    ;; ── 鱗の中の局所座標 ─────────────────────────────────────
    (setvar dn (/ visd rad))
    (setvar dx (/ (- aa vcx) rad))
    (setvar dy (/ (- bb vcy) rad))
    (setvar h1 (vnoise (make-point (+ visi 0.37) (+ vcj 0.71) 3.13)))
    (setvar h2 (vnoise (make-point (+ visi 5.19) (+ vcj 2.23) 7.77)))

    ;; ── 色: 背腹グラデーション + ムラ ─────────────────────────
    (setvar col (* (mix belly-color back-color (smoothstep belly-y back-y yy))
                   (+ 1 (* jitter (- (* 2 h1) 1)))))
    ;; 成長線
    (setvar ring (- 1 (* 0.07 (+ 0.5 (* 0.5 (sin (* dn 45)))) (- 1 (smoothstep 0.8 0.9 dn)))))
    (setvar col (* col ring))
    ;; 青い斑点
    (if (and (< h2 spot-density) (> yy spot-min-y))
        (progn
          (setvar sd (sqrt (+ (* (- dx 0.25) (- dx 0.25)) (* dy dy))))
          (setvar spf (- 1 (smoothstep 0.12 0.3 sd)))
          (setvar col (mix col spot-color spf))))
    ;; 後縁の明るい縁取りと、その外の暗い縁線
    (setvar rimf (* rim (smoothstep 0.72 0.9 dn) (- 1 (smoothstep 0.93 0.99 dn)) (smoothstep 0.1 0.6 dx)))
    (setvar col (mix col (+ (* col 0.5) (make-color 0.5 0.47 0.45)) rimf))
    (setvar edg (* (smoothstep 0.93 1.0 dn) (smoothstep -0.2 0.3 dx)))
    (setvar col (* col (- 1 (* 0.35 edg)) sh))

    ;; ── 鱗ごとのドーム法線 ──────────────────────────────────
    (setvar Nb (normalize (+ Nf (* bulge (+ (* Ta dx) (* Tb dy))))))
    (setvar fres (- 1 (clamp (dot Nb Ir) 0 1)))

    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* col (+ (* Ka (ambient)) (* Kd (diffuse Nb))))
                        (* Ks sh (specular Nb Ir roughness))
                        (* sheen fres fres sh (+ (make-color 0.45 0.45 0.5) (* 0.4 col)))))))))
(compile-shader fishscale-shader)
(append-shader fishscale-shader)
