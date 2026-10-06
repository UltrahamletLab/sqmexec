;;; bsdfwoodv — パストレーシング (-Q) 用の木。**年輪軸が縦 (y)** の版。
;;;
;;; 既存の bsdfwood は年輪軸が x 方向 = 横倒しの丸太で、立ち姿の像に貼ると
;;; 体を横切る縞になり「木」に見えない。こちらは丸太を立てて彫り出した形で、
;;; 年輪が体に巻きつく (人形・柱・仏像の木取り)。
;;;
;;; :volume クラスの PT 材質規約: Cl = アルベド / Oi = (roughness, metallic, transmission)。
;;;
;;; ⚠ アルベドは**リニア**。実測 sRGB をそのまま入れると ACES 通過後に白茶ける。
;;;
;;; 使い方 (SSQ):
;;;   (surface (bsdf bsdfwoodv) (param ring-scale 26)
;;;            (param axis-x 0.0) (param axis-z 0.0))

(setq bsdfwoodv-shader

(make-shader bsdfwoodv :keyword :volume
      (((ring-scale  float) 26.0)     ; 年輪の密度 (大 = 細かい)
       ((grain       float) 0.55)     ; 年輪を乱すノイズ量 (0 = 同心円)
       ((grain-scale float) 2.4)      ; 乱れの空間スケール
       ((axis-x      float) 0.0)      ; 丸太軸 (y方向) の x 位置
       ((axis-z      float) 0.0)      ; 同 z 位置
       ((light-wood  color) (make-color 0.430 0.255 0.120))
       ((dark-wood   color) (make-color 0.185 0.095 0.042))
       ((fiber-amt   float) 0.030)    ; 縦の導管 (木理)。年輪と直交する細い筋
       ((fiber-scale float) 90.0)
       ((rough-base  float) 0.52)     ; 早材 (明部)
       ((rough-dark  float) 0.40))    ; 晩材 (暗部。やや艶)

  (enter (((dx    float) 0.0)
          ((dz    float) 0.0)
          ((rad   float) 0.0)
          ((warp  float) 0.0)
          ((ring  float) 0.0)
          ((fib   float) 0.0)
          ((q     point) (make-point 0 0 0))
          ((col   color) (make-color 0 0 0))
          ((rg    float) 0.0))

    ;; ① 丸太軸 (y に平行) からの距離 = 年輪の半径
    (setvar dx (- (xcomp Pg) axis-x))
    (setvar dz (- (zcomp Pg) axis-z))
    (setvar rad (sqrt (+ (* dx dx) (* dz dz))))

    ;; ② 年輪を fBm で乱す (真円だと木口の印刷物に見える)
    (setvar q (make-point (* (xcomp Pg) grain-scale)
                          (* (ycomp Pg) (* grain-scale 0.35))
                          (* (zcomp Pg) grain-scale)))
    (setvar warp (* grain (- (vfbm q 4.0) 0.5)))
    (setvar ring (* ring-scale (+ rad warp)))
    (setvar ring (- ring (floor ring)))          ; = mod 1

    ;; ③ 晩材 (暗い細い帯) を年輪の一部に置く。幅を狭くすると本物らしい
    (setvar ring (- (smoothstep 0.0 0.42 ring) (smoothstep 0.55 1.0 ring)))
    (setvar col (mix dark-wood light-wood ring))

    ;; ④ 縦の導管 (木理)。**y を粗く xz を細かく**すると縦筋になる
    (setvar q (make-point (* (xcomp Pg) fiber-scale)
                          (* (ycomp Pg) (* fiber-scale 0.06))
                          (* (zcomp Pg) fiber-scale)))
    (setvar fib (- (vnoise q) 0.5))
    (setvar col (+ col (* fiber-amt fib)))

    (setvar Cl col)
    (setvar rg (+ (* rough-dark (- 1.0 ring)) (* rough-base ring)))
    (setvar Oi (make-color rg 0.0 0.0))
)))

(compile-shader bsdfwoodv-shader)
(append-shader bsdfwoodv-shader)
