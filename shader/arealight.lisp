;;; arealight — 面光源用のライトシェーダー
;;;
;;; 移植元: BMRT arealight.sl
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;; 原典は2経路ある:
;;;   #ifdef BMRT : illuminate(P, N, PI/2) — 光源ジオメトリの標本点 P と法線 N
;;;                 を使い、Cl = intensity/(L.L) * lightcolor。
;;;   #else       : シェーダー空間の原点と +z を面と法線に見立てた近似。
;;;                 Cl = intensity * (Nl.normalize(L)) / (L.L) * lightcolor。
;;;
;;; sqm には「光源ジオメトリ」が無い (光源は点+radius) ので #else 経路を採り、
;;; 面の姿勢を shader 空間固定の +z ではなく from→to で与えられるようにした
;;; = 「from に置いた、to を向く平板パネル」。cos 落ち込み × 距離減衰。
;;;
;;; ── sqm 固有の注意 (原典と式が変わる唯一の点) ────────────────────────
;;; RSL の L は光源→面の**全長**ベクトルなので L.L = 距離² だが、
;;; sqm の illuminate (shade_dr.cpp sqm_illuminate) は L を**単位化して**渡す。
;;; したがって (dot L L) は常に 1 で距離減衰にならない (既存の pointlight/
;;; spotlight/uberlight の 1/(L.L) も同じ理由で実質無効になっている)。
;;; ここでは距離を L からではなく length(P - from) で復元して 1/dist^falloff を掛ける。
;;;
;;; falloff: 距離減衰の指数。2 = 原典どおりの逆二乗。0 で減衰なし
;;;   (sqm の他のライトと同じ明るさスケールになる)。逆二乗は距離が伸びると
;;;   すぐ暗くなるので、シーン単位が数十のときは intensity を dist² 倍で与える。

(setq arealight-shader

(make-shader arealight :keyword :light
      (
       ((intensity   float) 1.0)
       ((light-color color) (make-color 1 1 1))
       ((from        point) (make-point 0 4 0))   ; パネルの中心
       ((to          point) (make-point 0 0 0))   ; 向き先 (法線 = to - from)
       ((falloff     float) 2.0)                  ; 距離減衰の指数 (2=逆二乗)
       )

  (enter (((Nl     point) (normalize (- to from)))  ; 原典の Nl (=面の法線)
          ((PtoL   point) (make-point 0 0 0))
          ((dist   float) 0)
          ((cosang float) 0)
          ((atten  float) 0))

    ;; 原典: illuminate (point "shader" (0,0,0), Nl, PI/2)
    ;;   → 法線側の半球だけを照らす。裏面には光が回らない。
    (illuminate (from Nl (/ PI 2))
      ;; L は単位ベクトル (光源→面)。Nl.normalize(L) がそのまま cos。
      (setvar cosang (max (dot L Nl) 0))
      ;; 距離は L から取れない (上の注意) ので位置から復元する。
      (setvar PtoL (- P from))
      (setvar dist (max (length PtoL) 0.0001))
      (setvar atten (/ cosang (pow dist falloff)))
      (setvar Cl (* intensity light-color atten))))))

(compile-shader arealight-shader)
(append-shader arealight-shader)
