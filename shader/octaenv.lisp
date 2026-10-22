;;; octaenv — 八面体マップ (octahedral map) による方向依存の見え
;;;
;;; 出典: VoroTracing, "Differentiable Voronoi Ray Tracing Beyond Rasterization
;;; Speeds" (arXiv:2608.17682) の "compact octahedral appearance textures"。
;;; 論文はセルごとの球面調和 (48 係数) を 8x8 RGB の八面体テクスチャ (24 値) に
;;; 置き換え、見えの引き込み量を半分にしつつ空間的な細部を増やした。
;;;
;;; sqm への移し方: sqm の既存の方向引きは `(environment map-name dir)` =
;;; **cubemap** (画像 6 枚 + 面分岐 + 面内 UV)。これを **1 枚・分岐なし・
;;; 三角関数なし・極なし**の正方形 1 枚に置き換える。equirect (demiurge) の
;;; atan2/asin も要らない — abs と除算だけで uv が出る。
;;;
;;; mode
;;;   0 … 反射方向で引く (金属・環境反射)。全球 = **full-octa** マップ
;;;   1 … 法線で引く (ワールド固定のライトプローブ風)。全球 = **full-octa** マップ
;;;   2 … **matcap**: 視線基準の法線で引く。可視面の法線は半球しか無いので
;;;        **hemi-octa** マップ (正方形を半球で使い切る = 同じ画素で実効2倍)
;;;
;;; ⚠ mode 0/1 と mode 2 でマップの形式が違う。取り違えると絵は出るが歪む。
;;;   full-octa は tools/bake_octa_env.py、hemi-octa は tools/bake_matcap.py。
;;; ⚠ 画像はどちらも (octa-res + 2)^2 で焼くこと。外周 1 テクセルは折り返しを
;;;   詰めた**パディング枠**で、無いと端の 4 タップが wrap して反対側を拾う。
;;; ⚠ `(param octa-res N)` に渡すのは **論理解像度 N** で画像サイズ N+2 ではない。
;;;
;;; filter 0 = 最近傍 1 タップ / 1 = バイリニア 4 タップ
;;;   (sqm の texture() は最近傍固定なので、混ぜるのはシェーダー側の仕事)
;;;
;;; spec … シーン光源のスペキュラを足す重み。**既定 0**。
;;;   このシェーダーではテーブルが見えの全部を持つので、その上に engine の
;;;   specular を重ねると**二重計上**になる (mode 2 の matcap で顕著: 焼き込んだ
;;;   艶とは別に鋭いハイライトが乗り、布がラッカー塗りに化ける)。
;;;   環境マップ側に光源が入っていない等、意図があるときだけ 1 にする。

(setq octaenv-shader

(make-shader octaenv :keyword :surface
      (
       ((Ka float) 0.0)
       ((Kd float) 0.0)
       ((Ks float) 1.0)
       ((roughness float) 0.05)
       ((map-name string) "")
       ((octa-res float) 8)
       ((intensity float) 1.0)
       ((mode float) 0)
       ((filter float) 1)
       ((spec float) 0)
       )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((dir point) (make-point 0 0 1))
          ((vx point) (make-point 1 0 0)) ((vy point) (make-point 0 1 0))
          ((vz point) (make-point 0 0 1)) ((upw point) (make-point 0 1 0))
          ((den float) 0) ((ox float) 0) ((oy float) 0) ((oz float) 0)
          ((tmpx float) 0) ((sx float) 1) ((sz float) 1) ((lo float) 0)
          ((uu float) 0) ((vv float) 0) ((pres float) 0)
          ((tx float) 0) ((ty float) 0) ((fx float) 0) ((fy float) 0)
          ((ev color) (make-color 0 0 0))
          ((c00 color) (make-color 0 0 0)) ((c10 color) (make-color 0 0 0))
          ((c01 color) (make-color 0 0 0)) ((c11 color) (make-color 0 0 0)))

    (if (string= map-name "")
        ;; マップ未指定は手続き空へフォールバック (= envmetal と同じ絵になる)
        (progn
          (if (> mode 0.5)
              (setvar dir Nf)
              (setvar dir (reflect I Nf)))
          (setvar ev (environment map-name dir)))

        (progn
          (if (> mode 1.5)
              ;; ── mode 2: matcap (視線基準の法線 → hemi-octa) ──────────────
              ;;   sqm の (transform "camera" ..) は identity スタブなので、
              ;;   視線 I と world up からその場で正規直交基底を組む。
              ;;   Nf は I に対して faceforward 済み = dot(Nf, vz) >= 0 が保証され、
              ;;   常に半球側に落ちる。
              (progn
                (setvar vz Ir)                       ; 面 → 視点
                ;; 真下/真上を見ると up と縮退するので参照軸を差し替える
                (if (> (abs (ycomp vz)) 0.999)
                    (setvar upw (make-point 0 0 1))
                    (setvar upw (make-point 0 1 0)))
                (setvar vx (normalize (cross upw vz)))
                (setvar vy (cross vz vx))
                (setvar ox (dot Nf vx))
                (setvar oy (dot Nf vy))
                (setvar oz (dot Nf vz))              ; >= 0
                (setvar den (max (+ (abs ox) (abs oy) (abs oz)) 0.000001))
                (setvar ox (/ ox den)) (setvar oy (/ oy den))
                ;; hemi-octa: 45 度回して正方形いっぱいに使う (|ox|+|oy| <= 1 なので
                ;; ox+oy と ox-oy がちょうど [-1,1] に収まる)
                (setvar uu (+ (* 0.5 (+ ox oy)) 0.5))
                (setvar vv (+ (* 0.5 (- ox oy)) 0.5)))

              ;; ── mode 0/1: 全球 (full-octa) ───────────────────────────────
              (progn
                (if (> mode 0.5)
                    (setvar dir Nf)
                    (setvar dir (reflect I Nf)))
                (setvar ox (xcomp dir)) (setvar oy (ycomp dir)) (setvar oz (zcomp dir))
                (setvar den (max (+ (abs ox) (abs oy) (abs oz)) 0.000001))
                (setvar ox (/ ox den)) (setvar oy (/ oy den)) (setvar oz (/ oz den))
                ;; 下半球の折り返し。分岐せず lo で混ぜる。`sign` は 0 で 0 を返し
                ;; 軸上の方向を潰すので使わない — step で sign(0)=+1 に倒す。
                (setvar tmpx ox)
                (setvar sx (- (* 2 (step 0 tmpx)) 1))
                (setvar sz (- (* 2 (step 0 oz)) 1))
                (setvar lo (step 0 (- 0 oy)))          ; oy <= 0 で 1
                (setvar ox (+ (* ox (- 1 lo)) (* lo (* (- 1 (abs oz))   sx))))
                (setvar oz (+ (* oz (- 1 lo)) (* lo (* (- 1 (abs tmpx)) sz))))
                (setvar uu (+ (* 0.5 ox) 0.5))
                (setvar vv (+ (* 0.5 oz) 0.5))))

          ;; ── パディング枠ぶんずらして引く (mode 共通) ──────────────────
          ;;    論理テクセル n は画像の n+1 列目。画像は (octa-res+2)^2。
          (setvar pres (+ octa-res 2))
          (if (> filter 0.5)
              (progn
                (setvar tx (- (* uu octa-res) 0.5))
                (setvar ty (- (* vv octa-res) 0.5))
                (setvar fx (- tx (floor tx)))
                (setvar fy (- ty (floor ty)))
                (setvar tx (floor tx)) (setvar ty (floor ty))
                (setvar c00 (texture map-name (/ (+ tx 1.5) pres) (/ (+ ty 1.5) pres)))
                (setvar c10 (texture map-name (/ (+ tx 2.5) pres) (/ (+ ty 1.5) pres)))
                (setvar c01 (texture map-name (/ (+ tx 1.5) pres) (/ (+ ty 2.5) pres)))
                (setvar c11 (texture map-name (/ (+ tx 2.5) pres) (/ (+ ty 2.5) pres)))
                (setvar ev (mix (mix c00 c10 fx) (mix c01 c11 fx) fy)))
              (progn
                (setvar tx (clamp (floor (* uu octa-res)) 0 (- octa-res 1)))
                (setvar ty (clamp (floor (* vv octa-res)) 0 (- octa-res 1)))
                (setvar ev (texture map-name (/ (+ tx 1.5) pres) (/ (+ ty 1.5) pres)))))
          (setvar ev (* ev intensity))))

    (setvar Oi Os)
    (setvar Ci (* Os (+ (* Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* Cs Ks (+ ev (* spec (specular Nf Ir roughness)))))))
)))

(compile-shader octaenv-shader)
(append-shader octaenv-shader)
