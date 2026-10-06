;;; sierpinski.lisp — シェルピンスキー四面体をループで描く表面シェーダー (2026-08-03)
;;;
;;; geo_show + gen_sierpinski.py (chaos game 点描) の姉妹版。こちらは点群を作らず、
;;; シェーディング点ごとに「3D ガスケットへの近似距離」を四面体フォールドの反復で
;;; 計算して塗り分ける — DSL ループ拡張 (repeat/progn-if) の実戦例。
;;;
;;; フォールド (IQ の sierpinski tetra と同型):
;;;   3枚の対角面で折り返し → 頂点 (1,1,1) 基準に 2 倍拡大、を iters 回。
;;;   ガスケット上の点は原点近傍に留まり、外の点は発散する。
;;;   近似距離 d = |p| · 2^-iters を thickness で smoothstep して塗る。
;;; 判定領域は center を中心に scale 半径の四面体 (頂点 (±1,±1,±1) の偶置換)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の sierpinski_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 iters=4 scale=5 center=6
;;;   thickness=7 gasket-color=8 base-color=9

(setq sierpinski-shader
(make-shader sierpinski :keyword :surface
  (((Ka float) 0.25)
   ((Kd float) 0.85)
   ((Ks float) 0.25)
   ((roughness float) 0.10)
   ((iters float) 6.0)
   ((scale float) 1.0)
   ((center point) (make-point 0 0 0))
   ((thickness float) 0.05)
   ((gasket-color color) (make-color 0.85 0.10 0.08))
   ((base-color color) (make-color 0.93 0.89 0.80))
   ((base-opacity float) 1.0))  ; 非ガスケット部の不透明度。<1で「模様だけ浮かぶ」
                                ; (0.06未満はsqmのカットアウト帯なのでclamp)
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((px float) 0) ((py float) 0) ((pz float) 0)
          ((tt float) 0) ((j float) 0)
          ((dd float) 0) ((sel float) 0) ((oiv float) 1)
          ((surf color) (make-color 0 0 0)))
    (setvar px (/ (- (xcomp Pg) (xcomp center)) scale))
    (setvar py (/ (- (ycomp Pg) (ycomp center)) scale))
    (setvar pz (/ (- (zcomp Pg) (zcomp center)) scale))
    ;; 四面体フォールド × iters (repeat + progn つき if — ループ拡張の実戦例)
    (repeat (j iters)
      (if (< (+ px py) 0)
          (progn (setvar tt px) (setvar px (- 0 py)) (setvar py (- 0 tt))))
      (if (< (+ px pz) 0)
          (progn (setvar tt px) (setvar px (- 0 pz)) (setvar pz (- 0 tt))))
      (if (< (+ py pz) 0)
          (progn (setvar tt py) (setvar py (- 0 pz)) (setvar pz (- 0 tt))))
      (setvar px (- (* 2 px) 1))
      (setvar py (- (* 2 py) 1))
      (setvar pz (- (* 2 pz) 1)))
    ;; 近似距離 (縮尺を畳み戻す) → thickness 幅でガスケット色
    (setvar dd (* (sqrt (+ (* px px) (+ (* py py) (* pz pz))))
                  (pow 2 (- 0 iters))))
    (setvar sel (- 1 (smoothstep 0 thickness dd)))
    (setvar surf (mix base-color gasket-color sel))
    ;; 非ガスケット部を base-opacity まで透明化 (半透明帯 0.06.. の屈折レイ合成。
    ;; scene 側は kt≈0 + roi 1.0 素通し・多層通過するので -D 8 推奨)
    (setvar oiv (clamp (+ base-opacity (* (- 1 base-opacity) sel)) 0.06 1))
    (setvar Oi (* Os oiv))
    (setvar Ci (* Oi (+ (* surf (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* Ks (specular Nf Ir roughness))))))))
(compile-shader sierpinski-shader)
(append-shader sierpinski-shader)
