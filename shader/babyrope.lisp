;;; babyrope — 臍帯の撚りロープ畝 (BabyToy dCord 転写用)
;;;
;;; 原典 (螺旋ワープ後のチューブ方位角に沿う畝):
;;;   up = p + (sin(fg*y), 0, cos(fg*y)) * rr
;;;   a  = atan2(up.x - axx, up.z)
;;;   d += sin(fa*a + fy*y) * .03
;;; engine は d - amp*h → h = -sin(...), amp=.03。P はワールド (臍帯は無変換)。
;;; lipschitz: 表面 (半径≈.13) で |∇h| ≈ fa/.13 + fy + ワープ分 ≈ 40 前後を申告。
(setq babyrope-shader

(make-shader babyrope :keyword :displacement
      (((axx float) 1.0)        ; 軸の x (原典 1)
       ((rr  float) 0.2)        ; 螺旋オフセット
       ((fg  float) 2.0)        ; 螺旋の位相速度 (2y)
       ((fa  float) 3.0)        ; 畝の本数 (方位角周波数)
       ((fyy float) 7.0))       ; 畝の縦送り

  (enter (((gg float) 0.0)
          ((ux float) 0.0)
          ((uz float) 0.0)
          ((aa float) 0.0))

    (setvar gg (* fg (ycomp P)))
    (setvar ux (- (+ (xcomp P) (* rr (sin gg))) axx))
    (setvar uz (+ (zcomp P) (* rr (cos gg))))
    (setvar aa (atan2 ux uz))
    (setvar disp (- 0.0 (sin (+ (* fa aa) (* fyy (ycomp P))))))
)))

(compile-shader babyrope-shader)
(append-shader babyrope-shader)
