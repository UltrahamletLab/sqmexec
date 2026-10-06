;;; lensflare — スクリーン空間レンズフレア
;;;
;;; Converted from RenderMan SL lensflare.sl
;;; (c) 1990-2000 Exluna Inc. / Larry Gritz  -- original
;;; DynamicRender Lisp conversion: 2026
;;;
;;; カメラ正面のクアッド (s,t = スクリーンUV 0-1) に貼る。光源のスクリーン位置は
;;; light-s / light-t で与える (sqm には NDC 変換と光源位置の照会が無いため —
;;; 原典の illuminance+NDC 自動化は不採用)。
;;;
;;; 2026-08-09: BMRT 原典と比較し、優位点3つを**末尾追加 param の opt-in** で導入:
;;;   ・(param nspots 50)          — **seed 駆動のランダム斑点** (原典の目玉)。
;;;       位置/半径/種類 (disk/ring/blot/balloon 比率 = disky..bloony)/色ばらつきを
;;;       乱数列で決める。0 (既定) = 従来の固定ガウス6斑。
;;;       cellnoise 代替は黄金比撒き (noise(整数)=0.5 の罠を回避)。
;;;   ・(param rainbow-spline 1)   — 虹を V→I→B→G→Y→O→R のスペクトル帯に
;;;       (原典の spline を区分線形 mix で)。0 (既定) = 従来の多項式 RGB。
;;;   ・(param starburst-npoints 100) — スターを角度ノイズの多本レイに (原典の
;;;       pnoise(angle) を「単位円上の noise」で継ぎ目なく近似)。0 (既定) = 従来の
;;;       解析8本スター。
;;;   既定値では**従来と同じ絵** (compose の加算順の変更のみ — lensflare_test で確認)。
;;;
;;; パラメータ定義順 (shade_dr.cpp lensflare_params[] と一致必須):
;;;   0..11 = 従来 (intensity light-s light-t bloom-* starburst-intensity rainbow-* spot-intensity)
;;;   12=nspots 13=disky 14=ringy 15=blotty 16=bloony 17=spot-vary-color 18=seed
;;;   19=rainbow-spline 20=starburst-npoints 21=starburst-radius

(setq lensflare-shader

(make-shader lensflare :keyword :surface
  (((intensity           float)  1.0)
   ((light-s             float)  0.7)
   ((light-t             float)  0.7)
   ((bloom-intensity     float)  1.0)
   ((bloom-radius        float)  0.20)
   ((bloom-falloff       float)  5.0)
   ((bloom-starry        float)  0.55)
   ((starburst-intensity float)  0.45)
   ((rainbow-intensity   float)  0.65)
   ((rainbow-radius      float)  0.28)
   ((rainbow-width       float)  0.04)
   ((spot-intensity      float)  0.35)
   ;; ── 2026-08-09 末尾追加 (既定 = 従来の絵) ──
   ((nspots              float)  0.0)    ; >0 でランダム斑点 (原典 50)
   ((disky               float)  3.0)    ; 斑点タイプの比率: 平円盤
   ((ringy               float)  1.0)    ;   リング
   ((blotty              float)  1.0)    ;   柔斑
   ((bloony              float)  1.0)    ;   中抜き斑
   ((spot-vary-color     float)  0.5)    ; 斑点の色ばらつき
   ((seed                float)  143.0)  ; 乱数種 (原典既定)
   ((rainbow-spline      float)  0.0)    ; 1 でスペクトル帯の虹
   ((starburst-npoints   float)  0.0)    ; >0 で角度ノイズの多本スター (原典 100)
   ((starburst-radius    float)  0.5))   ; 多本スターの半径

  (enter (
    ;; screen-space coords centered at 0
    ((ss   float) (- s 0.5))
    ((tt   float) (- t 0.5))
    ((ls   float) (- light-s 0.5))
    ((lt   float) (- light-t 0.5))
    ((dx   float) (- ss ls))
    ((dy   float) (- tt lt))
    ((dist float) (sqrt (+ (* dx dx) (* dy dy))))

    ;; safe normalized direction (add epsilon to avoid /0)
    ((safe-dist float) (+ dist 0.0001))
    ((nx   float) (/ dx safe-dist))
    ((ny   float) (/ dy safe-dist))

    ;; --- BLOOM: smoothstep radial glow with noise star shape ---
    ((bn1  float) (noise (make-point (* 8.0 nx) (* 8.0 ny) 0.0)))
    ((bn2  float) (noise (make-point (* 8.0 nx) (* 8.0 ny) 1.0)))
    ((bshape float) (+ (- 1.0 bloom-starry) (* bloom-starry (* 0.5 (+ bn1 bn2)))))
    ((br    float) (* bloom-radius bshape))
    ((br-s  float) (+ br 0.001))
    ((bloom float) (* bloom-intensity
                      (pow (- 1.0 (smoothstep 0.0 br-s dist))
                           bloom-falloff)))

    ;; --- STARBURST (従来): 8-pointed star / 解析パターン ---
    ((star-cross float) (abs (* nx ny)))
    ((star-diag  float) (abs (- (* nx nx) (* ny ny))))
    ((star-ray   float) (+ star-cross star-diag))
    ((sfade      float) (- 1.0 (smoothstep 0.0 starburst-intensity dist)))
    ((starburst  float) (* starburst-intensity star-ray
                           (* sfade sfade sfade)))

    ;; --- RAINBOW (従来): Gaussian ring + 多項式 hue ---
    ((ring-d  float) (- dist rainbow-radius))
    ((ring-g  float) (exp (* -0.5 (/ (* ring-d ring-d)
                                     (* rainbow-width rainbow-width)))))
    ((nx2      float) (* nx nx))
    ((nx-neg2  float) (* (- nx) (- nx)))
    ((nx-center float) (- 1.0 nx2))
    ((hue-r   float) (* nx2 (+ nx 1.0) 0.5))
    ((hue-g   float) (* nx-center nx-center))
    ((hue-b   float) (* nx-neg2 (- 1.0 nx) 0.5))
    ((rbow-r  float) (* rainbow-intensity ring-g hue-r))
    ((rbow-g  float) (* rainbow-intensity ring-g hue-g))
    ((rbow-b  float) (* rainbow-intensity ring-g hue-b))

    ;; --- AXIS SPOTS (従来): 固定ガウス6斑 ---
    ((al    float) (sqrt (+ (* ls ls) (* lt lt))))
    ((sal   float) (+ al 0.0001))
    ((ax    float) (/ (* -1.0 ls) sal))
    ((ay    float) (/ (* -1.0 lt) sal))
    ((proj  float) (+ (* ss ax) (* tt ay)))
    ((pp2   float) (- (+ (* ss ss) (* tt tt)) (* proj proj)))
    ((g1 float) (* spot-intensity (exp (* -80.0 (+ (* (- proj -1.4) (- proj -1.4)) (* 8.0 pp2))))))
    ((g2 float) (* spot-intensity (exp (* -60.0 (+ (* (- proj -0.8) (- proj -0.8)) (* 8.0 pp2))))))
    ((g3 float) (* spot-intensity (exp (* -90.0 (+ (* (- proj -0.2) (- proj -0.2)) (* 8.0 pp2))))))
    ((g4 float) (* spot-intensity (exp (* -70.0 (+ (* (- proj  0.5) (- proj  0.5)) (* 8.0 pp2))))))
    ((g5 float) (* spot-intensity (exp (* -85.0 (+ (* (- proj  1.1) (- proj  1.1)) (* 8.0 pp2))))))
    ((g6 float) (* spot-intensity (exp (* -65.0 (+ (* (- proj  1.7) (- proj  1.7)) (* 8.0 pp2))))))
    ((spots float) (+ g1 (+ g2 (+ g3 (+ g4 (+ g5 g6))))))

    ;; --- 新パス用の作業変数 (既定パスでは未使用) ---
    ((sr float) 0.0) ((sg float) 0.0) ((sb float) 0.0)
    ((j float) 0.0) ((k0 float) 0.0)
    ((u1 float) 0.0) ((u2 float) 0.0) ((u3 float) 0.0)
    ((ax2 float) 0.0) ((ay2 float) 0.0)
    ((cx float) 0.0) ((cy float) 0.0)
    ((axd float) 0.0) ((rad float) 0.0) ((r2 float) 0.0)
    ((brt float) 0.0) ((ityp float) 0.0) ((w float) 0.0)
    ((cr float) 0.0) ((cg float) 0.0) ((cb float) 0.0)
    ((alltypes float) 0.0) ((fzz float) 0.004)
    ((xx float) 0.0) ((gate float) 0.0)
    ((spc color) (make-color 0 0 0))
    ((base float) 0.0)
    ((fr float) 0.0) ((fg float) 0.0) ((fb float) 0.0)
    ((fmax1 float) 0.0) ((fmax float) 0.0) ((aval float) 0.0))

    ;; ══ STARBURST 差し替え (starburst-npoints > 0): 角度ノイズの多本レイ ══
    ;; 原典の pnoise(npoints·angle/2π, npoints) を「単位円上の noise」で近似
    ;; (半径 npoints/2π の円周上を歩く = 周回で連続・継ぎ目なし)。
    (if (> starburst-npoints 0.5)
        (progn
          (setvar w (* starburst-npoints 0.159154943))
          (setvar u1 (noise (make-point (* nx w) (* ny w) 3.3)))
          (setvar rad (* starburst-radius u1))
          (setvar starburst (* starburst-intensity
                               (pow (- 1.0 (smoothstep 0.0 (max rad 0.001) dist)) 3.0)))))

    ;; ══ RAINBOW 差し替え (rainbow-spline > 0): V→I→B→G→Y→O→R のスペクトル帯 ══
    (if (> rainbow-spline 0.5)
        (progn
          (setvar xx (/ (- (/ dist rainbow-radius) 1.0) rainbow-width))
          ;; 区分線形 spline: V, I, B, G, Y, O, R (原典の spline を mix 連鎖で)
          (setvar spc (make-color 0.5 0.0 0.5))                                   ; V
          (setvar spc (mix spc (make-color 0.375 0.0 0.75) (clamp (* xx 6.0) 0.0 1.0)))          ; I
          (setvar spc (mix spc (make-color 0.0 0.0 1.0) (clamp (* (- xx 0.16667) 6.0) 0.0 1.0))) ; B
          (setvar spc (mix spc (make-color 0.0 1.0 0.0) (clamp (* (- xx 0.33333) 6.0) 0.0 1.0))) ; G
          (setvar spc (mix spc (make-color 1.0 1.0 0.0) (clamp (* (- xx 0.5) 6.0) 0.0 1.0)))     ; Y
          (setvar spc (mix spc (make-color 1.0 0.5 0.0) (clamp (* (- xx 0.66667) 6.0) 0.0 1.0))) ; O
          (setvar spc (mix spc (make-color 1.0 0.0 0.0) (clamp (* (- xx 0.83333) 6.0) 0.0 1.0))) ; R
          (setvar gate (* (smoothstep -0.02 0.0 xx) (- 1.0 (smoothstep 1.0 1.02 xx))))
          (setvar rbow-r (* rainbow-intensity gate (comp spc 0)))
          (setvar rbow-g (* rainbow-intensity gate (comp spc 1)))
          (setvar rbow-b (* rainbow-intensity gate (comp spc 2)))))

    ;; ══ SPOTS: nspots>0 で原典の seed 駆動ランダム斑点 / 0 で従来ガウス6斑 ══
    (if (< nspots 0.5)
        (progn
          (setvar sr spots)
          (setvar sg (* 0.8 spots))
          (setvar sb (* 0.5 spots)))
        (progn
          ;; 軸 = 画面中心→光源 (原典 normalize(Plight))
          (setvar ax2 (/ ls sal))
          (setvar ay2 (/ lt sal))
          (setvar alltypes (+ disky (+ ringy (+ blotty bloony))))
          (setvar sr 0.0) (setvar sg 0.0) (setvar sb 0.0)
          (repeat (j nspots)
            ;; 乱数列 (原典の nrand 簿記 20+3i を模倣。cellnoise 代替 = 黄金比撒き)
            (setvar k0 (+ 20.0 (* j 3.0)))
            (setvar u1 (noise (* (+ seed (+ k0 1.0)) 0.6180339887)))
            (setvar u2 (noise (* (+ seed (+ k0 2.0)) 0.6180339887)))
            (setvar u3 (noise (* (+ seed (+ k0 3.0)) 0.6180339887)))
            ;; 斑点の中心 = 軸上 mix(-1.7, 1.7, u1)
            (setvar w (+ -1.7 (* 3.4 u1)))
            (setvar cx (* w ax2))
            (setvar cy (* w ay2))
            (setvar axd (sqrt (+ (* (- cx ss) (- cx ss)) (* (- cy tt) (- cy tt)))))
            ;; 半径 = mix(0.04, 0.1, u2²) × |中心−光源|
            (setvar rad (* (+ 0.04 (* 0.06 (* u2 u2)))
                           (sqrt (+ (* (- cx ls) (- cx ls)) (* (- cy lt) (- cy lt))))))
            (setvar brt (- 1.0 (* 2.0 rad)))
            (setvar brt (* brt brt))
            ;; 色ばらつき (原典 1 + varycolor·(cellnoise(i)−0.5))
            (setvar cr (+ 1.0 (* spot-vary-color (- (noise (* (+ j 11.1) 0.6180339887)) 0.5))))
            (setvar cg (+ 1.0 (* spot-vary-color (- (noise (* (+ j 42.7) 0.6180339887)) 0.5))))
            (setvar cb (+ 1.0 (* spot-vary-color (- (noise (* (+ j 77.3) 0.6180339887)) 0.5))))
            ;; タイプ選択 (disk / ring / blot / balloon)
            (setvar ityp (* u3 alltypes))
            (if (< ityp disky)
                (setvar w (- 1.0 (smoothstep (- rad fzz) (+ rad fzz) axd)))
                (if (< ityp (+ disky ringy))
                    (progn
                      (setvar r2 (+ rad (* 0.05 axd)))
                      (setvar w (- (smoothstep (- rad fzz) (+ rad fzz) axd)
                                   (smoothstep (- r2 fzz) (+ r2 fzz) axd))))
                    (if (< ityp (+ disky (+ ringy blotty)))
                        (setvar w (- 1.0 (smoothstep 0.0 rad axd)))
                        (setvar w (- (smoothstep 0.0 rad axd)
                                     (smoothstep (- rad fzz) (+ rad fzz) axd))))))
            (setvar w (* w (* spot-intensity brt)))
            (setvar sr (+ sr (* w cr)))
            (setvar sg (+ sg (* w cg)))
            (setvar sb (+ sb (* w cb))))))

    ;; ══ COMPOSE (従来と同値。nspots=0 なら sr/sg/sb = 従来の spots×(1,0.8,0.5)) ══
    (setvar base (+ bloom starburst))
    (setvar fr (* intensity (+ base (+ rbow-r sr))))
    (setvar fg (* intensity (+ (* 0.8 base) (+ rbow-g sg))))
    (setvar fb (* intensity (+ (* 0.5 base) (+ rbow-b sb))))
    (setvar fmax1 (* 0.5 (+ (+ fr fg) (abs (- fr fg)))))
    (setvar fmax  (* 0.5 (+ (+ fmax1 fb) (abs (- fmax1 fb)))))
    (setvar aval  (* 1.4 fmax))
    (setvar Oi (* Os aval))
    (setvar Ci (make-color fr fg fb)))))

(compile-shader lensflare-shader)
(append-shader lensflare-shader)
