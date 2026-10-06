;;; waterwave — 水面のうねり (変位シェーダー)
;;;
;;; :displacement クラス。狙いは **コースティクスが網になる水面**。
;;;
;;; なぜ rock (fBm) では駄目か:
;;;   fBm は等方的なランダム凹凸なので、屈折したフォトンが一様に散るだけで
;;;   「網」にならない (実測: 淵の底が細かいシミーにしかならなかった)。
;;;   実際の水の集光は、**なだらかに曲がった面が光を折り畳んで稜線 (カスプ) が
;;;   連結する**ことで出来る。だから水面は「低周波・滑らか・少数の波の重ね合わせ」
;;;   であるべきで、ノイズであってはいけない。
;;;
;;; 構成:
;;;   ・方向の違う4本の正弦波を重ねる。方向と周波数は**非整数比**にして
;;;     格子が揃わない (揃うと縞になる)
;;;   ・crest で波頭だけ尖らせる (0 = 純サイン)。1に近づけるほど
;;;     カスプが締まるが Lipschitz も (1+crest) 倍になる
;;;   ・angle で波列全体を回す (流れの向きに合わせる)
;;;   ・phase を進めるとうねりが流れる (アニメ可)
;;;
;;; Lipschitz (シーンが申告する値):
;;;   L = pi * freq * (1 + 4.197*detail) / (1 + 1.89*detail) * (1 + crest)
;;;   detail 0.55 のとき L = 5.10 * freq * (1 + crest)
;;;   → **fBm より桁違いに小さい**。freq 0.9 / crest 0.35 なら L = 6.2 で、
;;;     amp 0.035 でも歩幅の縮みは 1+0.035*6.2 = 1.22 倍で済む
;;;
;;; 使い方 (水の SDF box など):
;;;   (displace (amp 0.035) (mode dsl) (shader waterwave) (lipschitz 6.2)
;;;             (param freq 0.9)(param phase 0.0)(param crest 0.35)
;;;             (param angle 18.0)(param detail 0.55))

(setq waterwave-shader

(make-shader waterwave :keyword :displacement
      (((freq   float) 0.9)     ; 基本周波数 (世界単位あたりの波数)。低いほど網が大きい
       ((phase  float) 0.0)     ; 位相 (進めるとうねりが流れる)
       ((crest  float) 0.0)     ; 波頭の尖り (0=純サイン)。Lipschitz は (1+crest) 倍
       ((angle  float) 0.0)     ; 波列全体の回転 (度)
       ((detail float) 0.55))   ; 2〜4本目の相対振幅 (0=単一サイン)

  (enter (((ca   float) 0.0) ((sa   float) 0.0)
          ((px   float) 0.0) ((pz   float) 0.0)
          ((qx   float) 0.0) ((qz   float) 0.0)
          ((k0   float) 0.0)
          ((a2   float) 0.0) ((a3   float) 0.0) ((a4   float) 0.0)
          ((wsum float) 0.0) ((acc  float) 0.0)
          ((sig  float) 0.0) ((hh   float) 0.0))

    ;; 波列を angle だけ回す (xz 平面)
    (setvar ca (cos (* angle 0.0174533)))
    (setvar sa (sin (* angle 0.0174533)))
    (setvar px (xcomp P))
    (setvar pz (zcomp P))
    (setvar qx (- (* ca px) (* sa pz)))
    (setvar qz (+ (* sa px) (* ca pz)))

    (setvar k0 (* 6.2831853 freq))
    (setvar a2 detail)
    (setvar a3 (* detail 0.58))
    (setvar a4 (* detail 0.31))
    (setvar wsum (+ 1.0 a2 a3 a4))

    ;; 4本の交差する正弦波。方向ベクトルも周波数比も非整数
    (setvar acc (sin (+ (* k0 qx) phase)))
    (setvar acc (+ acc (* a2 (sin (+ (* (* k0 1.63) (+ (* 0.35 qx) (* 0.94 qz)))
                                     (* phase 1.21))))))
    (setvar acc (+ acc (* a3 (sin (+ (* (* k0 2.41) (+ (* -0.72 qx) (* 0.69 qz)))
                                     (* phase 0.77))))))
    (setvar acc (+ acc (* a4 (sin (+ (* (* k0 3.77) (+ (* 0.86 qx) (* -0.51 qz)))
                                     (* phase 1.53))))))
    (setvar sig (/ acc wsum))

    ;; 波頭を尖らせる (谷は緩く、山は締まる)。|d/dsig| <= 1+crest
    (setvar sig (/ (+ sig (* crest (* sig (abs sig)))) (+ 1.0 crest)))

    (setvar hh (clamp (+ 0.5 (* 0.5 sig)) 0.0 1.0))
    (setvar disp hh)
)))

(compile-shader waterwave-shader)
(append-shader waterwave-shader)
