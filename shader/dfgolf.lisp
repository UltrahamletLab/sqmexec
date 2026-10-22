;;; dfgolf — ゴルフボールの丸皿ディンプル (blob deform の DSL 模様, 2026-08-03)
;;;
;;; dfdimple (sin³格子の pow 潰し) は窪みの縁が格子の対角に引きずられて丸くない。
;;; こちらは **3D セル格子の最近接中心からの距離** d で球冠状のボウルを彫る:
;;;   c = セル中心 (floor(P·freq)+0.5)/freq
;;;   t = clamp(1 - (d/r)², 0, 1)         ; r = 0.5·rad/freq (セル半幅×rad)
;;;   g = -smoothstep(0,1,t)              ; 縁は真円・C¹ 接続・底は平らめ
;;; rad<1 なら窪み同士は接触せず、自セルだけ見れば最近接 (ジッタ無し=走査不要)。
;;; 負値を返す = 内向きに彫る (engine は d -= amp·disp)。
;;;
;;; Lipschitz: |∇g| ≤ 3/r = 6·freq/rad (smoothstep の最大勾配1.5×2d/r²の上界)。
;;;   シーン申告はその1.5倍を起点に倍掃引で裏取り。
;;;
;;; 使い方:
;;;   (deform (mode dsl)(shader dfgolf)(amp 0.03)(lipschitz 260)
;;;           (param freq 11)(param rad 0.85))
;;;
;;; パラメータ定義順 (shade_dr.cpp の dfgolf_dparams[] と一致必須):
;;;   freq=0 rad=1
(setq dfgolf-shader
(make-shader dfgolf :keyword :displacement
  (((freq float) 11.0)    ; セル格子の細かさ (単位長あたりのセル数)
   ((rad  float) 0.85))   ; 窪み半径 (セル半幅に対する割合 0..1)
  (enter (((cx float) 0) ((cy float) 0) ((cz float) 0)
          ((dx float) 0) ((dy float) 0) ((dz float) 0)
          ((dd float) 0) ((rw float) 0) ((tt float) 0))
    (setvar cx (/ (+ (floor (* freq (xcomp P))) 0.5) freq))
    (setvar cy (/ (+ (floor (* freq (ycomp P))) 0.5) freq))
    (setvar cz (/ (+ (floor (* freq (zcomp P))) 0.5) freq))
    (setvar dx (- (xcomp P) cx))
    (setvar dy (- (ycomp P) cy))
    (setvar dz (- (zcomp P) cz))
    (setvar dd (sqrt (+ (* dx dx) (+ (* dy dy) (* dz dz)))))
    (setvar rw (/ (* 0.5 (clamp rad 0.05 1.0)) freq))
    (setvar tt (clamp (- 1 (/ (* dd dd) (* rw rw))) 0 1))
    (setvar disp (- 0 (smoothstep 0 1 tt))))))
(compile-shader dfgolf-shader)
(append-shader dfgolf-shader)
