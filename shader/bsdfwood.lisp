;;; bsdfwood — パストレーシング (-Q) 用の材質シェーダー 3号 (落ち着いた木目)
;;;
;;; :volume クラスの PT 材質規約 (詳細は bsdfchecker.lisp 冒頭のコメント):
;;;   Cl = アルベド / Oi = (roughness, metallic, trans) / Ci = 発光 / t = IOR
;;;
;;; wood.lisp (1993 Magic Box) の年輪ロジックを移植: 丸太軸を x に取り、
;;; r = |(y,z) - 年輪中心| を ring-scale 倍 + ノイズ攪拌 → mod 1 の帯を
;;; smoothstep で早材/晩材に分ける。天板 (y≈一定) では z 方向に緩く湾曲した
;;; 板目の縞になる。晩材 (暗部) はわずかに roughness を下げて艶を変える。
;;;
;;; 使い方 (SSQ):
;;;   (surface (color ..) (bsdf bsdfwood)
;;;            (param ring-scale 6) (param center-y 0) (param center-z 1.5))
;;;   落ち着いた色は light/dark-wood の明度差を小さく保つこと。

(setq bsdfwood-shader

(make-shader bsdfwood :keyword :volume
      (((ring-scale  float) 6.0)      ; 年輪の密度 (大=細かい縞)
       ((grain       float) 0.55)     ; 年輪を乱すノイズ量 (0=同心円)
       ((grain-scale float) 1.6)      ; 乱れノイズの空間スケール
       ((center-y    float) 0.0)      ; 丸太軸 (x方向) の y 位置
       ((center-z    float) 1.5)      ; 丸太軸 (x方向) の z 位置
       ((light-wood  color) (make-color 0.44 0.29 0.165))
       ((dark-wood   color) (make-color 0.28 0.165 0.09))
       ((rough-base  float) 0.48)     ; 早材 (明部) の roughness
       ((rough-dark  float) 0.38))    ; 晩材 (暗部) の roughness (やや艶)

  (enter (((q    point) (make-point 0 0 0))
          ((yy   float) 0.0)
          ((zz   float) 0.0)
          ((r    float) 0.0)
          ((band float) 0.0)
          ((rg   float) 0.0))

    (setvar yy (- (ycomp Pg) center-y))
    (setvar zz (- (zcomp Pg) center-z))
    (setvar r (sqrt (+ (* yy yy) (* zz zz))))
    (setvar r (* r ring-scale))

    ;; 年輪の攪拌 (自然な揺らぎ。grain 0 で同心円に退化)
    (setvar q (make-point (* (xcomp Pg) grain-scale)
                          (* yy grain-scale)
                          (* zz grain-scale)))
    (setvar r (+ r (* grain (vfbm q 3.0))))

    (setvar r (- r (floor r)))  ; = (mod r 1)
    (setvar band (- (smoothstep 0 0.8 r) (smoothstep 0.83 1 r)))

    (setvar Cl (mix light-wood dark-wood band))
    ;; float の補間は明示算術で (mix は color 用 — bsdfrust と同じ流儀)
    (setvar rg (+ (* rough-base (- 1.0 band)) (* rough-dark band)))
    (setvar Oi (make-color rg 0.0 0.0))
)))

(compile-shader bsdfwood-shader)
(append-shader bsdfwood-shader)
