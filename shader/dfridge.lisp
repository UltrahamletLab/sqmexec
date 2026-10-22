;;; dfridge — blob deform の DSL 模様: 単軸リッジ (解析 mode 3 の複製)
;;;
;;; 用途は dfgyroid と同じく **検証用の基準線**。mode 3 は解析側で最も安い関数形
;;; (sin_lin_interval 1回) なので、「DSL 化のオーバーヘッドが最も不利に出る条件」を
;;; 測るために置いてある。gyroid (解析側は sin/cos 6回) とは逆の端。
;;;
;;;   g = sin(f·x + ph)
;;;
;;; Lipschitz: |∇g| = |f·cos(f·x+ph)| <= f  →  (lipschitz freq) が厳密な上界。
;;;
;;; 使い方 (シーン):
;;;   (deform (mode dsl)(shader dfridge)(amp 0.30)(lipschitz 9.0)
;;;           (param freq 9.0)(param phase 0.0))

(setq dfridge-shader

(make-shader dfridge :keyword :displacement
      (((freq  float) 3.0)
       ((phase float) 0.0))

  (enter ()
    (setvar disp (sin (+ (* freq (xcomp P)) phase)))
)))

(compile-shader dfridge-shader)
(append-shader dfridge-shader)
