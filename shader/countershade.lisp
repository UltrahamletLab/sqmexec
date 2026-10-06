;;; countershade.lisp — カウンターシェーディング (背=暗色 / 腹=明色)
;;;
;;; 海洋生物や動物の「背中が暗く腹が明るい」体色。ワールド法線の Y 成分で
;;; back-color と belly-color を smoothstep ブレンドする汎用サーフェス。
;;; (faceforward 前の真の法線を使う: 上向き面=back, 下向き面=belly)
;;;
;;; パラメータ定義順 (shade_dr.c の countershade_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 back-color=4 belly-color=5
;;;   blend-center=6 blend-width=7

(setq countershade-shader
(make-shader countershade :keyword :surface
  (((Ka float) 0.30) ((Kd float) 0.70) ((Ks float) 0.30) ((roughness float) 0.08)
   ((back-color  color) (make-color 0.30 0.40 0.52))
   ((belly-color color) (make-color 0.78 0.82 0.86))
   ((blend-center float) -0.05)   ; 法線Yがこの値を境に背↔腹
   ((blend-width  float) 0.35))   ; ブレンドのぼけ幅
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((Nw point) (normalize N))
    ((nny float) 0) ((f float) 0)
    ((base color) (make-color 0 0 0)))
  ;; 真の法線の Y で背/腹をブレンド (上向き=1 → back)
  (setvar nny (ycomp Nw))
  (setvar f (smoothstep (- blend-center blend-width) (+ blend-center blend-width) nny))
  (setvar base (mix belly-color back-color f))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                      (* Ks (specular Nf Ir roughness))))))))

(compile-shader countershade-shader)
(append-shader countershade-shader)
