;;; brushedmetal — Ward 異方性のヘアライン金属
;;;
;;; 移植元: BMRT brushedmetal.sl + material.h の MaterialBrushedMetal
;;;         + locillum.h の LocIllumWardAnisotropic
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;   参考: Advanced RenderMan (Apodaca & Gritz, 1999)
;;;
;;;   Ci = Cs * (Ka*ambient() + Kd*diffuse(Nf) + Ks*Ward(Nf, -I, dPdu, ur, vr))
;;;   ※ ローカル名 V は**グローバル v と大文字小文字非区別で衝突する**ので Vd。
;;;   Ward:  X = xdir/ur,  Y = (N^xdir)/vr
;;;          rho = exp(-2*((X.H)^2+(Y.H)^2)/(1+H.N)) / sqrt(cti*ctr)
;;;          C  = Σ_lights Cl * cti * rho   /  (4*ur*vr)
;;;
;;; ── sqm 版の違い ────────────────────────────────────────────────
;;; ・原典は `illuminance` で光源を反復するが、sqm の DSL には光源反復が無く、
;;;   多灯合算は C 側の決め打ち BRDF (diffuse/specular/pbr) だけだった。
;;;   → **反復だけ**を開くフック2本を足した (2026-08-09):
;;;        (lightcount)  有効なライト数
;;;        (lightsel j)  j 番を選び L (面→光源, 単位) と Cl (可視度込み) を書き、
;;;                      可視度 [0,1] を返す
;;;   BRDF は下のとおり **.lisp 側にある** (「機構だけ C・中身は .lisp」)。
;;; ・RSL の `lightsource("__nonspecular", ..)` に相当する per-light 属性が sqm に
;;;   無いので落とした (全ライトが鏡面に寄与する)。
;;; ・**ブラシ目の向き**: 原典は normalize(dPdu)。sqm では UV を持つメッシュなら
;;;   dPdu が意味を持つが、**SDF/blob では法線から作った任意基底**なので向きが
;;;   保証されない (shade_dr.cpp の注記どおり)。そこで `brush-dir` を足した:
;;;     brush-dir = (0,0,0) → 原典どおり dPdu を使う
;;;     それ以外   → その世界方向を接平面へ射影してブラシ目にする (SDF 向き)
;;;
;;; パラメータ定義順 (shade_dr.cpp の brushedmetal_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 uroughness=3 vroughness=4 brush-dir=5
;;;
;;; 使い方 (シーン):
;;;   (surface (color 0.85 0.86 0.88) (ka 0.2) (kd 0.1) (ks 0.9) (phong 0)
;;;            (shader brushedmetal)
;;;            (param uroughness 0.08) (param vroughness 0.45)
;;;            (param brush-dir 1 0 0))
;;;   ※ ur < vr で「ブラシ目に沿って伸びたハイライト」。等しくすると等方 (Ward)。
;;;   ※ roughness を極端に小さくすると 1/(4*ur*vr) が跳ね上がるので Ks で抑える。

(setq brushedmetal-shader

(make-shader brushedmetal :keyword :surface
      (
       ((Ka         float) 1.0)
       ((Kd         float) 0.1)
       ((Ks         float) 0.9)
       ((uroughness float) 0.15)   ; ブラシ目方向の粗さ
       ((vroughness float) 0.5)    ; それに直交する方向の粗さ
       ((brush-dir  point) (make-point 0 0 0))  ; 0 なら dPdu を使う
       )

  (enter (((Nf  point) (faceforward (normalize N) I))
          ((Vd  point) (normalize (- I)))
          ((xd  point) (make-point 1 0 0))
          ((X   point) (make-point 1 0 0))
          ((Y   point) (make-point 0 1 0))
          ((LN  point) (make-point 0 0 1))
          ((H   point) (make-point 0 0 1))
          ((ctr float) 0.0) ((cti float) 0.0)
          ((xh  float) 0.0) ((yh  float) 0.0) ((hn float) 0.0)
          ((rho float) 0.0) ((g   float) 0.0)
          ((nl  float) 0.0) ((j   float) 0.0)
          ((spec color) (make-color 0 0 0)))

    ;; ── ブラシ目の接線 ─────────────────────────────────────────
    (setvar xd (normalize dPdu))
    (if (> (length brush-dir) 0.0001)
        (setvar xd (normalize (- brush-dir (* Nf (dot Nf brush-dir))))))

    ;; ── Ward の異方性基底 ──────────────────────────────────────
    (setvar X (/ xd (max uroughness 0.0001)))
    (setvar Y (/ (cross Nf xd) (max vroughness 0.0001)))
    (setvar ctr (clamp (dot Nf Vd) 0.0001 1.0))

    ;; ── illuminance 相当: 光源を回して Ward を積分する ──────────
    (setvar nl (lightcount))
    (repeat (j nl)
      ;; L (面→光源, 単位) と Cl (影・ボリューム減衰込み) が書かれる
      (setvar g (lightsel j))
      (setvar LN (normalize L))
      (setvar cti (dot LN Nf))
      (setvar H (normalize (+ Vd LN)))
      (setvar xh (dot X H))
      (setvar yh (dot Y H))
      (setvar hn (max (+ 1.0 (dot H Nf)) 0.0001))
      (setvar rho (/ (exp (/ (* -2.0 (+ (* xh xh) (* yh yh))) hn))
                     (sqrt (max (* cti ctr) 0.000001))))
      ;; 原典の if (cos_theta_i > 0) を step で。Cl は寄与なしのとき 0 が入る。
      (setvar spec (+ spec (* Cl (* (step 0.0 cti) (* cti rho))))))

    (setvar spec (/ spec (* 4.0 (* (max uroughness 0.0001) (max vroughness 0.0001)))))

    (setvar Oi Os)
    (setvar Ci (* Oi (* Cs (+ (* Ka (ambient))
                              (* Kd (diffuse Nf))
                              (* Ks spec)))))
)))

(compile-shader brushedmetal-shader)
(append-shader brushedmetal-shader)
