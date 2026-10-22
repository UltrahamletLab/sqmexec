;;; tebineri — 手捏ね + 箆削りの変位 (:displacement)
;;;
;;; fBm をそのまま掛けると「滑らかにうねる」だけで、轆轤を使わない手作りには
;;; ならない。手捏ねの茶碗が手捏ねに見えるのは次の2つで、性質が違う。
;;;
;;;   ① 歪み  — 器そのものが真円でない。低周波・大振幅のゆっくりしたうねり。
;;;              口縁が水平でなくなる (山道) のもこれ。
;;;   ② 箆目  — 削った**平らな面**が稜線で継がれる。fBm には無い性質で、
;;;              これが無いと「柔らかい粘土のまま」に見える。
;;;
;;; ②は連続な階段関数で作る:
;;;     t = n·steps ;  f = floor(t) ;  h = (f + smoothstep(a,b,t-f)) / steps
;;;   f は不連続だが、frac が 1 に近づくと smoothstep も 1 に近づくので
;;;   **h 全体は連続**になる。跳びを作ると距離場が壊れる (中点包囲が跨げない)
;;;   ので、この形にすること。段の平らな部分が面、遷移部が稜線になる。
;;;
;;; Lipschitz: 遷移部の傾きが支配的で、|∇h| ≈ facet·1.5/(b-a)·facet-freq·|∇fbm|。
;;;   既定値なら ≈ 0.6·5·4·2 ≈ 24 に asym 分を足す。**掃引で裏を取ること**。
;;;
;;; 使い方 (SSQ):
;;;   (displace (amp 0.03) (mode dsl) (shader tebineri) (lipschitz 40)
;;;             (param asym 0.55) (param asym-freq 1.5)
;;;             (param facet 0.55) (param facet-freq 4.0) (param steps 5)
;;;             (param edge 0.30))

(setq tebineri-shader

(make-shader tebineri :keyword :displacement
      (((asym      float) 0.55)   ; ① 歪みの量 (器が真円でなくなる)
       ((asym-freq float) 1.5)    ;    歪みの周波数 (低いほど大きなうねり)
       ((facet     float) 0.55)   ; ② 箆目の量 (段の深さ)
       ((facet-freq float) 4.0)   ;    箆目の細かさ = 面の大きさ
       ((steps     float) 5.0)    ;    段の数 (面の数)
       ((edge      float) 0.30)   ;    稜線の鋭さ (小=シャープな削り跡)
       ((vert      float) 1.8))   ;    縦への引き伸ばし (箆は縦に引く)

  (enter (((qa float) 0.0)
          ((qf point) (make-point 0 0 0))
          ((nf float) 0.0)
          ((tt float) 0.0)
          ((ff float) 0.0)
          ((fr float) 0.0)
          ((hs float) 0.0)
          ((hh float) 0.0))

    ;; ① 大きな歪み: 低周波 2 オクターブ
    (setvar qa (vfbm (* P asym-freq) 2))

    ;; ② 箆目: 縦に引き伸ばした場を階段化して平らな面を作る
    (setvar qf (make-point (* (xcomp P) facet-freq)
                           (* (ycomp P) (/ facet-freq vert))
                           (* (zcomp P) facet-freq)))
    (setvar nf (vfbm qf 2))

    (setvar tt (* nf steps))
    (setvar ff (floor tt))
    (setvar fr (- tt ff))
    ;; f + smoothstep(frac) は連続 (frac→1 で +1 に達し次の段と繋がる)
    (setvar hs (/ (+ ff (smoothstep (- 0.5 edge) (+ 0.5 edge) fr)) steps))

    (setvar hh (+ (* asym  (- qa 0.5))
                  (* facet (- hs 0.5))))
    (setvar disp (clamp (* 2.0 hh) -1.0 1.0))
)))

(compile-shader tebineri-shader)
(append-shader tebineri-shader)
