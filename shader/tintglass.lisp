;;; tintglass — 着色透過するガラス/液体 (赤ワイン・色ガラス・着色瓶)
;;;
;;; glass.lisp が「無色透明」なのに対し、こちらは **透過光に色を付ける**。
;;;
;;; 原理: RenderMan の Oi は本来カラー (3成分) で、チャンネル毎の不透明度を表せる。
;;;   エンジンの合成は  Ci_final[c] = Oi[c]*Ci[c] + (1-Oi[c])*透過光[c]
;;;   なので、透過させたい色のチャンネルだけ Oi を下げれば その色が透けて残る。
;;;
;;;   Os はエンジンが scene の kt から 1-kt を入れてくる (グレー) ので、
;;;     Oi = 1 - (1-Os) * transmit-color
;;;   とすれば「kt が透明度、transmit-color が透ける色」になる。
;;;   例: kt 0.86 / transmit-color (1, 0.035, 0.022)
;;;       → Oi = (0.14, 0.970, 0.981)  R はよく透け、G/B はほぼ遮る = 赤い液体
;;;
;;; kt だけでは「透明にすると色が消え、色を出すと不透明になる」という二律背反になる。
;;; 透明度 (kt) と 透ける色 (transmit-color) を分けるのが要点。
;;;
;;; 屈折方向・多重透過はエンジン側 (shade_dr.c の透過ブロック) が scene の roi/kt で扱う。
;;; ここで自前 trace を足すと二重屈折 + IOR 不一致になる (glass.lisp が過去に撤去した罠)。

(setq tintglass-shader

(make-shader tintglass :keyword :surface
      (
	((Ks float) 0.25)
        ((Kd float) 0.15)
        ((Ka float) 0.10)
        ((Kr float) 0.10)
        ((roughness float) 0.02)
        ((transmit-color color) (make-color 1 1 1))
        ((specular-color color) (make-color 1 1 1))
        ;; depth-cue: Beer-Lambert 厚み近似 (0=無効=均一 tint / >0 で深部ほど濃く)。
        ;; 真の光路長は無いので、視線と面の向き |I·N| を厚みの proxy にする:
        ;; 凸な液体を外から見ると、面が視線に正対する所ほど奥の液が厚い=最も濃く見え、
        ;; シルエット際 (掠め) は薄い。face=|I·N| を厚み係数として吸収を強める。
        ((depth-cue float) 0.0)
       )
  (enter (((Nf point) (faceforward (normalize N) I))
	  ((Ir point) (normalize (- I)))
	  ((Ii point) (normalize I))
	  ((face float) (abs (dot Ii Nf)))          ; 正対=1 / 掠め=0 (厚みの proxy)
	  ((deep color) (* transmit-color transmit-color))  ; 厚い所の濃色 = transmit²
	  ((tc   color) (mix transmit-color deep (clamp (* depth-cue face) 0 1)))
	  ((r-direction point) (reflect I Nf)))
    ;; チャンネル毎の不透明度。透過させたい色ほど Oi を下げる。
    ;; transmit-color = (1 1 1) なら Oi = Os となり glass 相当 (無着色) に戻る。
    ;; depth-cue>0: 厚い所 (face 大) で transmit を deep 側へ寄せて濃く見せる。
    ;;   depth-cue=0 で mix 係数 0 → tc=transmit-color = 従来と一致 (回帰なし)。
    (setvar Oi (- (make-color 1 1 1) (* (- (make-color 1 1 1) Os) tc)))
    ;; 表面側の色。液体本体の濃い色はここが担う (透過しなかった分に効く)。
    (setvar Ci (+ (* Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
		 (* specular-color Ks (specular Nf Ir roughness))))
    ;; 環境反射 (液面/ガラス面の映り込み)。1バウンス。
    (setvar Ci (+ Ci (* Kr (trace P r-direction))))
)))

(compile-shader tintglass-shader)
(append-shader tintglass-shader)
