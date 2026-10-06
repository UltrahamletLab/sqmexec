;;; bsdfstripe — パストレーシング (-Q) 用。縦ストライプの壁紙。
;;;
;;; :volume クラスの PT 材質規約 (詳細は bsdfchecker.lisp 冒頭)。
;;;   Cl = アルベド / Oi = (roughness, metallic, transmission) / t = IOR
;;;
;;; 狙い: **ガラスの背後に置いて、屈折で縦線が曲がるのを見せる**面。
;;; 無地の壁だとガラスが白い靄にしか見えない。目地 (bsdftile) と違い
;;; ストライプは**一方向の直線**なので、ボウルの曲率がそのまま歪みとして読める。
;;;
;;; 実物の縞壁紙は「地=マット / 縞=サテン」の艶違いで柄を出しているものが多く、
;;; 色差をほとんど付けなくても斜光で縞が浮く。roughness を分けてあるのはそのため。
;;; 太い縞の中央に細いピンストライプを1本入れると一気に壁紙らしくなる。
;;;
;;; 縞は**縦**に走る (= 水平方向の座標で変調)。面の向きは Ng から選ぶので
;;; z 向きの壁にも x 向きの壁にも同じシェーダーを貼れる。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color 1 1 1) (kd 1) (bsdf bsdfstripe)
;;;            (param width 0.36) (param ratio 0.42))

(setq bsdfstripe-shader

(make-shader bsdfstripe :keyword :volume
      (((width        float) 0.36)                          ; 縞の周期 (ワールド)
       ((ratio        float) 0.42)                          ; 周期のうち縞が占める割合
       ((ground-color color) (make-color 0.62 0.58 0.52))   ; 地
       ((stripe-color color) (make-color 0.70 0.66 0.60))   ; 縞 (地と近い色でよい)
       ((accent       float) 0.018)                         ; ピンストライプの半幅 (周期比)
       ((accent-color color) (make-color 0.34 0.30 0.27))   ; ピンストライプ
       ((soft         float) 0.010)                         ; 縁のぼかし (周期比)
       ((rough-ground float) 0.62)                          ; 地 (マット)
       ((rough-stripe float) 0.20)                          ; 縞 (サテン)
       ((grain        float) 0.020))                        ; 紙の地合い

  ;; ※ローカル名は SGV グローバル (u v s t N P L I E Cs Cl Ci Oi ..) と衝突不可
  (enter (((ax float) 0.0) ((ay float) 0.0) ((az float) 0.0)
          ((wx float) 0.0) ((wy float) 0.0) ((wz float) 0.0)
          ((uu float) 0.0) ((tt float) 0.0) ((dd float) 0.0)
          ((mm float) 0.0) ((aa float) 0.0)
          ((rg float) 0.0) ((lo float) 0.0)
          ((col color) (make-color 0 0 0))
          ((q  point) (make-point 0 0 0)))

    ;; ── 水平方向の座標を面の向きから選ぶ ─────────────────────────────
    ;; (step edge x) = x>=edge で 1。max が無いので step の積で最大の軸を出す
    (setvar ax (abs (xcomp Ng)))
    (setvar ay (abs (ycomp Ng)))
    (setvar az (abs (zcomp Ng)))
    (setvar wy (* (step ax ay) (step az ay)))     ; 床/天井 → x で変調
    (setvar wz (* (- 1.0 wy) (step ax az)))       ; z 向きの壁 → x
    (setvar wx (- 1.0 (+ wy wz)))                 ; x 向きの壁 → z
    (setvar uu (+ (* (+ wy wz) (xcomp Pg)) (* wx (zcomp Pg))))

    ;; ── 周期内の位置 [0,1) ───────────────────────────────────────────
    ;; ⚠ mod は負を返しうる。そのままだと軸の負側で縞が反転する
    (setvar tt (mod (/ uu width) 1.0))
    (setvar tt (mod (+ tt 1.0) 1.0))

    ;; 太い縞: [0, ratio) を占める。両端をぼかす
    (setvar mm (* (smoothstep 0.0 soft tt)
                  (smoothstep 0.0 soft (- ratio tt))))

    ;; ピンストライプ: 地の帯の中央に細く1本
    (setvar dd (abs (- tt (+ ratio (* 0.5 (- 1.0 ratio))))))
    (setvar aa (- 1.0 (smoothstep accent (+ accent soft) dd)))

    ;; 紙の地合い (無いと塗り分けたプラスチックに見える)
    (setvar q (make-point (* (xcomp Pg) 190.0)
                          (* (ycomp Pg) 190.0)
                          (* (zcomp Pg) 190.0)))
    (setvar lo (* grain (- (vnoise q) 0.5)))

    (setvar col (mix ground-color stripe-color mm))
    (setvar col (mix col accent-color aa))
    (setvar Cl (+ col (make-color lo lo (* lo 0.9))))

    ;; ⚠ (mix a b f) は color 専用。float の補間は素の算術で書く
    (setvar rg (+ rough-ground (* (- rough-stripe rough-ground) mm)))
    (setvar Oi (make-color rg 0.0 0.0))
)))

(compile-shader bsdfstripe-shader)
(append-shader bsdfstripe-shader)
