;;; clothweave — 粗い織り布の変位シェーダー (頭巾・前掛け・布袋)
;;;
;;; 「ひとつ目ころん」の頭巾のために書いた。参照画では**麻のような粗い平織り**で、
;;; 経糸と緯糸の交差が凹凸として見え、そこに継ぎ当てが1枚当たっている。
;;; 色ではなく**形**なので bump ではなく変位 — シルエットと影に出る必要がある。
;;;
;;; 原理:
;;;   平織りは経(warp)と緯(weft)が交互に上下する。u,v それぞれの正弦の**積**を取ると
;;;   「両方が山」「両方が谷」の所が持ち上がる市松になり、これが織り目に見える。
;;;     weave = 0.5*(1 + sin(u*fu) * sin(v*fv))
;;;   さらに布のたわみとして vfbm を薄く足す (糸目だけだと機械的に見える)。
;;;
;;; 座標: **s,t は無い**ので P から作る (変位シェーダーの入力は P だけ)。
;;;   u = atan2(Pz, Px)      経度 [rad]  → 頭の周りを一周
;;;   v = Py                 高さ
;;;   ⚠ 極 (真上) で経線が収束するので、頂点付近は織り目が詰まる。頭巾のように
;;;     天頂が中心にある物では目立たないが、球全体に使うなら triplanar にすること。
;;;
;;; Lipschitz (シーンが申告する値の根拠):
;;;   |∇weave| ≤ 0.5*weave-amt*sqrt((fu/r)^2 + fv^2)     r = 布の半径
;;;   |∇fbm|   ≈ 2.5*wrinkle-scale*wrinkle-amt
;;;   L = その和。頭巾 (r≈0.33, fu=70, fv=180, weave-amt=1) で約 140。
;;;   ⚠ 小さすぎると球面追跡が織り目を貫通して穴が開く。掠める角度を5倍拡大で確認する。
;;;
;;; 使い方 (シーン):
;;;   (displace (amp 0.005) (mode dsl) (shader clothweave) (lipschitz 150)
;;;             (param warp-freq 70) (param weft-freq 180) (param weave-amt 1.0)
;;;             (param wrinkle-scale 9) (param wrinkle-amt 0.35))

(setq clothweave-shader

(make-shader clothweave :keyword :displacement
      (((warp-freq     float) 70.0)    ; 経糸: 一周あたりの本数
       ((weft-freq     float) 180.0)   ; 緯糸: 高さ方向の角周波数 (周期 = 2pi/この値)
       ((weave-amt     float) 1.0)     ; 織り目の深さ
       ((wrinkle-scale float) 9.0)     ; 布のたわみの空間周波数
       ((wrinkle-amt   float) 0.35)    ; 同・量。0 で機械的な糸目だけになる
       ((patch-u       float) 99.0)    ; 継ぎ当ての中心 (経度[rad])。既定は範囲外=無効
       ((patch-v       float) 0.0)     ; 同・高さ
       ((patch-size    float) 0.10)    ; 同・半径 (u は rad, v は world 長)
       ((patch-amt     float) 0.55))   ; 同・盛り上がり

  (enter (((u  float) 0.0)
          ((vv float) 0.0)
          ((q  point) (make-point 0 0 0))
          ((w  float) 0.0)
          ((fw float) 0.0)
          ((du float) 0.0)
          ((dv float) 0.0)
          ((pk float) 0.0)
          ((h  float) 0.0))

    ;; 布の座標を P から作る (s,t は displacement クラスには来ない)
    (setvar u  (atan2 (zcomp P) (xcomp P)))
    (setvar vv (ycomp P))

    ;; 平織り: 経と緯の正弦の積 → 交差点が持ち上がる市松
    (setvar w (* (sin (* u warp-freq)) (sin (* vv weft-freq))))
    (setvar w (* 0.5 (+ 1.0 w)))
    (setvar h (* w weave-amt))

    ;; 布のたわみ (糸目だけだと金網に見える)。周波数比は非整数のまま使う
    (setvar q (* P wrinkle-scale))
    (setvar fw (vfbm q 3))
    (setvar h (+ h (* wrinkle-amt fw)))

    ;; 継ぎ当て: (u,v) 上の矩形をなだらかに盛り上げる。
    ;; 段差は smoothstep で作る — if の崖にすると距離場が不連続になり球面追跡が壊れる
    (setvar du (abs (- u patch-u)))
    (setvar dv (abs (- vv patch-v)))
    (setvar pk (* (- 1.0 (smoothstep (* patch-size 0.6) patch-size du))
                  (- 1.0 (smoothstep (* patch-size 0.6) patch-size dv))))
    (setvar h (+ h (* patch-amt pk)))

    (setvar disp (clamp h 0.0 1.0))
)))

(compile-shader clothweave-shader)
(append-shader clothweave-shader)
