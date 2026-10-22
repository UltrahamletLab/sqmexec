;;; digitnum.lisp — 7セグメント デジタル数字シェーダー (0-9)
;;;
;;; World座標 Pg をセルに分割し、各セルに DIGIT で指定した数字を表示する。
;;; セグメント配置 (UV [0,1]×[0,1]):
;;;
;;;   ┌──a──┐
;;;   f     b
;;;   ├──g──┤
;;;   e     c
;;;   └──d──┘
;;;
;;; パラメータ:
;;;   DIGIT    : 表示する数字 (0-9)
;;;   SCALE    : 1ワールド単位あたりのセル数
;;;   SOFF     : 水平オフセット (0.5でパネル中央にセンタリング)
;;;   TOFF     : 垂直オフセット
;;;   Con      : 点灯セグメント色
;;;   Coff     : 消灯セグメント色 (暗く見せる)
;;;   Cbg      : パネル背景色

(setq digitnum-shader
(make-shader digitnum :keyword :surface
  (((Kd float) 0.60) ((Ka float) 0.40) ((Ks float) 0.15) ((roughness float) 0.20)
   ((DIGIT float) 8)
   ((SCALE float) 1.0)
   ((SOFF  float) 0.5)
   ((TOFF  float) 0.0)
   ((Con  color) (make-color 1.00 0.65 0.05))
   ((Coff color) (make-color 0.14 0.09 0.02))
   ((Cbg  color) (make-color 0.05 0.05 0.08)))
  (enter (
    ((NN point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((Nx float) (abs (xcomp NN)))
    ((Ny float) (abs (ycomp NN)))
    ((Nz float) (abs (zcomp NN)))
    ((Px float) (xcomp Pg)) ((Py float) (ycomp Pg)) ((Pz float) (zcomp Pg))
    ((is_top float) (step 0.7 Ny))
    ; X面/Z面判定: |Nx|>=|Nz| → X面(bxz=1) → ss=Pz、Z面(bxz=0) → ss=Px
    ((bxz float) (step Nz Nx))
    ; 数字を整数に丸める
    ((dg float) (floor (+ DIGIT 0.5)))
    ; is_d(X): dg==X のとき1、それ以外0
    ((d0 float) (step 0.5 (- 1 (abs (- dg 0)))))
    ((d1 float) (step 0.5 (- 1 (abs (- dg 1)))))
    ((d2 float) (step 0.5 (- 1 (abs (- dg 2)))))
    ((d3 float) (step 0.5 (- 1 (abs (- dg 3)))))
    ((d4 float) (step 0.5 (- 1 (abs (- dg 4)))))
    ((d5 float) (step 0.5 (- 1 (abs (- dg 5)))))
    ((d6 float) (step 0.5 (- 1 (abs (- dg 6)))))
    ((d7 float) (step 0.5 (- 1 (abs (- dg 7)))))
    ((d8 float) (step 0.5 (- 1 (abs (- dg 8)))))
    ((d9 float) (step 0.5 (- 1 (abs (- dg 9)))))
    ; セグメント点灯状態 (body で計算)
    ((sa float) 0) ((sb float) 0) ((sc float) 0) ((sd float) 0)
    ((se float) 0) ((sf float) 0) ((sg float) 0)
    ; セグメント領域マスク
    ((ma float) 0) ((mb float) 0) ((mc float) 0) ((md float) 0)
    ((me float) 0) ((mf float) 0) ((mg float) 0)
    ((ss float) 0) ((tt float) 0)
    ((any_seg float) 0) ((lit float) 0)
    ((Ct color) Cbg))

  ; ── 投影 (X面: Pz使用、Z面: Px使用) ──
  (setvar ss (+ (* SCALE (+ (* bxz Pz) (* (- 1 bxz) Px))) SOFF))
  (setvar ss (- ss (floor ss)))
  (setvar tt (+ (* SCALE Py) TOFF))
  (setvar tt (- tt (floor tt)))

  ; ── セグメント点灯状態 ──
  ; a (上水平):    0,2,3,5,6,7,8,9 → 1と4で消灯
  (setvar sa (- 1 (+ d1 d4)))
  ; b (右上垂直):  0,1,2,3,4,7,8,9 → 5と6で消灯
  (setvar sb (- 1 (+ d5 d6)))
  ; c (右下垂直):  0,1,3,4,5,6,7,8,9 → 2で消灯
  (setvar sc (- 1 d2))
  ; d (下水平):    0,2,3,5,6,8,9 → 1と4と7で消灯
  (setvar sd (- 1 (+ d1 (+ d4 d7))))
  ; e (左下垂直):  0,2,6,8 → d0+d2+d6+d8
  (setvar se (+ d0 (+ d2 (+ d6 d8))))
  ; f (左上垂直):  0,4,5,6,8,9 → 1と2と3と7で消灯
  (setvar sf (- 1 (+ d1 (+ d2 (+ d3 d7)))))
  ; g (中水平):    2,3,4,5,6,8,9 → 0と1と7で消灯
  (setvar sg (- 1 (+ d0 (+ d1 d7))))

  ; ── セグメント領域マスク (ss,tt∈[0,1]内の矩形) ──
  ; a: 上水平   ss=[0.15,0.85]  tt=[0.83,0.94]
  (setvar ma (* (- (step 0.15 ss) (step 0.85 ss))
                (- (step 0.83 tt) (step 0.94 tt))))
  ; b: 右上垂直 ss=[0.76,0.88]  tt=[0.55,0.80]
  (setvar mb (* (- (step 0.76 ss) (step 0.88 ss))
                (- (step 0.55 tt) (step 0.80 tt))))
  ; c: 右下垂直 ss=[0.76,0.88]  tt=[0.20,0.46]
  (setvar mc (* (- (step 0.76 ss) (step 0.88 ss))
                (- (step 0.20 tt) (step 0.46 tt))))
  ; d: 下水平   ss=[0.15,0.85]  tt=[0.06,0.17]
  (setvar md (* (- (step 0.15 ss) (step 0.85 ss))
                (- (step 0.06 tt) (step 0.17 tt))))
  ; e: 左下垂直 ss=[0.12,0.24]  tt=[0.20,0.46]
  (setvar me (* (- (step 0.12 ss) (step 0.24 ss))
                (- (step 0.20 tt) (step 0.46 tt))))
  ; f: 左上垂直 ss=[0.12,0.24]  tt=[0.55,0.80]
  (setvar mf (* (- (step 0.12 ss) (step 0.24 ss))
                (- (step 0.55 tt) (step 0.80 tt))))
  ; g: 中水平   ss=[0.15,0.85]  tt=[0.47,0.53]
  (setvar mg (* (- (step 0.15 ss) (step 0.85 ss))
                (- (step 0.47 tt) (step 0.53 tt))))

  ; ── セグメント内かどうか ──
  (setvar any_seg (step 0.5 (+ ma (+ mb (+ mc (+ md (+ me (+ mf mg))))))))

  ; ── 点灯ピクセル (セグメントON × マスク) ──
  (setvar lit (step 0.5
    (+ (* sa ma) (+ (* sb mb) (+ (* sc mc) (+ (* sd md)
    (+ (* se me) (+ (* sf mf) (* sg mg)))))))))

  ; ── 色: 背景 → 消灯セグメント → 点灯セグメント ──
  (setvar Ct (mix Cbg Coff any_seg))
  (setvar Ct (mix Ct Con lit))

  ; 上下面はパネル色のみ
  (if (> is_top 0.5) (setvar Ct Cbg))

  (setvar Oi Os)
  (setvar Ci (* Oi (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse NN))))
                      (* Ks (specular NN Ir roughness))))))))

(compile-shader digitnum-shader)
(append-shader digitnum-shader)
