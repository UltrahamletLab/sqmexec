;;; strawribs — 放射筋の変位シェーダー (菅笠・編笠・番傘)
;;;
;;; 笠は「頂点から放射状に伸びる骨/藁の束」を「周方向の締め糸」で留めた構造。
;;; clothweave (平織り) が u,v の**格子**なのに対し、こちらは
;;;   ① 経度方向に等間隔で走る筋 (骨の束)
;;;   ② 高さ方向に一定間隔で入る締めの輪
;;; の2要素でできている。傘・笠はこちらが正しい。
;;;
;;; 原理:
;;;   phase = atan2(Pz,Px) * rib-count           経度で刻んだ筋の位相
;;;   rib   = pow(0.5*(1+cos(phase)), rib-sharp) 尖らせて「束」に見せる
;;;   band  = pow(0.5*(1+cos(Py*band-freq)), band-sharp)
;;;   h = rib-amt*rib*fade + band-amt*band + jitter
;;;
;;; ⚠ **頂点で経線が収束する** — r_perp = sqrt(x^2+z^2) → 0 で
;;;   dθ/d(world) = 1/r_perp が発散し、Lipschitz が破綻して球面追跡が穴を開ける。
;;;   `apex-fade` 未満の半径で筋を smoothstep で消して有界にしてある。
;;;   **この fade を 0 にしてはいけない。**
;;;
;;; Lipschitz (シーンが申告する根拠):
;;;   |∇rib|  ≤ 0.5*rib-sharp*rib-count/apex-fade * rib-amt
;;;   |∇band| ≤ 0.5*band-sharp*band-freq*band-amt
;;;   |∇jit|  ≈ 2.5*jitter-scale*jitter-amt
;;;   L = 和。笠 (count=44, sharp=2.2, apex-fade=0.06, band-freq=90, band-sharp=2) で約 830。
;;;
;;; 使い方 (シーン):
;;;   (displace (amp 0.006) (mode dsl) (shader strawribs) (lipschitz 900)
;;;             (param rib-count 44) (param rib-sharp 2.2) (param rib-amt 1.0)
;;;             (param band-freq 90) (param band-sharp 2.0) (param band-amt 0.30)
;;;             (param apex-fade 0.06) (param jitter-amt 0.10) (param jitter-scale 26))

(setq strawribs-shader

(make-shader strawribs :keyword :displacement
      (((rib-count    float) 44.0)   ; 一周あたりの骨の本数
       ((rib-sharp    float) 2.2)    ; 筋の尖り。大きいほど細く束らしく
       ((rib-amt      float) 1.0)    ; 筋の高さ
       ((band-freq    float) 90.0)   ; 締め輪の角周波数 (周期 = 2pi/この値)
       ((band-sharp   float) 2.0)    ; 締め輪の細さ
       ((band-amt     float) 0.30)   ; 締め輪の高さ
       ((apex-fade    float) 0.06)   ; **これ未満の半径で筋を消す** (頂点の発散止め)
       ((jitter-amt   float) 0.10)   ; 藁の不揃い
       ((jitter-scale float) 26.0))  ; 同・空間周波数

  (enter (((rp    float) 0.0)
          ((th    float) 0.0)
          ((rib   float) 0.0)
          ((band  float) 0.0)
          ((fade  float) 0.0)
          ((q     point) (make-point 0 0 0))
          ((jit   float) 0.0)
          ((h     float) 0.0))

    ;; 軸からの距離 (経線の収束を検出するのに要る)
    (setvar rp (sqrt (+ (* (xcomp P) (xcomp P)) (* (zcomp P) (zcomp P)))))
    (setvar th (atan2 (zcomp P) (xcomp P)))

    ;; ① 放射する骨の束
    (setvar rib (* 0.5 (+ 1.0 (cos (* th rib-count)))))
    (setvar rib (pow rib rib-sharp))
    ;; 頂点付近は筋を消す。**ここを外すと Lipschitz が発散して穴が開く**
    (setvar fade (smoothstep 0.0 apex-fade rp))
    (setvar h (* rib-amt (* rib fade)))

    ;; ② 周方向の締めの輪
    (setvar band (* 0.5 (+ 1.0 (cos (* (ycomp P) band-freq)))))
    (setvar band (pow band band-sharp))
    (setvar h (+ h (* band-amt band)))

    ;; ③ 藁の不揃い (完全に規則的だと金属の傘骨に見える)
    (setvar q (* P jitter-scale))
    (setvar jit (vnoise q))
    (setvar h (+ h (* jitter-amt jit)))

    (setvar disp (clamp h 0.0 1.0))
)))

(compile-shader strawribs-shader)
(append-shader strawribs-shader)
