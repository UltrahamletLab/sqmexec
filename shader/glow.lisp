;;; glow
;;; 球の中心にある発光体の「光芒」を球面上で表現する。
;;;
;;; Converted from:
;;;   Listing 16.26 / Figure 16.6 (The RenderMan Interface / 電球の作例)
;;;
;;;   float falloff = I.N;
;;;   if (falloff < 0) {                       /* front of sphere only */
;;;       falloff = falloff*falloff / (I.I * N.N);   /* |I||N| で正規化 = cos^2 */
;;;       falloff = pow(falloff, attenuation);
;;;       Ci = Cs * falloff;  Oi = falloff;
;;;   } else Oi = 0;
;;;
;;; 原理 (Figure 16.6): 光芒は発光体を**正面から**見たとき最も明るく、少し外すと急に
;;;   落ちる。発光体を球の中心に置くと「発光体への視線の近さ」= 「球面への視線の
;;;   直交度」に対応する → 球面上で I と N のなす角 (の cos) をそのまま光芒の強さに
;;;   使える。attenuation を上げるほど中心に締まる。
;;;   Ci も Oi も falloff にするので、球は中心が濃く周辺で消える半透明の霞になる
;;;   (premultiplied alpha)。
;;;
;;; 使い方: 発光体 (filament.lisp を貼った円筒など) を球で包み、その球にこれを貼る。
;;;   球を非一様スケールすれば光芒が細長くなる (Plate 8 はフィラメントの長さ方向に
;;;   引き伸ばして楕円の光芒にしている)。
;;;
;;; ※ 旧版はグレージング角で光る rim light だったが、これは原典と**逆**
;;;   (原典は正面が最も明るい)。2026-07-27 に添付資料どおりに書き直した。
;;;
;;; ※ sqm 固有: エンジンは Oi<0.05 を「カットアウト」とみなし、継続レイを飛ばさず
;;;   **シーン背景色をそのまま置く**。原典どおり裏面を Oi=0 にすると、背景が明るい
;;;   シーンで光芒が「黒い楕円板」になる。そこで完全透明はその閾値のすぐ上
;;;   (transparent = 0.06) で表す → 半透明経路に乗り継続レイが飛んで背後が正しく透ける。
;;;   roi=1 なら曲がらないので光学的には素通しと同じ。

(setq glow-shader

(make-shader glow :keyword :surface
      (((attenuation float) 2.0)    ; 大きいほど光芒が中心に締まる
       ((transparent float) 0.06))  ; sqm の穴閾値(0.05)のすぐ上 = 「素通し」

  (enter (((dn      float) 0.0)
          ((falloff float) 0.0))

    ;; I.N (正面向きなら負)
    (setvar dn (dot I N))

    ;; |I||N| で正規化した cos^2 → attenuation 乗
    (setvar falloff (/ (* dn dn) (* (dot I I) (dot N N))))
    (setvar falloff (pow falloff attenuation))

    ;; 球の手前側 (I.N < 0) だけ光らせる。裏面は素通し
    ;; = 光芒を二重に重ねない (原典の "Back of sphere only" 分岐)。
    ;; max は DSL のフックが壊れているので clamp で代用 (下限だけ効かせる)。
    (if (< dn 0)
        (setvar Oi (clamp falloff transparent 1.0))
        (setvar Oi transparent))
    (setvar Ci (* Cs Oi))
)))

(compile-shader glow-shader)
(append-shader glow-shader)
