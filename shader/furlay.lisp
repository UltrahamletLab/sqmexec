;;; furlay — 毛流 (lay) を持つ毛皮の変位シェーダー
;;;
;;; fur.lisp との違いは1点だけ、しかしそれが決定的:
;;;   **fur は等方ノイズなので「小石を敷いた塊」にしかならない。**
;;;   ゴリラで density/sharp/detail/amp を6通り、組み込みの
;;;   fbm/turbulence/ridged/voronoi/cracks/lobes も全部振って比べたが、
;;;   5倍拡大するとどれも砂利で、毛に見えるものは1つも無かった (2026-08-17)。
;;;   毛は**方向を持つ**ので、等方な場をいくら調整しても筋にはならない。
;;;
;;; 原理: ノイズ座標を毛流方向にだけ圧縮する。ノイズの模様は座標空間で等方なので、
;;;   毛流方向の座標を 1/elong にすると、その方向に **elong 倍に伸びた模様** =
;;;   筋になる。直交方向はそのままなので毛の太さは density が決める。
;;;
;;;     t   = dot(P*density, L̂)                 ; 毛流に沿った座標
;;;     q   = (P*density − L̂·t) + L̂·(t/elong)   ; 毛流方向だけ圧縮
;;;     h   = pow(mix(vnoise(q), vnoise(q*2.17), detail), sharp)
;;;     h  *= 1 − tip·frac(t/elong)              ; 根元が厚く毛先が細い鋸波
;;;
;;; ⚠ frac は `x − floor(x)` で書く。DSL の mod は fmod なので負側で符号が変わり、
;;;   体の片側だけ毛先が消える (storefront で実際に踏んだ罠と同じ)。
;;;
;;; 使い方 (シーン):
;;;   (displace (amp 0.020)(mode dsl)(shader furlay)(lipschitz 160)
;;;             (param density 90)(param sharp 3)(param detail 0.35)
;;;             (param elong 6)(param lay-x 1)(param lay-y -0.35)(param lay-z 0)
;;;             (param tip 0.6)(param ymin 0.02))
;;;   ※ lipschitz は伸ばしても **直交方向の勾配は縮まない** ので fur と同じ
;;;     1.7×density が下限。毛先の鋸波が加わるぶん余裕を見る。
;;;   ※ grid SDF に載せるときは SQM_SDF_GRID_NEPS=0.3 (既定3は毛を撫で消す)。

(setq furlay-shader

(make-shader furlay :keyword :displacement
      (((density float) 90.0)     ; 毛の密度 (単位長あたりのノイズ周期) = 毛の太さ
       ((sharp   float) 3.0)      ; 尖り。大きいほど毛が細く疎らに
       ((detail  float) 0.35)     ; 第2オクターブ (×2.17) の重み = 不揃いさ
       ((elong   float) 6.0)      ; 毛流方向の引き伸ばし倍率。1=等方(fur相当)
       ((lay-x   float) 1.0)      ; 毛流方向 (正規化不要)
       ((lay-y   float) -0.35)
       ((lay-z   float) 0.0)
       ((tip     float) 0.6)      ; 毛先の細り (0=一様な畝, 1=完全に尖る)
       ((ymin    float) -1000.0)) ; これ未満の高さは毛なし (足裏の接地を守る)

  (enter (((Lh point) (make-point 1 0 0))
          ((q  point) (make-point 0 0 0))
          ((tt float) 0.0)
          ((tc float) 0.0)
          ((n1 float) 0.0)
          ((n2 float) 0.0)
          ((h  float) 0.0))

    (setvar Lh (normalize (make-point lay-x lay-y lay-z)))
    (setvar q (* P density))

    ;; 毛流方向の成分だけ 1/elong に縮める = 模様がその方向へ elong 倍に伸びる
    (setvar tt (dot q Lh))
    (setvar tc (/ tt elong))
    (setvar q (+ (- q (* Lh tt)) (* Lh tc)))

    (setvar n1 (vnoise q))
    (setvar n2 (vnoise (* q 2.17)))
    (setvar h (clamp (+ (* (- 1.0 detail) n1) (* detail n2)) 0.0 1.0))
    (setvar h (pow h sharp))

    ;; 毛先: 毛流に沿った鋸波。⚠ frac は x-floor(x) (mod は負側で壊れる)
    (setvar h (* h (- 1.0 (* tip (- tc (floor tc))))))

    ;; 接地際は滑らかにフェード — 毛が床にめり込むのを防ぐ
    (setvar h (* h (smoothstep ymin (+ ymin 0.05) (ycomp P))))

    (setvar disp h)
)))

(compile-shader furlay-shader)
(append-shader furlay-shader)
