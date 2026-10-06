;;; filament
;;; 円筒の表面を螺旋状のフィラメント (電球のコイル) に見せる。
;;;
;;; Converted from:
;;;   Listing 16.25 "Surface shader to make a cylinder look like a filament"
;;;   (The RenderMan Interface / 電球の作例。本文いわく screen() と threads() の合成)
;;;
;;;   float offset = mod((t*frequency + s + phase), 1.0);
;;;   if (offset < width) { Ci = Cs;  Oi = 1.0; }
;;;   else                { Ci = 0.0; Oi = 0.0; }
;;;
;;; 原理: 円筒の (s,t) 上で t*frequency + s が一定 = 「s が1周する間に t が
;;;   1/frequency だけ進む」直線 → 円筒に巻けば**螺旋**。そこから width 未満の帯だけを
;;;   不透明に残し、他は Oi=0 で抜く。ジオメトリは円筒のままなのに、抜けた穴から
;;;   裏側のリボンが透けてコイルの巻きが立体的に見える。
;;;   = 「形を指定するのとシェーディングで見せるのは別物」の実例 (本文 Plate 9 と同趣旨)。
;;;
;;; フィラメントは自己発光。原典どおり照明計算をせず出力色は常に Cs。
;;; (glow.lisp を貼った球で包むと Plate 8 の光る糸になる)
;;;
;;; ※ s=円周方向 / t=軸方向 の UV が要る → sqm では **UV付きメッシュ**に貼ること。
;;;   SDF/メタボールは法線由来の球面 s,t にフォールバックし、円筒側面では t が 0.5
;;;   固定になって螺旋にならない。assets/cylinder_uv.obj (tools/gen_uv_cylinder.py) を使う。

(setq filament-shader

(make-shader filament :keyword :surface
      (((frequency float) 5.0)     ; 円筒の全長あたりの巻き数
       ((phase     float) 0.0)     ; 螺旋の位相
       ((width     float) 0.3)     ; リボンが表面に占める幅の割合 [0,1]
       ((transparent float) 0.06))  ; sqm の穴閾値(0.05)のすぐ上 = 「素通し」
                                   ;   Oi=0 だと背景色が置かれ裏のリボンが見えない

  (enter (((offset float) 0.0))

    ;; 螺旋からの距離を [0,1) の割合で
    (setvar offset (mod (+ (* t frequency) (+ s phase)) 1.0))

    ;; リボン幅で閾値処理。DSL の if は分岐あたり1フォームなので、screen.lisp と同じ
    ;; 「Oi を立ててから Ci に掛ける」形に畳む (原典と等価: 内=Cs/1, 外=0/0)。
    (if (< offset width)
        (setvar Oi 1)
        (setvar Oi transparent))
    (setvar Ci (* Cs Oi))
)))

(compile-shader filament-shader)
(append-shader filament-shader)
