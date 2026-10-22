;;; babynotch — 足指つけ根のノッチ = 足裏のしわ (BabyToy ToeCaps 転写用)
;;;
;;; 原典: h = 軸 a→b 上の射影パラメータ t (clamp 0..1) に対し
;;;   g = 1 - min(1, |t - x|*k);  d -= g^4 * y   (y<0 なので実際は彫り)
;;; engine は d - amp*h → h = -g^4, amp = |y|。
;;; P はノードローカル (足サブツリーは translate(ankle) の内側 = 足ローカル)。
(setq babynotch-shader

(make-shader babynotch :keyword :displacement
      (((ax float) 0.0)         ; 軸の始点 a (足ローカル)
       ((ay float) 0.0)
       ((az float) 0.0)
       ((bx float) 0.0)         ; 軸の終点 b
       ((by float) 1.0)
       ((bz float) 0.0)
       ((xx float) 0.5)         ; ノッチ位置 (t)
       ((kk float) 8.0))        ; ノッチの鋭さ

  (enter (((dx float) 0.0)
          ((dy float) 0.0)
          ((dz float) 0.0)
          ((ex float) 0.0)
          ((ey float) 0.0)
          ((ez float) 0.0)
          ((tt float) 0.0)
          ((gg float) 0.0))

    (setvar dx (- (xcomp P) ax))
    (setvar dy (- (ycomp P) ay))
    (setvar dz (- (zcomp P) az))
    (setvar ex (- bx ax))
    (setvar ey (- by ay))
    (setvar ez (- bz az))
    (setvar tt (/ (+ (+ (* dx ex) (* dy ey)) (* dz ez))
                  (+ (+ (* ex ex) (* ey ey)) (* ez ez))))
    (setvar tt (clamp tt 0.0 1.0))
    (setvar gg (- 1.0 (clamp (* (abs (- tt xx)) kk) 0.0 1.0)))
    (setvar disp (- 0.0 (* (* gg gg) (* gg gg))))
)))

(compile-shader babynotch-shader)
(append-shader babynotch-shader)
