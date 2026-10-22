;;; uberlight.lisp — SQM/DR reduced port of BMRT uberlight.sl.
;;; Keeps near/far gates, inverse-power falloff, beam shaping, superellipse barn-door
;;; gate and procedural breakup. SQM applies visibility shadows outside this shader.
;;; 2026-08-09 修理: dist が (length L) だった — sqm の illuminate は L を単位化する
;;;   ため **dist≡1 で cuton/cutoff (この光源の看板機能) が全部死んでいた**
;;;   (既定値と suite のゲートは「たまたま 1 がゲート内」で素通し)。
;;;   dist = length(P - from) に修正。あわせて /(dist²) を除去 — これは spotlight の
;;;   1/(L·L) を引き写した項で dist≡1 のため常に ÷1 (=除去と等価)、しかも**原典の
;;;   uberlight に自動 1/r² は無い** (距離減衰は falloff param の仕事)。
;;;   falloff を末尾追加 (sentinel 解決で既定 0 = 従来の絵)。
;;;
;;; 2026-08-09 フル版の小物5点を末尾追加 (既定は全部「従来の絵とビット一致」):
;;;   omni                     — 全方位ライト。原典の lighttype "omni" 相当。
;;;                              円錐角を PI にして (=cos PI が -1 なので全方向が
;;;                              通る) 円錐減衰・beam-distribution・超楕円ゲートを
;;;                              外す。距離ゲート/falloff/斑れは効いたまま。
;;;   falloffdist / maxintensity — 原典の距離減衰の完全形。
;;;                              dist >= falloffdist では (falloffdist/dist)^falloff。
;;;                              内側は発散するので maxintensity へなめらかクランプ
;;;                              (原典どおり maxintensity/intensity で正規化する
;;;                               = Cl = atten*intensity の上限が maxintensity)。
;;;                              **maxintensity は intensity より大きく取ること** —
;;;                              原典の式は mi>1 でしか収束しない (下の注記)。
;;;   nearedge / faredge       — cuton 側と cutoff 側の遷移幅を個別に。
;;;                              未指定なら両方 edge に解決される (C 側 sentinel)。
;;;                              **原典は cuton の外側 (cuton-nearedge → cuton) に
;;;                              ランプを置くが、この移植は従来どおり内側
;;;                              (cuton → cuton+nearedge) のまま**。既定でビット一致
;;;                              させるため位置は変えず、幅だけ分離した。
;;;   shearx / sheary          — 光錐の中心をずらす。**原典は z=1 平面に投影した
;;;                              (x/z, y/z) から引くが、この移植の超楕円は方向余弦
;;;                              (dot Ln right) の上で評価している**ので、shear も
;;;                              同じ「サイン」の単位で効く (原典の tan 単位ではない)。
;;;   noiseoffset              — 斑れの空間オフセット (アニメで流せる)。
;;;
;;; 追加分の並びは C 側 setup_uberlight の lightArgs[16..23] と 1:1。

(setq uberlight-shader
(make-shader uberlight :keyword :light
  (((intensity float) 1.0) ((light-color color) (make-color 1 1 1))
   ((from point) (make-point 0 4 -6)) ((to point) (make-point 0 0 0))
   ((cone-angle float) 0.55) ((cone-delta-angle float) 0.10)
   ((beam-distribution float) 2.0) ((cuton float) 0.0) ((cutoff float) 100000.0)
   ((width float) 1.0) ((height float) 1.0) ((roundness float) 1.0)
   ((edge float) 0.10) ((noiseamp float) 0.0) ((noisefreq float) 1.0)
   ((falloff float) 0.0)
   ;; ↓ 2026-08-09 末尾追加 (既定 = 従来と同値)
   ((omni float) 0.0) ((falloffdist float) 1.0) ((maxintensity float) 1.0)
   ((nearedge float) 0.10) ((faredge float) 0.10)
   ((shearx float) 0.0) ((sheary float) 0.0)
   ((noiseoffset point) (make-point 0 0 0)))
  (enter (((A point) (normalize (- to from))) ((cosout float) (cos cone-angle))
          ((cosin float) (cos (- cone-angle cone-delta-angle)))
          ((ca float) 0) ((dist float) 0) ((atten float) 0)
          ((gate float) 0) ((shape float) 0) ((expo float) 2)
          ((coneang float) 0) ((mifac float) 1) ((sfall float) 0) ((bfall float) 0)
          ((xsh float) 0) ((ysh float) 0)
          ((right point) (normalize (cross A (make-point 0 1 0))))
          ((upv point) (make-point 0 1 0)) ((Ln point) (make-point 0 0 1)))
    (setvar upv (normalize (cross right A)))
    ;; omni = 全方位。cos(PI) = -1 なので sqm_illuminate の円錐テスト
    ;; (ca < cos angle で棄却) を必ず通る。
    (setvar coneang cone-angle)
    (if (> omni 0.5) (setvar coneang PI))
    (illuminate (from A coneang)
      (setvar dist (max (length (- P from)) 0.0001))
      (setvar Ln L)
      (setvar ca (dot Ln A))
      (setvar atten (* (smoothstep cosout cosin ca)
                       (pow (max ca 0) beam-distribution)))
      ;; 全方位では円錐減衰も beam-distribution も無い (原典と同じ)
      (if (> omni 0.5) (setvar atten 1.0))
      (if (> falloff 0.001)
          (if (>= dist falloffdist)
              ;; 遠側: 原典の I = (falloffdist/dist)^falloff
              (setvar atten (* atten (pow (/ falloffdist dist) falloff)))
              ;; 近側: 発散を maxintensity へなめらかにクランプ
              ;;   s = log(1/mi), beta = -falloff/s, I = mi * exp(s * (d/fd)^beta)
              ;;   ※ この式が収束するのは **mi > 1 のときだけ** (mi=maxintensity/intensity)。
              ;;     mi>1 なら s<0, beta>0 で d→0 が I→mi (=クランプ)、d=fd で I=1 と
              ;;     遠側になめらかに繋がる。mi<=1 だと beta<0 になって d→0 で発散する
              ;;     (原典の maxintensity は「falloffdist での明るさより上に置く天井」)。
              ;;     mi<=1 (既定の 1 を含む) は天井なし = falloffdist の値で頭打ち、
              ;;     と読み替えて atten を据え置く (d=fd で連続・単調)。
              (progn
                (setvar mifac (/ maxintensity (max intensity 0.0001)))
                (if (> mifac 1.000001)
                    (progn
                      (setvar sfall (log (/ 1.0 mifac)))
                      (setvar bfall (/ (- 0.0 falloff) sfall))
                      (setvar atten (* atten mifac
                                       (exp (* sfall (pow (/ dist falloffdist) bfall))))))))))
      (setvar gate (* (smoothstep cuton (+ cuton nearedge) dist)
                      (- 1 (smoothstep (- cutoff faredge) cutoff dist))))
      ;; 断面の超楕円 (バーンドア)。全方位では断面そのものが無い。
      (if (< omni 0.5)
          (progn
            (setvar expo (/ 2.0 (max roundness 0.05)))
            (setvar xsh (- (dot Ln right) shearx))
            (setvar ysh (- (dot Ln upv) sheary))
            (setvar shape (+ (pow (/ (abs xsh) (max width 0.001)) expo)
                             (pow (/ (abs ysh) (max height 0.001)) expo)))
            (setvar gate (* gate (- 1 (smoothstep 1.0 (+ 1.0 edge) shape))))))
      (setvar gate (* gate (+ 1 (* noiseamp
                                   (- (* 2 (noise (* (+ P noiseoffset) noisefreq))) 1)))))
      (setvar Cl (* intensity light-color atten (clamp gate 0 1)))))))
(compile-shader uberlight-shader)
(append-shader uberlight-shader)
