;;; brick — レンガ壁の表面シェーダー (brickbump の対)
;;;
;;; 移植元: BMRT brick.sl (+ patterns.h basicbrick)
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;; brickbump (2026-08-09 変位移植) と同じ格子の**色側**:
;;;   basicbrick → ragged エッジ (snoisexy ×4, 2オクターブ) → mortar/brick を
;;;   パルスで塗り分け → レンガ毎に明度ばらつき → Ka·ambient + Kd·diffuse。
;;; 原典後半の変位 (溝+あばた) は :surface では書けない → **brickbump を重ねる**。
;;;   格子パラメータ (brickwidth/brickheight/mortarthickness/jagged/rowvary/axis) を
;;;   **両者で一致させること** (原典の注意書きと同じ)。
;;;
;;; sqm 版の違い (brickbump と同一の読み替え):
;;;   s,t → axis 平面投影・ワールド単位 / filtered* → 固定 fuzz / mod は floor 基準 /
;;;   rowvary は原典で未使用 → basicbrick の rowstaggervary に接続 (既定 0.2 = 原典の literal)
;;;
;;; パラメータ定義順 (shade_dr.cpp brick_params[] と一致必須):
;;;   Ka=0 Kd=1 brickcolor=2 mortarcolor=3 raggedamp=4 raggedfreq=5 jagged=6
;;;   brickvary=7 brickwidth=8 brickheight=9 mortarthickness=10 rowvary=11 axis=12

(setq brick-shader

(make-shader brick :keyword :surface
      (
       ((Ka              float) 1.0)
       ((Kd              float) 1.0)
       ((brickcolor      color) (make-color 0.6 0.1 0.1))
       ((mortarcolor     color) (make-color 0.6 0.6 0.6))
       ((raggedamp       float) 0.04)
       ((raggedfreq      float) 12.0)
       ((jagged          float) 0.006)
       ((brickvary       float) 0.3)
       ((brickwidth      float) 0.28)
       ((brickheight     float) 0.07)
       ((mortarthickness float) 0.014)
       ((rowvary         float) 0.2)
       ((axis            float) 2.0)
       )

  (enter (((Nf point) (faceforward (normalize N) I))
          ((BMW float) (+ brickwidth  mortarthickness))
          ((BMH float) (+ brickheight mortarthickness))
          ((MWF float) (/ (* mortarthickness 0.5) (+ brickwidth  mortarthickness)))
          ((MHF float) (/ (* mortarthickness 0.5) (+ brickheight mortarthickness)))
          ((sc float) 0.0) ((tc float) 0.0)
          ((sc0 float) 0.0) ((tc0 float) 0.0)
          ((xt float) 0.0) ((yt float) 0.0)
          ((row float) 0.0) ((q float) 0.0)
          ((jx float) 0.0) ((jy float) 0.0)
          ((sb float) 0.0) ((tb float) 0.0)
          ((ss float) 0.0) ((tt float) 0.0)
          ((wb float) 0.0)
          ((fz float) 0.02)
          ((w float) 0.0) ((h float) 0.0)
          ((bc color) (make-color 0 0 0))
          ((Ct color) (make-color 0 0 0)))

    ;; ── 投影 (brickbump と同一) ──
    (setvar sc (xcomp Pg))
    (setvar tc (ycomp Pg))
    (if (< axis 0.5) (setvar sc (zcomp Pg)))
    (if (and (> axis 0.5) (< axis 1.5)) (setvar tc (zcomp Pg)))
    (setvar sc0 sc)
    (setvar tc0 tc)

    ;; ── basicbrick ──
    (setvar jx (noise (make-point (/ sc BMW) (/ tc BMH) 0.0)))
    (setvar jy (noise (make-point (+ (/ sc BMW) 17.3) (/ tc BMH) 0.0)))
    (setvar sc (+ sc (* jagged jx)))
    (setvar tc (+ tc (* jagged jy)))
    (setvar xt (/ sc BMW))
    (setvar yt (/ tc BMH))
    (setvar row (floor yt))
    (setvar q (* 0.5 row))
    (setvar xt (+ xt (- q (floor q))))
    (setvar xt (+ xt (* rowvary (- (noise (+ row 0.5)) 0.5))))
    (setvar sb (floor xt))
    (setvar ss (- xt sb))
    (setvar tb row)
    (setvar tt (- yt row))
    (setvar wb (+ (* 103.0 sb) tb))     ; whichbrick

    ;; ── ragged エッジ (snoisexy ×4 = 符号つき2Dノイズ, 2オクターブ) ──
    (setvar ss (+ ss (* raggedamp
                        (- (* 2.0 (noise (make-point (* (+ sc0 (* tb 5.15)) raggedfreq)
                                                     (* (+ tc0 (* sb 23.8)) raggedfreq) 0.0))) 1.0))))
    (setvar tt (+ tt (* raggedamp
                        (- (* 2.0 (noise (make-point (* (+ sc0 (* tb 11.4)) raggedfreq)
                                                     (* (+ tc0 (* sb 7.2)) raggedfreq) 0.0))) 1.0))))
    (setvar ss (+ ss (* (* raggedamp 0.5)
                        (- (* 2.0 (noise (make-point (* (+ sc0 (* tb 5.15)) (* raggedfreq 2.0))
                                                     (* (+ tc0 (* sb 23.8)) (* raggedfreq 2.0)) 0.0))) 1.0))))
    (setvar tt (+ tt (* (* raggedamp 0.5)
                        (- (* 2.0 (noise (make-point (* (+ sc0 (* tb 11.4)) (* raggedfreq 2.0))
                                                     (* (+ tc0 (* sb 7.2)) (* raggedfreq 2.0)) 0.0))) 1.0))))

    ;; ── mortar / brick の塗り分け (filteredpulse → fuzz smoothstep) ──
    (setvar w (- (smoothstep (- MWF fz) (+ MWF fz) ss)
                 (smoothstep (- (- 1.0 MWF) fz) (+ (- 1.0 MWF) fz) ss)))
    (setvar h (- (smoothstep (- MHF fz) (+ MHF fz) tt)
                 (smoothstep (- (- 1.0 MHF) fz) (+ (- 1.0 MHF) fz) tt)))

    ;; ── レンガ毎の明度ばらつき (snoise(whichbrick+0.5)) ──
    (setvar bc (* brickcolor (+ 1.0 (* brickvary (- (* 2.0 (noise (+ wb 0.5))) 1.0)))))
    (setvar Ct (mix mortarcolor bc (* w h)))

    (setvar Oi Os)
    (setvar Ci (* Oi Ct (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))
)))

(compile-shader brick-shader)
(append-shader brick-shader)
