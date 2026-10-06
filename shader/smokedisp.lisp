;;; smokedisp.lisp — fundza "RSL - Smoke Displacement" (smoke1..4 統合 Listing 5) の移植
;;;
;;; 円柱を煙の柱に見せる4層の変位:
;;;   Layer1: ノイズの瘤 (noise(P*freq)-0.5)*bump   … 符号付き = 凹凸両方
;;;   Layer2: 高さで増幅 (根元は滑らか・上ほど乱流)  … hump *= hf
;;;   Layer3: トランペット (上端の開き)              … += pow(hf,5)*trumpet
;;;   Layer4: x/z の揺らぎ (柱ごとの横ずれ)
;;; 原典の Layer4 は P の横シフトだが、sqm の変位はスカラー (法線方向 d-=amp·disp)。
;;; 横シフト w(hf) の半径方向射影 dot(w, r̂) は小変位で等価なのでそれで写す。
;;; 原典の s,t (円柱の高さパラメータ) は SDF に無いので ymin/ymax (ローカル高さ) から
;;; hf を復元する。P はオブジェクトのローカル座標。
;;;
;;; パラメータ定義順 (shade_dr.cpp の smokedisp_dparams[] と一致必須):
;;;   freq=0 bump=1 trumpet=2 sway=3 sway-freq=4 ymin=5 ymax=6
;;;
;;; 使い方 (シーン):
;;;   (displace (amp 0.25) (mode dsl) (shader smokedisp) (lipschitz 12)
;;;             (param freq 4) (param bump 1.0) (param trumpet 1.2)
;;;             (param sway 0.8) (param sway-freq 2.5)
;;;             (param ymin 0.0) (param ymax 2.2))
;;;   ※ lipschitz ≈ bump*freq + 5*trumpet/(ymax-ymin) + sway*sway-freq を起点に
;;;     倍にして絵が変わらないか確かめる (机上見積もりを信用しない)。

(setq smokedisp-shader
(make-shader smokedisp :keyword :displacement
  (((freq float) 4.0)
   ((bump float) 1.0)
   ((trumpet float) 1.2)
   ((sway float) 0.8)
   ((sway-freq float) 2.5)
   ((ymin float) 0.0)
   ((ymax float) 2.2)
   ((phase float) 0.0))   ; 立ち昇り: ノイズ領域を y 方向へスクロール
  (enter (((hf float) 0)
          ((n1 float) 0)
          ((xx float) 0) ((zz float) 0)
          ((rl float) 0) ((rx float) 0) ((rz float) 0)
          ((wx float) 0) ((wz float) 0)
          ((h float) 0))
    ;; 高さ割合 0(根元)..1(上端)
    (setvar hf (clamp (/ (- (ycomp P) ymin) (- ymax ymin)) 0 1))
    ;; Layer1+2: 符号付きノイズ瘤 × 高さランプ
    (setvar n1 (vnoise (* (- P (make-point 0 phase 0)) freq)))
    (setvar h (* (- n1 0.5) bump hf))
    ;; Layer3: トランペット (上端の開き)
    (setvar h (+ h (* trumpet (pow hf 5))))
    ;; Layer4: 横揺れ w(hf) の半径方向射影 (根元はフェード)
    (setvar xx (xcomp P))
    (setvar zz (zcomp P))
    (setvar rl (clamp (sqrt (+ (* xx xx) (* zz zz))) 0.0001 1000))
    (setvar rx (/ xx rl))
    (setvar rz (/ zz rl))
    (setvar wx (- (* 2 (vnoise (make-point (+ (* hf sway-freq) (* 0.35 phase)) 0.37 0.71))) 1))
    (setvar wz (- (* 2 (vnoise (make-point 0.19 (+ (* hf sway-freq) (* 0.35 phase)) 0.53))) 1))
    (setvar h (+ h (* sway hf (+ (* wx rx) (* wz rz)))))
    (setvar disp h))))
(compile-shader smokedisp-shader)
(append-shader smokedisp-shader)
