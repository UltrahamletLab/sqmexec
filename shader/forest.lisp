;;; forest.lisp — マングローブ林 (Shadertoy "foggy forest" 移植) のサーフェスシェーダー
;;;
;;; SDF leaf `forest` 専用。エンジンがヒット点で material と幹周り角度を算出し、
;;;   s = material (0=地面 1=樹皮)
;;;   t = 幹周り角度 atan2(treeP.x, treeP.z) ∈ [-pi,pi]
;;; として渡してくる (intersect.c の forest_info → setup_sgv)。
;;; 樹皮/地面の両マテリアルを毎ピクセル計算し step(0.5,s) で選択する
;;; (DSL の if は単一式制約があるため、両方算出して float ブレンドで合成)。
;;; ライティングは元コードの偽AOではなくエンジンの diffuse+ambient+IQソフト影を使い、
;;; 暖色サン+青空フィルの2灯 (scene側) で元の色味を出す。fBm は共有値ノイズ vfbm/vnoise。
;;;
;;; パラメータ定義順 (shade_dr.c の forest_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3

(setq forest-shader
(make-shader forest :keyword :surface
  (((Ka float) 0.30) ((Kd float) 0.95) ((Ks float) 0.04) ((roughness float) 0.5))
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((ang float) 0) ((py float) 0)
    ((qx float) 0) ((qy float) 0)
    ;; --- bark ---
    ((bh float) 0) ((bhx float) 0) ((bhy float) 0)
    ((bmate color) (make-color 0 0 0))
    ((lich float) 0) ((dbk float) 0) ((dtg float) 0)
    ((mossn float) 0) ((crev float) 0) ((moss float) 0) ((baoF float) 0)
    ((tdir point) (make-point 1 0 0)) ((bdir point) (make-point 0 0 1))
    ((bNb point) (make-point 0 1 0))
    ;; --- ground ---
    ((gpx float) 0) ((gpz float) 0) ((gqx float) 0) ((gqz float) 0)
    ((gh float) 0) ((ghx float) 0) ((ghz float) 0)
    ((gmate color) (make-color 0 0 0)) ((gcol color) (make-color 0 0 0))
    ((gmix float) 0) ((gpatch float) 0) ((gdet float) 0) ((gdead float) 0) ((gaoF float) 0)
    ((grnx float) 0) ((grnz float) 0)
    ((tdir2 point) (make-point 1 0 0)) ((bdir2 point) (make-point 0 0 1))
    ((gbump point) (make-point 0 1 0)) ((gNb point) (make-point 0 1 0))
    ;; --- select / output ---
    ((sel float) 0) ((aoF float) 0)
    ((mate color) (make-color 0 0 0)) ((Nb point) (make-point 0 1 0))
    ((nbx float) 0) ((nby float) 0) ((nbz float) 0))

  ;; ════════════ BARK ════════════ (rootUV = (angle, P.y))
  (setvar ang t) (setvar py (ycomp P))
  ;; barkTexture(ang, py) → bh
  (setvar qx (* ang 20.0)) (setvar qy (* py 3.0))
  (setvar qx (+ qx (* (vfbm (make-point (* qx 0.3) (* qy 0.3) 0.0) 3) 5.0)))
  (setvar qy (+ qy (* (vfbm (make-point (* qx 0.5) (* qy 0.5) 0.0) 3) 2.0)))
  (setvar bh (vfbm (make-point qx qy 0.0) 6))
  (setvar bh (+ bh (* (vfbm (make-point (* qx 2.5) (* qy 2.5) 0.0) 4) 0.4)))
  (setvar bh (* (pow bh 1.2) 1.5))
  ;; barkTexture(ang+0.015, py) → bhx
  (setvar qx (* (+ ang 0.015) 20.0)) (setvar qy (* py 3.0))
  (setvar qx (+ qx (* (vfbm (make-point (* qx 0.3) (* qy 0.3) 0.0) 3) 5.0)))
  (setvar qy (+ qy (* (vfbm (make-point (* qx 0.5) (* qy 0.5) 0.0) 3) 2.0)))
  (setvar bhx (vfbm (make-point qx qy 0.0) 6))
  (setvar bhx (+ bhx (* (vfbm (make-point (* qx 2.5) (* qy 2.5) 0.0) 4) 0.4)))
  (setvar bhx (* (pow bhx 1.2) 1.5))
  ;; barkTexture(ang, py+0.015) → bhy
  (setvar qx (* ang 20.0)) (setvar qy (* (+ py 0.015) 3.0))
  (setvar qx (+ qx (* (vfbm (make-point (* qx 0.3) (* qy 0.3) 0.0) 3) 5.0)))
  (setvar qy (+ qy (* (vfbm (make-point (* qx 0.5) (* qy 0.5) 0.0) 3) 2.0)))
  (setvar bhy (vfbm (make-point qx qy 0.0) 6))
  (setvar bhy (+ bhy (* (vfbm (make-point (* qx 2.5) (* qy 2.5) 0.0) 4) 0.4)))
  (setvar bhy (* (pow bhy 1.2) 1.5))
  ;; wood color ramp
  (setvar bmate (mix (make-color 0.08 0.06 0.05) (make-color 0.15 0.13 0.11) (smoothstep 0.3 0.7 bh)))
  (setvar bmate (mix bmate (make-color 0.24 0.21 0.18) (smoothstep 0.7 1.2 bh)))
  ;; lichen (greenish patches)
  (setvar lich (vfbm (make-point (* ang 8.0) (* py 8.0) 0.0) 3))
  (setvar bmate (mix bmate (make-color 0.35 0.38 0.32) (smoothstep 0.65 0.85 lich)))
  ;; dead/weathered bark on high ridges
  (setvar dbk (vnoise (make-point (* ang 4.0) (* py 4.0) 0.0)))
  (setvar bmate (mix bmate (make-color 0.35 0.33 0.30)
                     (* (smoothstep 0.75 0.85 dbk) (smoothstep 1.0 1.4 bh))))
  ;; moss near the ground (distToGround approx: ground level ~ -1.5)
  (setvar dtg (- py -1.5))
  (setvar mossn (vfbm (make-point (* ang 6.0) (* py 6.0) 0.0) 3))
  (setvar crev (- 1.0 (smoothstep 0.5 1.0 bh)))
  (setvar moss (smoothstep 0.3 0.8 (+ (* (clamp (- 1.0 dtg) 0.0 1.0) 0.6)
                                      (* mossn 0.4) (* crev 0.4))))
  (setvar bmate (mix bmate (make-color 0.12 0.18 0.07) (clamp moss 0.0 1.0)))
  ;; bark AO + bump
  (setvar baoF (pow (clamp (+ (* bh 0.7) 0.1) 0.0 1.0) 1.2))
  (setvar tdir (normalize (cross Nf (make-point 0.0 1.0 0.0))))
  (setvar bdir (normalize (cross tdir Nf)))
  (setvar bNb (normalize (- Nf (+ (* tdir (* (/ (- bhx bh) 0.015) 0.10))
                                  (* bdir (* (/ (- bhy bh) 0.015) 0.06))))))

  ;; ════════════ GROUND ════════════ (groundTexture over P.xz)
  (setvar gpx (xcomp Pg)) (setvar gpz (zcomp Pg))
  ;; groundTexture(gpx,gpz) → gh  (domain warp + 5-octave value noise, a=1 f=2)
  (setvar gqx (+ gpx (* (vfbm (make-point (* gpx 1.5) (* gpz 1.5) 0.0) 3) 0.4)))
  (setvar gqz (+ gpz (* (vfbm (make-point (+ (* gpx 1.5) 5.2) (+ (* gpz 1.5) 5.2) 0.0) 3) 0.4)))
  (setvar gh (+ (* 1.0    (vnoise (make-point (* gqx 2.0)  (* gqz 2.0)  0.0)))
                (* 0.5    (vnoise (make-point (* gqx 4.0)  (* gqz 4.0)  0.0)))
                (* 0.25   (vnoise (make-point (* gqx 8.0)  (* gqz 8.0)  0.0)))
                (* 0.125  (vnoise (make-point (* gqx 16.0) (* gqz 16.0) 0.0)))
                (* 0.0625 (vnoise (make-point (* gqx 32.0) (* gqz 32.0) 0.0)))))
  ;; gradient samples for bump (offset 0.02 in x and z)
  (setvar gqx (+ (+ gpx 0.02) (* (vfbm (make-point (* (+ gpx 0.02) 1.5) (* gpz 1.5) 0.0) 3) 0.4)))
  (setvar gqz (+ gpz (* (vfbm (make-point (+ (* (+ gpx 0.02) 1.5) 5.2) (+ (* gpz 1.5) 5.2) 0.0) 3) 0.4)))
  (setvar ghx (+ (* 1.0    (vnoise (make-point (* gqx 2.0)  (* gqz 2.0)  0.0)))
                 (* 0.5    (vnoise (make-point (* gqx 4.0)  (* gqz 4.0)  0.0)))
                 (* 0.25   (vnoise (make-point (* gqx 8.0)  (* gqz 8.0)  0.0)))
                 (* 0.125  (vnoise (make-point (* gqx 16.0) (* gqz 16.0) 0.0)))
                 (* 0.0625 (vnoise (make-point (* gqx 32.0) (* gqz 32.0) 0.0)))))
  (setvar gqx (+ gpx (* (vfbm (make-point (* gpx 1.5) (* (+ gpz 0.02) 1.5) 0.0) 3) 0.4)))
  (setvar gqz (+ (+ gpz 0.02) (* (vfbm (make-point (+ (* gpx 1.5) 5.2) (+ (* (+ gpz 0.02) 1.5) 5.2) 0.0) 3) 0.4)))
  (setvar ghz (+ (* 1.0    (vnoise (make-point (* gqx 2.0)  (* gqz 2.0)  0.0)))
                 (* 0.5    (vnoise (make-point (* gqx 4.0)  (* gqz 4.0)  0.0)))
                 (* 0.25   (vnoise (make-point (* gqx 8.0)  (* gqz 8.0)  0.0)))
                 (* 0.125  (vnoise (make-point (* gqx 16.0) (* gqz 16.0) 0.0)))
                 (* 0.0625 (vnoise (make-point (* gqx 32.0) (* gqz 32.0) 0.0)))))
  ;; dirt → grass material blend
  (setvar gmix (smoothstep 0.4 0.8 gh))
  (setvar gmate (mix (make-color 0.08 0.06 0.05) (make-color 0.12 0.10 0.08) (smoothstep 0.1 0.6 gh)))
  (setvar gpatch (vfbm (make-point (* gpx 4.0) (* gpz 4.0) 0.0) 3))
  (setvar gcol (mix (make-color 0.08 0.12 0.05) (make-color 0.14 0.20 0.08) (smoothstep 0.3 0.7 gpatch)))
  (setvar gdet (vfbm (make-point (* gpx 15.0) (* gpz 15.0) 0.0) 3))
  (setvar gcol (mix gcol (make-color 0.20 0.28 0.12) (smoothstep 0.6 0.9 gdet)))
  (setvar gmate (mix gmate gcol gmix))
  (setvar gdead (vfbm (make-point (+ (* gpx 3.0) 10.0) (+ (* gpz 3.0) 10.0) 0.0) 3))
  (setvar gmate (mix gmate (make-color 0.16 0.14 0.08) (smoothstep 0.70 0.9 gdead)))
  (setvar gaoF (clamp (+ 0.2 (* 0.8 (/ gh 1.5))) 0.0 1.0))
  ;; ground bump + grass micro-grain
  (setvar tdir2 (normalize (cross Nf (make-point 0.0 0.0 1.0))))
  (setvar bdir2 (normalize (cross tdir2 Nf)))
  (setvar gbump (normalize (- Nf (+ (* tdir2 (* (/ (- ghx gh) 0.02) 0.15))
                                    (* bdir2 (* (/ (- ghz gh) 0.02) 0.15))))))
  (setvar grnx (- (vnoise (make-point (* gpx 120.0) (* gpz 120.0) 0.0)) 0.5))
  (setvar grnz (- (vnoise (make-point (+ (* gpx 120.0) 13.5) (+ (* gpz 120.0) 7.3) 0.0)) 0.5))
  (setvar gNb (normalize (+ gbump (+ (* tdir2 (* grnx (* 0.4 gmix)))
                                     (* bdir2 (* grnz (* 0.4 gmix)))))))

  ;; ════════════ SELECT (sel=1 樹皮 / 0 地面) ════════════
  (setvar sel (step 0.5 s))
  (setvar mate (mix gmate bmate sel))
  (setvar aoF (+ (* (- 1.0 sel) gaoF) (* sel baoF)))
  (setvar nbx (+ (* (- 1.0 sel) (xcomp gNb)) (* sel (xcomp bNb))))
  (setvar nby (+ (* (- 1.0 sel) (ycomp gNb)) (* sel (ycomp bNb))))
  (setvar nbz (+ (* (- 1.0 sel) (zcomp gNb)) (* sel (zcomp bNb))))
  (setvar Nb (normalize (make-point nbx nby nbz)))

  ;; ════════════ LIGHTING (engine diffuse+ambient+shadow) ════════════
  (setvar Oi Os)
  (setvar Ci (* Oi (* aoF (+ (* mate (+ (* Ka (ambient)) (* Kd (diffuse Nb))))
                             (* Ks (specular Nb Ir roughness))))))
)))

(compile-shader forest-shader)
(append-shader forest-shader)
