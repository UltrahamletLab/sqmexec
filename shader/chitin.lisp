;;; chitin — 節足動物の脚のような外骨格の節目 (変位シェーダー)
;;;
;;; :displacement クラス。threads/fur/rock と同じく本体を触らずパターンを .lisp 側に置く。
;;;
;;; sweep(スプライン)の脚には s,t が無く、経路上の弧長パラメータも再構成できない
;;; (経路の制御点はシェーダー側から見えない) ため、**体の付け根 center から測った
;;; 3D距離**を疑似的な「脚に沿った位置」として使う。脚は center 近くから外向きに
;;; 伸びるだけで戻ってこないので、距離は脚に沿ってほぼ単調に増加し、
;;; 実用上は弧長パラメータの代役になる。
;;;
;;; 構成:
;;;   ・fine 値ノイズ = 表面のざらつき(base の凹凸。既に少し盛り上がった状態が基準)
;;;   ・center からの距離を ring-freq で周期化 → 三角波 tri (周期境界=1, 中間=0)
;;;     を smoothstep で狭い帯だけ切り出し、base から一部だけ引く
;;;     = 盛り上がった節(segment)の間に凹んだ関節膜(joint)が入る外骨格の見た目。
;;;   h は仕様どおり [0,1] のみ (負にしない・groove は "base から引く" 方式)。
;;;
;;; 使い方 (シーン, legs オブジェクトなど):
;;;   (displace (amp 0.028) (mode dsl) (shader chitin) (lipschitz 40)
;;;             (param center-x 0)(param center-y 1.05)(param center-z 0)
;;;             (param ring-freq 7.0)(param ring-width 0.22)(param ring-depth 0.75)
;;;             (param fine-freq 20.0)(param bump-amt 0.35)(param base-level 0.55)
;;;             (param ymin -1000))
;;;   ※ ring-width は「周期に対する比率」。狭くする(鋭くする)ほど Lipschitz 実測値が
;;;     急増する → 5倍拡大で稜線の穴あきを確認してから amp/lipschitz を詰めること。

(setq chitin-shader

(make-shader chitin :keyword :displacement
      (((center-x   float) 0.0)
       ((center-y   float) 1.05)
       ((center-z   float) 0.0)
       ((ring-freq  float) 7.0)    ; center からの距離1単位あたりの節の数
       ((ring-width float) 0.22)   ; 関節の溝の幅 (周期に対する比率, 0〜0.5)
       ((ring-depth float) 0.75)   ; 溝が base をどれだけ削るか (0〜1)
       ((fine-freq  float) 20.0)   ; 表面のざらつきの周波数
       ((bump-amt   float) 0.35)   ; ざらつきの寄与
       ((base-level float) 0.55)   ; ざらつき無しでの基準の盛り上がり
       ((ymin       float) -1000.0))

  (enter (((ctr point) (make-point 0 0 0))
          ((n     float) 0.0)
          ((base  float) 0.0)
          ((dist  float) 0.0)
          ((dphase float) 0.0)
          ((fr    float) 0.0)
          ((tri   float) 0.0)
          ((g     float) 0.0)
          ((h     float) 0.0))

    ;; 表面のざらつき (節の土台になる基準の盛り上がり)
    (setvar n (vfbm (* P fine-freq) 3))
    (setvar base (clamp (+ base-level (* (- n 0.5) bump-amt)) 0.0 1.0))

    ;; center からの距離を周期化して三角波に (周期境界=1, 中間=0)
    (setvar ctr (make-point center-x center-y center-z))
    (setvar dist (length (- P ctr)))
    (setvar dphase (* dist ring-freq))
    (setvar fr (- dphase (floor dphase)))
    (setvar tri (abs (- (* 2.0 fr) 1.0)))

    ;; tri が 1 に近い(=周期の境目=関節)所だけ幅 ring-width で溝を切る
    (setvar g (smoothstep (- 1.0 ring-width) 1.0 tri))
    (setvar h (clamp (* base (- 1.0 (* g ring-depth))) 0.0 1.0))

    ;; 接地際はフェードアウト (床との継ぎ目を守る)
    (setvar h (* h (smoothstep ymin (+ ymin 0.05) (ycomp P))))

    (setvar disp h)
)))

(compile-shader chitin-shader)
(append-shader chitin-shader)
