;;; fakegi.lisp — 擬似グローバル照明ライトリグ (IQ流の多項ライティングを独自実装)
;;;
;;; 加算する光の項:
;;;   sun  = Kd * diffuse(Nf)        … シーンのライト (影はエンジン側)
;;;   amb  = Ka * ambient()          … -O n 有効時は AO×(空+地面バウンス) の擬似GI
;;;   back = back-amt * diffuse(-Nf) … 逆光/リム (背後からの光を反転法線で拾う)
;;;   sss  = sss-amt * fresnel * (amb + 0.5*sun) … 縁が透ける擬似サブサーフェス
;;;   spec = Ks * specular * (0.25 + 0.75*fresnel^3) … かすめ角で強まるハイライト
;;; 最後に tone (γ<1) で暗部を持ち上げ、リニア出力でも陰が死なないようにする。
;;;
;;; パラメータ定義順 (shade_dr.c の fakegi_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 back-amt=4 sss-amt=5 tone=6 spec-tint=7

(setq fakegi-shader
(make-shader fakegi :keyword :surface
  (((Ka float) 0.9) ((Kd float) 0.9) ((Ks float) 0.4) ((roughness float) 0.10)
   ((back-amt float) 0.25)
   ((sss-amt  float) 0.35)
   ((tone     float) 0.85)            ; 出力ガンマ (1=無効, 0.8前後で暗部が起きる)
   ((spec-tint color) (make-color 1.0 0.95 0.85)))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((fres float) 0)
    ((lin color) (make-color 0 0 0))
    ((amb color) (make-color 0 0 0))
    ((sunc color) (make-color 0 0 0))
    ((outc color) (make-color 0 0 0))
    ((rr float) 0) ((gg float) 0) ((bb float) 0))
  ;; fresnel (かすめ角で 1)
  (setvar fres (pow (- 1 (clamp (dot Nf Ir) 0 1)) 3))
  ;; 光の項を加算
  (setvar amb  (* Ka (ambient)))
  (setvar sunc (* Kd (diffuse Nf)))
  (setvar lin (+ sunc amb
                 (* back-amt (diffuse (- Nf)))
                 (* sss-amt fres (+ amb (* 0.5 sunc)))))
  (setvar outc (+ (* Cs lin)
                  (* spec-tint Ks (+ 0.25 (* 0.75 fres)) (specular Nf Ir roughness))))
  ;; トーン: 暗部を持ち上げる軽いガンマ (チャンネル毎に pow)
  (setvar rr (pow (clamp (comp outc 0) 0 4) tone))
  (setvar gg (pow (clamp (comp outc 1) 0 4) tone))
  (setvar bb (pow (clamp (comp outc 2) 0 4) tone))
  (setvar Oi Os)
  (setvar Ci (* Oi (make-color rr gg bb))))))

(compile-shader fakegi-shader)
(append-shader fakegi-shader)
