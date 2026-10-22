;;; smokerim.lisp — fundza "RSL - Smoke Displacement" Listing 6 (rim surface) の移植
;;;
;;; 煙のシルエットだけを残す縁不透明シェーダー:
;;;   ・視線と法線の内積 dot が小さい (=縁) ほど不透明、正面ほど透明
;;;   ・縁の閾値 rw をノイズで揺らして煙のむらを出す
;;;   ・高さで全体をフェード Oi *= (1 - pow(hf, fade)) — 上ほど薄く消える
;;; 原典 flip=1 (縁が濃い) 固定。原典の s は高さパラメータなので ymin/ymax
;;; (ワールド高さ) から hf を復元する。
;;; sqm の Oi は <0.05 で「背景色の塗り」になる (穴でない) ので下限 0.06 に
;;; クランプし、0.06..0.999 の半透明帯 = 屈折レイ合成 (scene roi 1.0 で素通し)
;;; に載せる。Ci は RenderMan 流に Oi 前乗算 (flame.lisp と同じ)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の smokerim_params[] と一致必須):
;;;   rim-width=0 Krim=1 fade=2 noise-freq=3 ymin=4 ymax=5

(setq smokerim-shader
(make-shader smokerim :keyword :surface
  (((rim-width float) 0.6)
   ((Krim float) 0.4)
   ((fade float) 0.5)
   ((noise-freq float) 3.0)
   ((ymin float) 0.0)
   ((ymax float) 2.2)
   ((phase float) 0.0))   ; 立ち昇り: むらノイズを y 方向へスクロール
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((dt float) 0)
          ((rw float) 0)
          ((hf float) 0)
          ((oiv float) 0))
    (setvar dt (clamp (dot Ir Nf) 0 1))
    (setvar rw (+ rim-width (* Krim (noise (* noise-freq (- Pg (make-point 0 phase 0)))))))
    ;; flip=1: 縁 (dot→0) が濃く、正面 (dot→1) が透ける
    (setvar oiv (- 1 (smoothstep rw 1.0 dt)))
    ;; 高さフェード (上ほど薄い)
    (setvar hf (clamp (/ (- (ycomp Pg) ymin) (- ymax ymin)) 0 1))
    (setvar oiv (* oiv (- 1 (pow hf fade))))
    (setvar oiv (clamp oiv 0.06 1.0))
    (setvar Oi (* Os oiv))
    (setvar Ci (* Oi Cs)))))
(compile-shader smokerim-shader)
(append-shader smokerim-shader)
