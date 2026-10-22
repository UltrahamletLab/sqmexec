;;; babyband — sin/cos 帯 × 窓2枚の汎用しわ変位 (BabyToy 転写用)
;;;
;;; h = trig(dot(P,F)+ph) * S(e1a,e1b, dot(P,W1)+c1) * S(e2a,e2b, dot(P,W2)+c2)
;;;   trig: sin。tabs>0.5 で |sin| (しわ列)、neg>0.5 で符号反転 (彫り込み方向)。
;;;   窓は GLSL smoothstep (逆エッジ可) を手組み — w1abs>0.5 で |dot+c| (帯窓)。
;;;   窓を使わない側は W=(0,0,0) c=1 e=(0,0.5) にすると S(0,.5,1)=1 で常時ON。
;;;
;;; BabyToy の3箇所がこの1本で書ける:
;;;   首すじ  d -= |sin(-4x+20y)|*.0075*S(0,1,y+.25)
;;;   腹すじ  d -= |sin(8x-2z)|*.03*S(1,0,|x+.2|)
;;;   鼻溝    d += cos(30z)*.03*S(.3,0,-z)*S(.85,1.3,y)   (cos は ph=π/2, neg=1)
;;;
;;; lipschitz はシーン申告: |F| + 窓勾配 (1.5/幅)。
(setq babyband-shader

(make-shader babyband :keyword :displacement
      (((fx    float) 0.0)      ; 縞の周波数ベクトル F
       ((fy    float) 0.0)
       ((fz    float) 0.0)
       ((ph    float) 0.0)      ; 位相 (cos は π/2)
       ((tabs  float) 0.0)      ; >0.5 で |sin|
       ((neg   float) 0.0)      ; >0.5 で h を反転 (彫る)
       ((w1x   float) 0.0)      ; 窓1: S(e1a,e1b, dot(P,W1)+c1)
       ((w1y   float) 0.0)
       ((w1z   float) 0.0)
       ((c1    float) 1.0)
       ((e1a   float) 0.0)
       ((e1b   float) 0.5)
       ((w1abs float) 0.0)      ; >0.5 で |dot+c1|
       ((w2x   float) 0.0)      ; 窓2 (同上)
       ((w2y   float) 0.0)
       ((w2z   float) 0.0)
       ((c2    float) 1.0)
       ((e2a   float) 0.0)
       ((e2b   float) 0.5))

  (enter (((qq  float) 0.0)
          ((tg  float) 0.0)
          ((v1  float) 0.0)
          ((v2  float) 0.0)
          ((t1  float) 0.0)
          ((t2  float) 0.0)
          ((hh  float) 0.0))

    (setvar qq (+ (+ (* fx (xcomp P)) (* fy (ycomp P))) (+ (* fz (zcomp P)) ph)))
    (setvar tg (sin qq))
    (if (> tabs 0.5) (setvar tg (abs tg)))

    (setvar v1 (+ (+ (* w1x (xcomp P)) (* w1y (ycomp P))) (+ (* w1z (zcomp P)) c1)))
    (if (> w1abs 0.5) (setvar v1 (abs v1)))
    (setvar t1 (clamp (/ (- v1 e1a) (- e1b e1a)) 0.0 1.0))
    (setvar t1 (* (* t1 t1) (- 3.0 (* 2.0 t1))))

    (setvar v2 (+ (+ (* w2x (xcomp P)) (* w2y (ycomp P))) (+ (* w2z (zcomp P)) c2)))
    (setvar t2 (clamp (/ (- v2 e2a) (- e2b e2a)) 0.0 1.0))
    (setvar t2 (* (* t2 t2) (- 3.0 (* 2.0 t2))))

    (setvar hh (* (* tg t1) t2))
    (if (> neg 0.5) (setvar hh (- 0.0 hh)))
    (setvar disp hh)
)))

(compile-shader babyband-shader)
(append-shader babyband-shader)
