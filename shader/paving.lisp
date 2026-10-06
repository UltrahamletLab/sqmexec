;;; paving — 石瓦・敷石の床 (変位シェーダー)
;;;
;;; :displacement クラス。threads/fur/rock/chitin と同じく本体を触らず
;;; パターンを .lisp 側に置く。
;;;
;;; 構成 (水平床向け, x-z 平面のグリッド):
;;;   ・x/z 各軸を freq で周期化し、セル境界近傍だけ smoothstep で切り出して
;;;     目地(溝)にする — chitin の距離リングの2軸グリッド版。
;;;   ・タイル毎の高さばらつき: セル中心座標の vnoise (=セルhash) を
;;;     base に加算 → 敷石らしい不揃いの浮き沈み。
;;;   ・fine 値ノイズ = 石表面の荒れ。
;;;   h は [0,1]、溝は "base から引く" 方式 (chitin と同じ)。
;;;
;;; 使い方 (シーン, 床の SDF box など):
;;;   (displace (amp 0.06) (mode dsl) (shader paving) (lipschitz 26)
;;;             (param freq 1.2)(param groove-width 0.08)(param groove-depth 0.85)
;;;             (param tile-var 0.35)(param fine-freq 9.0)(param fine-amt 0.25)
;;;             (param base-level 0.60))
;;;   ※ lipschitz の目安: freq/groove-width (溝の壁の勾配) + fine-freq*fine-amt*2。
;;;     groove-width を細くするほど急増する。5倍拡大で目地の穴あきを確認すること。

(setq paving-shader

(make-shader paving :keyword :displacement
      (((freq         float) 1.2)    ; 単位長あたりのタイル数
       ((groove-width float) 0.08)   ; 目地の幅 (セルに対する比率, 0〜0.5)
       ((groove-depth float) 0.85)   ; 目地が base をどれだけ削るか (0〜1)
       ((tile-var     float) 0.35)   ; タイル毎の高さばらつき
       ((fine-freq    float) 9.0)    ; 石表面の荒れの周波数
       ((fine-amt     float) 0.25)   ; 荒れの寄与
       ((base-level   float) 0.60))  ; 基準の盛り上がり

  (enter (((gx float) 0.0) ((gz float) 0.0)
          ((cellx float) 0.0) ((cellz float) 0.0)
          ((trix float) 0.0) ((triz float) 0.0)
          ((gvx float) 0.0) ((gvz float) 0.0) ((g float) 0.0)
          ((cp point) (make-point 0 0 0))
          ((tvar float) 0.0)
          ((n float) 0.0)
          ((base float) 0.0)
          ((h float) 0.0))

    ;; セル座標と三角波 (セル境界=1, セル中央=0)
    (setvar gx (* (xcomp P) freq))
    (setvar gz (* (zcomp P) freq))
    (setvar cellx (floor gx))
    (setvar cellz (floor gz))
    (setvar trix (abs (- (* 2.0 (- gx cellx)) 1.0)))
    (setvar triz (abs (- (* 2.0 (- gz cellz)) 1.0)))

    ;; どちらかの軸で境界に近ければ目地 (max 合成)
    (setvar gvx (smoothstep (- 1.0 groove-width) 1.0 trix))
    (setvar gvz (smoothstep (- 1.0 groove-width) 1.0 triz))
    (setvar g (clamp (+ gvx (* gvz (- 1.0 gvx))) 0.0 1.0))

    ;; タイル毎の高さばらつき (セル中心の値ノイズ = セルhash)
    (setvar cp (make-point (* (+ cellx 0.5) 0.7317) (* (+ cellz 0.5) 0.7317) 3.17))
    (setvar tvar (- (vnoise cp) 0.5))

    ;; 石表面の荒れ
    (setvar n (- (vnoise (* P fine-freq)) 0.5))

    (setvar base (clamp (+ base-level (* tvar tile-var) (* n fine-amt)) 0.0 1.0))
    (setvar h (clamp (* base (- 1.0 (* g groove-depth))) 0.0 1.0))

    (setvar disp h)
)))

(compile-shader paving-shader)
(append-shader paving-shader)
