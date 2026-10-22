;;; rainbowsky.lisp — 虹つき天空ドームシェーダー (2026-08-14)
;;;
;;; fakesky2 と同じくシーンを囲む大球の内側に貼り、N を空方向として扱う。
;;; そこへ **幾何学的に正しい位置の虹** を加算する。
;;;
;;; 虹は「太陽の反対側 (対日点)」を中心とする円。視線と対日点のなす角 theta で決まり、
;;; 波長ごとに戻ってくる角度が違うので色が分かれる:
;;;   - 主虹   40.7°(紫) .. 42.4°(赤)          — 外側が赤
;;;   - 副虹   50.4°(赤) .. 53.4°(紫)          — **色順が逆**、明るさは主虹の 0.43 倍
;;;   - その間 42.4°..50.4° は Alexander の暗帯 (この角度には光が戻れない)
;;; 比率 0.43 と各角度は物理定数なので param にしない (作画の自由度ではない)。
;;;
;;; ⚠ 太陽が高いと対日点が地平の深くに沈み、虹は地平線下に隠れて見えなくなる。
;;;   弧を見せたいなら **sundir は低く** (仰角 10° 前後) し、カメラは太陽と反対を向くこと。
;;;   実際、虹が空に出る高さは「42° − 太陽高度」なので、太陽高度が 42° を超えると
;;;   地平線上には一切出ない。
;;;
;;; パラメータ定義順 (shade_dr.cpp の rainbowsky_params[] と一致必須, 最大16):
;;;   up=0 sundir=1 zenith-color=2 horizon-color=3 sun-color=4 cloud-color=5
;;;   sun-size=6 sun-glow=7 cloud-cover=8 cloud-sharp=9 cloud-scale=10
;;;   horizon-falloff=11 exposure=12 cloud-horizon=13 bow-intensity=14 bow-width=15

(setq rainbowsky-shader
(make-shader rainbowsky :keyword :surface
  (((up            point) (make-point 0 1 0))
   ((sundir        point) (make-point 0 0.17 1))
   ((zenith-color  color) (make-color 0.16 0.33 0.72))
   ((horizon-color color) (make-color 0.80 0.86 0.95))
   ((sun-color     color) (make-color 1.00 0.95 0.80))
   ((cloud-color   color) (make-color 1.00 1.00 1.00))
   ((sun-size        float) 1200.0)
   ((sun-glow        float) 6.0)
   ((cloud-cover     float) 0.50)
   ((cloud-sharp     float) 0.20)
   ((cloud-scale     float) 1.40)
   ((horizon-falloff float) 0.45)
   ((exposure        float) 1.10)
   ((cloud-horizon   float) 0.28)
   ((bow-intensity   float) 0.55)    ; 虹全体の濃さ (0 で虹なし=fakesky2 相当)
   ((bow-width       float) 0.35))   ; 帯の縁のぼけ幅 [度]。大きいほど淡く滲む
  (enter (
    ((dir point) (normalize N))
    ((sd  point) (normalize sundir))
    ((alt float) 0) ((altc float) 0) ((gfac float) 0)
    ((mu float) 0) ((sundisk float) 0) ((glow float) 0)
    ((cy float) 0) ((cx float) 0) ((cz float) 0)
    ((fbm float) 0) ((thr float) 0) ((density float) 0) ((hfade float) 0)
    ((cosd float) 0) ((theta float) 0)
    ((t1 float) 0) ((t2 float) 0) ((tt float) 0)
    ((env1 float) 0) ((env2 float) 0) ((env float) 0)
    ((dark float) 0) ((bowfade float) 0)
    ((cp  point) (make-point 0 0 0))
    ((sky color) (make-color 0 0 0))
    ((bowcol color) (make-color 0 0 0))
    ((cloudcol color) (make-color 0 0 0))
    ((col color) (make-color 0 0 0)))
  ;; --- 高度 (地平=0, 天頂=1) ---
  (setvar alt (dot up dir))
  (setvar altc (* 0.5 (+ alt (abs alt))))            ; max(0, alt)
  ;; --- 空のグラデーション ---
  (setvar gfac (pow (clamp altc 0 1) horizon-falloff))
  (setvar sky (mix horizon-color zenith-color gfac))
  ;; --- 太陽ディスク + グロー ---
  (setvar mu (clamp (dot dir sd) 0 1))
  (setvar sundisk (pow mu sun-size))
  (setvar glow (pow mu sun-glow))
  (setvar sky (+ sky (* sun-color (+ sundisk (* 0.5 glow)))))

  ;; ── 虹の角度 ────────────────────────────────────────────────
  ;;   対日点は -sd 方向。cos(theta) = dot(dir, -sd) = -dot(dir, sd)
  (setvar cosd (clamp (- 0 (dot dir sd)) -1 1))
  (setvar theta (degrees (acos cosd)))

  ;; --- Alexander の暗帯 (主虹と副虹の間は素の空より暗い) ---
  (setvar dark (* (smoothstep 42.4 44.2 theta)
                  (- 1 (smoothstep 48.6 50.4 theta))))
  (setvar sky (* sky (- 1 (* dark (* 0.12 bow-intensity)))))

  ;; --- 帯の中での波長位置 tt (0=赤, 1=紫) と 強度エンベロープ env ---
  (setvar t1 (clamp (/ (- 42.4 theta) 1.7) 0 1))     ; 主虹: 外(42.4)が赤
  (setvar t2 (clamp (/ (- theta 50.4) 3.0) 0 1))     ; 副虹: 内(50.4)が赤 = 逆順
  (setvar env1 (* (smoothstep (- 40.7 bow-width) (+ 40.7 (* 0.35 bow-width)) theta)
                  (- 1 (smoothstep (- 42.4 (* 0.35 bow-width)) (+ 42.4 bow-width) theta))))
  (setvar env2 (* (smoothstep (- 50.4 bow-width) (+ 50.4 (* 0.35 bow-width)) theta)
                  (- 1 (smoothstep (- 53.4 (* 0.35 bow-width)) (+ 53.4 bow-width) theta))))
  ;; 2本の帯は角度が重ならないので、46° を境に tt を選べばスペクトル評価は1回で済む。
  ;; ⚠ mix は (color color float) 専用でスカラー補間には使えない → 素の算術で書く。
  (setvar tt (+ t1 (* (- t2 t1) (step 46.0 theta))))
  (setvar env (+ env1 (* 0.43 env2)))                ; 副虹は主虹の 0.43 倍 (物理)

  ;; --- 波長 tt → 色 (赤→橙→黄→緑→空→青→紫 の順次 mix) ---
  (setvar bowcol (make-color 1.00 0.12 0.06))
  (setvar bowcol (mix bowcol (make-color 1.00 0.45 0.05) (smoothstep 0.00 0.18 tt)))
  (setvar bowcol (mix bowcol (make-color 1.00 0.92 0.10) (smoothstep 0.18 0.34 tt)))
  (setvar bowcol (mix bowcol (make-color 0.25 0.85 0.20) (smoothstep 0.34 0.52 tt)))
  (setvar bowcol (mix bowcol (make-color 0.10 0.65 0.92) (smoothstep 0.52 0.68 tt)))
  (setvar bowcol (mix bowcol (make-color 0.15 0.25 0.95) (smoothstep 0.68 0.84 tt)))
  (setvar bowcol (mix bowcol (make-color 0.48 0.10 0.80) (smoothstep 0.84 1.00 tt)))

  ;; --- フラクタル雲をドーム面へ遠近投影 ---
  (setvar cy (clamp altc 0.06 1))                    ; 地平でゼロ割回避
  (setvar cx (/ (* (xcomp dir) cloud-scale) cy))
  (setvar cz (/ (* (zcomp dir) cloud-scale) cy))
  (setvar cp (make-point cx cz 0))
  (setvar fbm (turbulence cp 6))
  (setvar thr (- 1 cloud-cover))
  (setvar density (smoothstep thr (+ thr cloud-sharp) fbm))
  (setvar hfade (smoothstep 0.05 cloud-horizon altc))
  (setvar density (* density hfade))
  (setvar cloudcol (mix (* cloud-color 0.55) cloud-color (smoothstep thr (+ thr 0.30) fbm)))
  (setvar cloudcol (* cloudcol (+ 0.65 (* 0.35 mu))))
  (setvar col (mix sky cloudcol density))

  ;; --- 虹を加算 (散乱光なので遮蔽ではなく加算) ---
  ;;   地平線下には雨のカーテンが無いのでフェード。雲の濃い所では減衰させる。
  (setvar bowfade (* (smoothstep -0.02 0.06 alt) (- 1 (* 0.85 density))))
  (setvar col (+ col (* bowcol (* env (* bow-intensity bowfade)))))

  (setvar col (* col exposure))
  (setvar Oi Os)
  (setvar Ci (* Oi col))
)))

(compile-shader rainbowsky-shader)
(append-shader rainbowsky-shader)
