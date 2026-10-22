;;; bsdfterrazzo — パストレーシング (-Q) 用。人造大理石/テラゾーの天板。
;;;
;;; :volume クラスの PT 材質規約 (詳細は bsdfchecker.lisp 冒頭)。
;;;   Cl = アルベド / Oi = (roughness, metallic, transmission) / t = IOR
;;;
;;; 狙い: カフェのテーブルにある「明るい灰色の地に、白・灰・黒の細かい粒が
;;; 密に散った」面。**粒は連続ノイズでなく離散**なのが肝で、fBm をそのまま
;;; 色に流すと «曇った大理石» になって粒に見えない。高周波の値格子ノイズを
;;; 閾値で3〜4段に量子化して、粒ごとに色を切り替える。
;;;
;;; ⚠ 粒の大きさは **本番の画素密度で決める**。低解像度で見ると粒がエイリアスして
;;;   「ちょうど良い」に見えるが、本番で砂嵐になる (guard: texture-judgement-res)。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (bsdf bsdfterrazzo)
;;;            (param scale 34) (param dark-frac 0.18))

(setq bsdfterrazzo-shader

(make-shader bsdfterrazzo :keyword :volume
      (((scale       float) 34.0)     ; 粒の細かさ (大きいほど細かい)
       ((base-color  color) (make-color 0.62 0.61 0.585))  ; 地の灰
       ((light-color color) (make-color 0.90 0.895 0.875)) ; 白い粒
       ((mid-color   color) (make-color 0.50 0.495 0.475)) ; 中間の粒
       ((dark-color  color) (make-color 0.17 0.165 0.16))  ; 黒い粒
       ((dark-frac   float) 0.16)     ; 黒い粒の割合 (閾値)
       ((light-frac  float) 0.42)     ; 白い粒の割合
       ((mottle      float) 0.14)     ; 低周波の地むら (板の不均一)
       ((rough-base  float) 0.34)     ; 地の roughness
       ((rough-grain float) 0.20))    ; 粒の roughness (粒の方が艶がある)

  (enter (((q    point) (make-point 0 0 0))
          ((q2   point) (make-point 0 0 0))
          ((ql   point) (make-point 0 0 0))
          ((vv   float) 0.0)
          ((v2   float) 0.0)
          ((lo   float) 0.0)
          ((col  color) (make-color 0 0 0))
          ((rg   float) 0.0))

    ;; 粒: 高周波の値格子ノイズ。**y は使わない** — 天板は水平面なので
    ;; xz だけで引くと «上から見た石» になり、側面に縞が出ない
    (setvar q (make-point (* (xcomp Pg) scale) 0.0 (* (zcomp Pg) scale)))
    (setvar vv (vnoise q))
    ;; 2枚目を別スケールで重ねて、格子の規則性を崩す (1枚だと市松に見える)
    (setvar q2 (make-point (+ (* (xcomp Pg) scale 1.93) 11.3) 0.0
                           (+ (* (zcomp Pg) scale 1.93) 7.1)))
    (setvar v2 (vnoise q2))
    (setvar vv (* 0.62 (+ vv (* 0.61 v2))))

    ;; 地の低周波むら (板ごとの色の揺れ)
    (setvar ql (make-point (* (xcomp Pg) 0.9) 0.0 (* (zcomp Pg) 0.9)))
    (setvar lo (* mottle (- (vfbm ql 4.0) 0.5)))

    ;; **離散化**: 閾値で3段に切る。mix の連続補間にしないこと (粒に見えない)
    (setvar col (mix base-color light-color (step light-frac vv)))
    (setvar col (mix col mid-color   (* (step 0.30 vv) (- 1.0 (step light-frac vv)))))
    (setvar col (mix col dark-color  (- 1.0 (step dark-frac vv))))
    (setvar col (+ col (make-color lo lo (* lo 0.9))))

    ;; 粒の方がわずかに磨かれている (斜光でキラッと返るのはこれ)
    ;; ⚠ (mix a b f) は **color 専用**。float に使うと
    ;;   "The argument doesn't match in fucntion MIX." でビルドが落ちる
    (setvar rg (+ rough-base (* (- rough-grain rough-base) (step light-frac vv))))

    (setvar Cl col)
    (setvar Oi (make-color rg 0.0 0.0))
)))

(compile-shader bsdfterrazzo-shader)
(append-shader bsdfterrazzo-shader)
