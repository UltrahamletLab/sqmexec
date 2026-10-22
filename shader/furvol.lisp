;;; furvol — 体積シェル毛皮 (:volume)。Blender のヘアパーティクル風の
;;;          「柔らかいシルエット + 光を透かす毛束」を参加媒質で出す。
;;;
;;; 使い方: 本体 (不透明) と同じ SDF を (round (r L)) で L だけ膨らませた
;;; オブジェクトを volume 容器にする。カメラレイは本体表面で打ち切られるので、
;;; 積分されるのは表面の外側の殻だけ。round は厳密 (d-r) なので
;;;   表面からの高さ = L - v     (v = 容器境界から内側への距離, SGV)
;;; が厳密に出る。furlay (変位) と違いシルエットが柔らかく、毛先が背景に溶ける。
;;;
;;;   (object "fur-shell"
;;;     (volume (shader furvol) (density 6.0) (steps 96)
;;;             (param length 0.08) (param density 55) (param sharp 3.0)
;;;             (param center 0 0.62 0) (param elong 8)
;;;             (param albedo 0.92 0.88 0.80) (param extinction 1 1 1))
;;;     (sdf (round (r 0.08) (grid (file "...bear.f32")))))
;;;   ※ (param length ..) は容器の round 半径と**同じ値**にすること。
;;;
;;; 毛の向き: 法線は volume ABI に来ない (P/u/v/s のみ) ので、
;;; **center からの放射方向**を毛流にする。コンパクトな塊 (クマ) なら
;;; 放射 ≈ 法線で、逆立った綿毛にはむしろ合う。
;;;
;;; SGV の読み替え (vol.cpp / dr_volume_sample):
;;;   u  = 容器 bbox 内の正規化高さ / v = 境界から内側への距離
;;;   s  = 組み込み fBm 密度 (未使用)
;;;   出力 t=密度 / Cl=散乱アルベド / Ci=発光 / Oi=RGB消散
;;; ⚠ 変数名に t を使わない (出力密度の SGV)。frac は x-floor(x) で書く。

(setq furvol-shader

(make-shader furvol :keyword :volume
      (((length   float) 0.08)    ; 毛長 = 容器の round 半径と同じ値を渡す
       ((density  float) 55.0)    ; 毛筋ノイズの周期 = 毛の太さ (大=細かい)
       ((sharp    float) 3.0)     ; 毛筋の尖り (大=細く疎らに)
       ((detail   float) 0.35)    ; 第2オクターブ (×2.17) の重み = 不揃いさ
       ((elong    float) 8.0)     ; 放射方向の引き伸ばし (1=等方=綿)
       ((center   point) (make-point 0 0.6 0)) ; 放射の原点 (体の重心あたり)
       ((taper    float) 1.6)     ; 毛先の減衰指数 (大=根元だけ濃い)
       ((root     float) 0.35)    ; 根元の下駄 (地肌を隠す均一密度)
       ((gain     float) 1.0)     ; 密度の全体ゲイン
       ((albedo   color) (make-color 0.92 0.88 0.80)) ; 散乱アルベド
       ((extinct  color) (make-color 1.0 1.0 1.0))    ; RGB消散
       ((ymin     float) -1000.0)  ; これ未満の高さは毛なし (接地を守る)
       ((wiggle   float) 0.35)     ; 毛流方向の乱れ (0=直毛の放射)
       ((wscale   float) 26.0)     ; 乱れの空間周波数
       ((normal-blend float) 0.0)  ; 0=放射 / 1=容器法線 (要 (volume (normals eps)))
       ((strand-tint float) 0.0)   ; 毛束ごとの明暗ムラ 0..1 (筋を「色」で見せる)
       ((tint-scale  float) 1.0)   ; ムラの縮尺 (毛間隔比。1=束ごと / 0.3=まだら)
       ((root-shade  float) 0.0)   ; 根元の陰り 0..1 (毛先ほど明るい = 深さが読める)
       ((lay-x float) 0.0)         ; 梳かし方向 (グルーミング)。接平面に射影して使う
       ((lay-y float) -1.0)
       ((lay-z float) 0.0)
       ((lay-blend float) 0.0))    ; 0=法線に立つ / 1=完全に寝て揃う (0.5〜0.7 が自然)

  (enter (((Dh  point) (make-point 0 1 0))
          ((q   point) (make-point 0 0 0))
          ((tt  float) 0.0)
          ((n1  float) 0.0)
          ((n2  float) 0.0)
          ((m   float) 0.0)
          ((hn  float) 0.0)
          ((Wv  point) (make-point 0 0 0))
          ((nb  float) 0.0)
          ((Lg  point) (make-point 0 -1 0))
          ((Tv  point) (make-point 0 0 0))
          ((tl  float) 0.0)
          ((sid float) 0.0)
          ((shade float) 1.0)
          ((dens float) 0.0))

    ;; ── 表面からの正規化高さ 0(根元)..1(毛先) ─────────────────
    ;; v > length (本体の中) は hn<0 → clamp で 0 = 影レイも自動で正しい
    (setvar hn (clamp (/ (- length v) length) 0.0 1.0))

    ;; ── 毛筋: 放射方向にだけノイズ座標を圧縮 (furlay と同じ原理) ──
    ;; (volume (normals eps)) 付き容器では N = 本体の外向き法線 (正規化済み)。
    ;; normal-blend で放射方向とブレンド = 面ごとに垂直に立つ毛。
    ;; N が来ていない (length 0) ときは blend を自動で 0 に落とす → NaN 安全。
    ;; wiggle: 毛流を低周波ベクトルノイズで曲げる = 毛束がうねり寝癖が出る
    (setvar Dh (normalize (- P center)))
    (setvar nb (* normal-blend (min (length N) 1.0)))
    (if (> nb 0.001)
        (setvar Dh (normalize (+ (* Dh (- 1.0 nb)) (* N nb)))))

    ;; ── グルーミング: 梳かし方向を接平面に射影して毛並みを揃える ──
    ;; Tv = lay − N(N·lay) は表面に沿った「櫛の向き」。lay-blend で立ち毛と
    ;; ブレンド (完全に 1 だと殻の厚み方向の密度が消えるので 0.9 上限が実用)。
    ;; N と lay が平行な場所 (頭頂など) は射影が潰れる → tl で自動フォールバック。
    (if (> (* lay-blend (length N)) 0.001)
        (progn
          (setvar Lg (normalize (make-point lay-x lay-y lay-z)))
          (setvar Tv (- Lg (* N (dot N Lg))))
          (setvar tl (length Tv))
          (if (> tl 0.05)
              (setvar Dh (normalize (+ (* Dh (- 1.0 lay-blend))
                                       (* (/ Tv tl) lay-blend)))))))
    (setvar Wv (make-point (- (vnoise (* P wscale)) 0.5)
                           (- (vnoise (+ (* P wscale) (make-point 7.3 3.1 9.7))) 0.5)
                           (- (vnoise (+ (* P wscale) (make-point 3.7 8.9 1.3))) 0.5)))
    (setvar Dh (normalize (+ Dh (* Wv (* 2.0 wiggle)))))
    (setvar q (* P density))
    (setvar tt (dot q Dh))
    (setvar q (+ (- q (* Dh tt)) (* Dh (/ tt elong))))

    (setvar n1 (vnoise q))
    (setvar n2 (vnoise (* q 2.17)))
    (setvar m (clamp (+ (* (- 1.0 detail) n1) (* detail n2)) 0.0 1.0))

    ;; 毛先ほど閾値を上げる = 各毛束が先細りになり、束の間が空く
    (setvar m (pow m (+ sharp (* sharp 1.5 hn))))

    ;; ── 密度: 根元の下駄 + 毛束、高さで減衰 ───────────────────
    (setvar dens (* gain (+ (* root (- 1.0 hn)) m)))
    (setvar dens (* dens (pow (- 1.0 hn) taper)))

    ;; 接地際のフェード
    (setvar dens (* dens (smoothstep ymin (+ ymin 0.05) (ycomp P))))

    (setvar t dens)

    ;; ── 毛束ごとの色ムラ + 根元の陰り ─────────────────────────
    ;; 密度の縞はレイ積分で平均化されて消えるが、「色」の縞は残る。
    ;; sid は毛筋と同じ圧縮座標の低周波ノイズ = 毛流に沿ってほぼ一定 = 束のID。
    ;; 毛と同じ圧縮座標・同じ縮尺の**別**ノイズ (オフセットでずらす) = 束ごとに
    ;; 一定で、隣の束とは違う値。粗くしたければ tint-scale を下げる。
    (setvar sid (vnoise (+ (* q tint-scale) (make-point 11.7 5.3 2.9))))
    (setvar shade (+ 1.0 (* strand-tint (- (* 1.8 sid) 0.9))))
    (setvar shade (* shade (- 1.0 (* root-shade (- 1.0 hn)))))
    (setvar shade (clamp shade 0.05 2.0))
    (setvar Cl (* albedo shade))
    (setvar Ci (make-color 0 0 0))
    (setvar Oi extinct)
)))

(compile-shader furvol-shader)
(append-shader furvol-shader)
