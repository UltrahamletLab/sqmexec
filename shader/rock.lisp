;;; rock — 岩塊のゴツゴツした表面 (変位シェーダー)
;;;
;;; :displacement クラス。threads/fur と同じく本体を触らずパターンを .lisp 側に置く。
;;;
;;; 原理: 2スケールの vfbm を合成。
;;;   ・coarse (低周波, 少ないoctave) = 塊状の大きな凹凸 (岩そのものの形の歪み)
;;;   ・fine   (高周波, 多いoctave)   = 表面の細かい荒れ
;;;   評価点 P を先に vfbm でドメインワープしておくことで、塊の輪郭自体を
;;;   非対称に歪ませ、同心円状に見えるのを防ぐ (forest.lisp の地形warpと同じ考え方)。
;;;
;;;   h = ( coarse-amt * vfbm(warp(P)*coarse-freq, 3)
;;;       + fine-amt   * vfbm(warp(P)*fine-freq,   4) ) ^ contrast
;;;
;;; 使い方 (シーン):
;;;   (displace (amp 0.10) (mode dsl) (shader rock) (lipschitz 24)
;;;             (param coarse-freq 1.6) (param fine-freq 7.0)
;;;             (param coarse-amt 0.65) (param fine-amt 0.35)
;;;             (param warp 0.25) (param contrast 1.3) (param ymin -1000))
;;;   ※ lipschitz ≈ amp * (coarse-freq*coarse-amt + fine-freq*fine-amt) * 2π 程度が
;;;     上限の目安。小さすぎると球面追跡が凹凸を貫通する→5×拡大で稜線を確認すること。

(setq rock-shader

(make-shader rock :keyword :displacement
      (((coarse-freq float) 1.6)   ; 塊状の凹凸の周波数 (低いほど大きな塊)
       ((fine-freq   float) 7.0)   ; 表面の荒れの周波数 (高いほど細かい)
       ((coarse-amt  float) 0.65)  ; 塊の寄与
       ((fine-amt    float) 0.35)  ; 荒れの寄与
       ((warp        float) 0.25)  ; 塊の輪郭を歪めるドメインワープの強さ
       ((contrast    float) 1.3)   ; 山を締めるコントラスト (pow)
       ((ymin        float) -1000.0)) ; これ未満は変位フェードアウト (接地の縁を守る)

  (enter (((qw point) (make-point 0 0 0))
          ((coarse float) 0.0)
          ((fine   float) 0.0)
          ((h      float) 0.0))

    ;; 塊の輪郭そのものを歪める (同心円/整った塊に見えるのを防ぐ)
    (setvar qw (+ P (* warp (- (vfbm (* P 0.5) 3) 0.5))))

    (setvar coarse (vfbm (* qw coarse-freq) 3))
    (setvar fine   (vfbm (* qw fine-freq) 4))

    (setvar h (clamp (+ (* coarse-amt coarse) (* fine-amt fine)) 0.0 1.0))
    (setvar h (pow h contrast))

    ;; 接地際は滑らかにフェードアウト (床との継ぎ目を守る)
    (setvar h (* h (smoothstep ymin (+ ymin 0.05) (ycomp P))))

    (setvar disp h)
)))

(compile-shader rock-shader)
(append-shader rock-shader)
