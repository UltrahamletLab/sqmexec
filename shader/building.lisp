;;; building.lisp — building facade window shader
;;;
;;; ビルの窓テクスチャをworld座標(Pg)でマッピング。
;;; 側面: X面は(Pz,Py)、Z面は(Px,Py) でウィンドウグリッドを生成。
;;; 上下面: 窓なし(コンクリート色)。

(setq building-shader
(make-shader building :keyword :surface
  (((Kd float) 0.75) ((Ka float) 0.25) ((Ks float) 0.25) ((roughness float) 0.10)
   ((Cframe color) (make-color 0.22 0.25 0.28))
   ((Clit   color) (make-color 0.95 0.88 0.55))
   ((Cdark  color) (make-color 0.04 0.07 0.12))
   ((COLS     float) 2.5)
   ((ROWS     float) 1.2)
   ((WFRAC    float) 0.62)
   ((HFRAC    float) 0.68)
   ((LIT_FRAC float) 0.60))
  (enter (
    ((NN point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((Nx float) (abs (xcomp NN)))
    ((Ny float) (abs (ycomp NN)))
    ((Nz float) (abs (zcomp NN)))
    ((Px float) (xcomp Pg)) ((Py float) (ycomp Pg)) ((Pz float) (zcomp Pg))
    ; 上下面判定: |Ny| >= 0.7 → top/bottom
    ((is_top float) (step 0.7 Ny))
    ; X面/Z面どちらか: |Nx| >= |Nz| → X面(bxz=1)
    ((bxz float) (step Nz Nx))
    ((ss float) 0) ((tt float) 0)
    ((sc float) 0) ((tc float) 0)
    ((sw float) 0) ((sh float) 0)
    ((iw float) 0) ((hash float) 0) ((lit float) 0)
    ((Ct color) Cframe))
  ; --- 水平投影 ---
  ; X面: ss = Pz、Z面: ss = Px  (それぞれ面に沿った水平方向)
  (setvar ss (* COLS (+ (* bxz Pz) (* (- 1 bxz) Px))))
  (setvar tt (* ROWS Py))
  ; --- セルインデックス / セル内位置 ---
  (setvar sc (floor ss))
  (setvar tc (floor tt))
  (setvar ss (- ss sc))
  (setvar tt (- tt tc))
  ; --- ウィンドウマスク (セル内 [0,1)でWFRAC×HFRACの矩形) ---
  (setvar sw (- (step (* 0.5 (- 1 WFRAC)) ss) (step (* 0.5 (+ 1 WFRAC)) ss)))
  (setvar sh (- (step (* 0.5 (- 1 HFRAC)) tt) (step (* 0.5 (+ 1 HFRAC)) tt)))
  ; 上下面には窓なし
  (setvar iw (* sw sh (- 1 is_top)))
  ; --- 擬似乱数で点灯/消灯 ---
  (setvar hash (mod (+ (* sc 0.754) (* tc 0.569) 0.5) 1.0))
  (setvar lit (step (- 1 LIT_FRAC) hash))
  ; --- 色決定 ---
  (if (> iw 0.5) (setvar Ct (mix Cdark Clit lit)))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse NN))))
                      (* Ks (specular NN Ir roughness))))))))

(compile-shader building-shader)
(append-shader building-shader)
