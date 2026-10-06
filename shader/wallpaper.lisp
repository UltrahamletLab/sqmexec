;;;; wallpaper.lisp — 壁紙 (2トーン縦ストライプ)。
;;;;   世界座標 Pg の (x+z) をストライプ座標に使う → 軸平行の壁ならどの向きでも
;;;;   縦縞になる (メッシュUV不要)。エッジは smoothstep でソフトに。
;;;;   params: Ka=0 Kd=1 base-color=2 stripe-color=3 stripe-width=4 stripe-soft=5

(setq wallpaper-shader
(make-shader wallpaper :keyword :surface
      (
       ((Ka float) 0.3)
       ((Kd float) 0.8)
       ((base-color color)   (make-color 0.93 0.89 0.80))
       ((stripe-color color) (make-color 0.88 0.76 0.74))
       ((stripe-width float) 0.85)
       ((stripe-soft float)  0.05)
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((uu float) 0)
          ((ff float) 0)
          ((band float) 0)
          ((col color) (make-color 0 0 0)))
    ;; ストライプ座標 (世界単位 → 周期 1)
    (setvar uu (/ (+ (xcomp Pg) (zcomp Pg)) stripe-width))
    (setvar ff (- uu (floor uu)))
    ;; 三角波の距離 |ff-0.5| で半分ずつの縞。soft でエッジをぼかす
    (setvar band (smoothstep (- 0.25 stripe-soft) (+ 0.25 stripe-soft) (abs (- ff 0.5))))
    (setvar col (mix base-color stripe-color band))
    (setvar Oi Os)
    (setvar Ci (* Oi (* col (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))))))
(compile-shader wallpaper-shader)
(append-shader wallpaper-shader)
