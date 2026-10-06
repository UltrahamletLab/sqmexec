;;; poseidon.lisp — FFT 海面のサーフェスシェーダー
;;;
;;; https://github.com/owenyuwono/poseidon の
;;;   src/ocean/oceanSurfaceMaterial.js (colorNode) を SQM の DSL に移植したもの。
;;; 原典と同じ組み立て:
;;;   フレネルで「水体色」と「空の反射」を混ぜ、日向の波頭に SSS を足し、
;;;   累積ヤコビアン由来の泡で崩れた波頭を白くする。細かい法線ノイズで
;;;   面と泡の均一さを崩す。
;;;
;;; SQM 側での違いは2点だけ:
;;;   - 空の反射は解析式ではなく **本物の (trace ...)** — シーンの空ドーム
;;;     (fakesky2) をそのまま映すので、雲も太陽も反射に出る。
;;;   - 泡は GPU のストレージテクスチャではなく、tools/gen_poseidon_ocean.py が
;;;     焼いた **ワールドXZ タイリングの PNG**。R=coverage / G=core。
;;;     変位後の位置に散布して焼いてあるので波頭と一致する。
;;;
;;; 幾何 (変位・法線) はシェーダーではなく blob 点群そのものが持つ。
;;; ここで N を触るのはサブグリッドのさざ波だけ。
;;;
;;; パラメータ定義順 = shade_dr.cpp の poseidon_params[] と一致必須:
;;;   Ka=0 Kd=1 Ks=2 roughness=3 Kr=4 deep-color=5 scatter-color=6 foam-color=7
;;;   sun-glint=8 sss=9 detail=10 detail-freq=11 foam-map=12 foam-tile=13
;;;   foam-texels=14 foam-gain=15 sundir=16 fade-far=17

(setq poseidon-shader
(make-shader poseidon :keyword :surface
  (((Ka float) 0.0) ((Kd float) 0.0) ((Ks float) 1.0)
   ((roughness float) 0.006)
   ((Kr float) 0.92)
   ((deep-color    color) (make-color 0.027 0.102 0.149))   ; params.js colors.deep
   ((scatter-color color) (make-color 0.180 0.560 0.560))   ;              .scatter
   ((foam-color    color) (make-color 0.862 0.905 0.917))   ;              .foam
   ((sun-glint     float) 3.0)
   ((sss           float) 1.0)     ; sssStrength
   ((detail        float) 0.10)    ; detailStrength (サブグリッド法線ノイズ)
   ((detail-freq   float) 0.55)    ; その基本周波数 [cycles/m]
   ((foam-map      string) "")
   ((foam-tile     float) 250.0)   ; 泡テクスチャのワールド周期 [m]
   ((foam-texels   float) 2048.0)
   ((foam-gain     float) 1.0)
   ((sundir        point) (make-point 0.14 0.19 0.97))
   ((fade-far      float) 520.0))  ; これ以遠は細部/グリントを落として遠景を鎮める
  (enter (
    ((Nf   point) (faceforward (normalize N) I))
    ((vd   point) (normalize (- I)))
    ((sdir point) (make-point 0 1 0))
    ((rdir point) (make-point 0 1 0))
    ((hv   point) (make-point 0 1 0))
    ((px float) 0) ((pz float) 0) ((py float) 0)
    ((dst float) 0) ((fade float) 0) ((invf float) 1)
    ((dnx float) 0) ((dnz float) 0) ((ee float) 0)
    ((fres float) 0) ((facing float) 0)
    ((hitf float) 0)
    ((hgt float) 0) ((sssv float) 0)
    ((uu float) 0) ((vv float) 0) ((au float) 0) ((av float) 0)
    ((fu float) 0) ((fv float) 0) ((u0 float) 0) ((u1 float) 0)
    ((v0 float) 0) ((v1 float) 0) ((tw float) 2048)
    ((covv float) 0) ((corev float) 0) ((bub float) 0) ((flit float) 0)
    ((c00 color) (make-color 0 0 0)) ((c10 color) (make-color 0 0 0))
    ((c01 color) (make-color 0 0 0)) ((c11 color) (make-color 0 0 0))
    ((bod   color) (make-color 0 0 0))
    ((refl  color) (make-color 0 0 0))
    ((wat   color) (make-color 0 0 0))
    ((foamc color) (make-color 0 0 0)))

  (setvar px (xcomp Pg)) (setvar py (ycomp Pg)) (setvar pz (zcomp Pg))
  (setvar sdir (normalize sundir))

  ;; --- 距離フェード: 遠景は細部もグリントも落として鎮める (LOD) ------------
  (setvar dst (length (- E Pg)))
  (setvar fade (smoothstep (* fade-far 0.35) fade-far dst))
  (setvar invf (- 1 fade))

  ;; --- サブグリッドのさざ波 (原典 detailTex の2スケール分に相当) ------------
  ;;     blob 1個より細かい起伏は幾何では持てないので法線だけ揺らす。
  (setvar ee (* detail-freq 1.0))
  (setvar dnx (- (vnoise (make-point (* (+ px 0.35) ee) 3.1 (* pz ee)))
                 (vnoise (make-point (* (- px 0.35) ee) 3.1 (* pz ee)))))
  (setvar dnz (- (vnoise (make-point (* px ee) 3.1 (* (+ pz 0.35) ee)))
                 (vnoise (make-point (* px ee) 3.1 (* (- pz 0.35) ee)))))
  (setvar ee (* detail-freq 3.7))
  (setvar dnx (+ dnx (* 0.45 (- (vnoise (make-point (* (+ px 0.13) ee) 7.7 (* pz ee)))
                                (vnoise (make-point (* (- px 0.13) ee) 7.7 (* pz ee)))))))
  (setvar dnz (+ dnz (* 0.45 (- (vnoise (make-point (* px ee) 7.7 (* (+ pz 0.13) ee)))
                                (vnoise (make-point (* px ee) 7.7 (* (- pz 0.13) ee)))))))
  (setvar Nf (normalize (make-point (+ (xcomp Nf) (* detail invf dnx 6))
                                    (ycomp Nf)
                                    (+ (zcomp Nf) (* detail invf dnz 6)))))

  ;; --- フレネル (原典と同じ 0.02 + 0.98(1-N.V)^5) --------------------------
  (setvar facing (clamp (dot Nf vd) 0 1))
  (setvar fres (+ 0.02 (* 0.98 (pow (- 1 facing) 5))))

  ;; --- 空の反射 (上半球にクランプしてから本物の trace) ----------------------
  (setvar rdir (reflect I Nf))
  (setvar rdir (normalize (make-point (xcomp rdir) (max (abs (ycomp rdir)) 0.02)
                                      (zcomp rdir))))
  (setvar refl (* Kr (trace P rdir hitf)))

  ;; --- 水体色 + 日向の波頭の SSS ------------------------------------------
  (setvar hgt (clamp (+ (* py 0.5) 0.4) 0 1))
  (setvar hv (normalize (+ (- Nf) sdir)))
  (setvar sssv (* (pow (clamp (dot vd (- hv)) 0 1) 4) sss hgt))
  (setvar bod (mix deep-color scatter-color (clamp (+ 0.12 sssv) 0 1)))
  (setvar wat (mix bod refl fres))

  ;; --- 太陽グリッター (波面の鋭いスペキュラ) --------------------------------
  ;;     シーンのライトは太陽1灯だけにしておくこと (specular は全灯を舐めるので、
  ;;     補助光を置くと海面のどこかにもう1つグリントの道ができる)。
  (setvar wat (+ wat (* sun-glint invf Ks (specular Nf vd roughness))))

  ;; --- 泡 (焼いたワールドXZタイル。sqm の texture() は最近傍なので手で bilinear)
  (if (string/= foam-map "")
    (progn
      (setvar tw (max foam-texels 2))
      ;; ルックアップを数十cmスケールで歪ませる。焼いたタイルは 6cm/texel なので
      ;; 近景では 1テクセルが数ピクセルに拡大され、bilinear の丸い染みが
      ;; 「泡」でなく「雪の粒」に見える。歪ませると縁が有機的にほつれる。
      (setvar uu (+ (/ px foam-tile)
                    (* 0.0011 (- (vnoise (make-point (* px 2.7) 11.3 (* pz 2.7))) 0.5))
                    (* 0.0004 (- (vnoise (make-point (* px 9.1) 21.7 (* pz 9.1))) 0.5))))
      (setvar vv (+ (/ pz foam-tile)
                    (* 0.0011 (- (vnoise (make-point (* px 2.7) 31.9 (* pz 2.7))) 0.5))
                    (* 0.0004 (- (vnoise (make-point (* px 9.1) 43.3 (* pz 9.1))) 0.5))))
      (setvar au (- (* uu tw) 0.5)) (setvar av (- (* vv tw) 0.5))
      (setvar fu (- au (floor au))) (setvar fv (- av (floor av)))
      (setvar u0 (/ (+ (floor au) 0.5) tw)) (setvar u1 (+ u0 (/ 1 tw)))
      (setvar v0 (/ (+ (floor av) 0.5) tw)) (setvar v1 (+ v0 (/ 1 tw)))
      (setvar c00 (texture foam-map u0 v0)) (setvar c10 (texture foam-map u1 v0))
      (setvar c01 (texture foam-map u0 v1)) (setvar c11 (texture foam-map u1 v1))
      (setvar covv (+ (* (+ (* (comp c00 0) (- 1 fu)) (* (comp c10 0) fu)) (- 1 fv))
                      (* (+ (* (comp c01 0) (- 1 fu)) (* (comp c11 0) fu)) fv)))
      (setvar corev (+ (* (+ (* (comp c00 1) (- 1 fu)) (* (comp c10 1) fu)) (- 1 fv))
                       (* (+ (* (comp c01 1) (- 1 fu)) (* (comp c11 1) fu)) fv)))
      (setvar covv (clamp (* covv foam-gain) 0 1))
      ;; 泡の「粒」は被覆率でなく明るさだけを揺らす (原典と同じ — 被覆を削ると点々になる)
      (setvar bub (clamp (+ 0.30 (* 0.55 (vfbm (make-point (* px 3.1) 1.7 (* pz 3.1)) 3))
                              (* 0.35 (vfbm (make-point (* px 11) 5.3 (* pz 11)) 2))) 0 1))
      ;; 白波は「太陽 + 空ドーム全体」で照らされる拡散面。原典の定数 (0.55+0.6cos)
      ;; は three.js 側の出力変換込みの値で、sqm の線形→表示そのままの経路だと
      ;; 灰色の泥に見える → 環境項を上げてある。
      (setvar flit (+ 0.92 (* 0.50 (clamp (dot Nf sdir) 0 1))))
      (setvar foamc (* foam-color flit (+ 0.76 (* 0.24 bub))))
      (setvar foamc (mix foamc (* foamc 1.25) corev))
      (setvar wat (mix wat foamc covv))))

  (setvar Oi Os)
  (setvar Ci (* Oi (+ wat (* Ka bod (ambient)))))
)))

(compile-shader poseidon-shader)
(append-shader poseidon-shader)
