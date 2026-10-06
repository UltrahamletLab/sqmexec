;;; storefront.lisp — ニューヨーク中低層の **1階 (店舗階)** シェーダー
;;;
;;; building2 が上層階の窓割りを担うのに対し、これは通りに面した1階を担当する。
;;; 街並みの表情は上層階の反復ではなく **1階の入り口のばらつき** が作る、という
;;; 観察に基づく。間口 (bay) ごとに擬似乱数で以下を引き分ける:
;;;
;;;   ショーウィンドウ … 大ガラス + 縦桟 + 上部の横桟。店内が点灯すると暖色が漏れる
;;;   入り口           … 引っ込んだ扉 + 上の欄間 (点灯するガラス)
;;;   シャッター       … 波板 (閉店した店)
;;;
;;; さらに全 bay 共通で 腰壁 (bulkhead) / 柱 (pier) / 看板帯 (signage band) の
;;; 3段構成を持ち、看板の色は bay ごとに振れる。
;;;
;;; building2 と同じく **s,t ではなくワールド座標 Pg と法線** で割るので、
;;; SDF にもメッシュにもそのまま貼れる (球面マッピングに落ちない)。
;;; 寸法はすべてメートルで指定する (BAY_W=間口, SIGN_Y=看板帯の下端 …)。
;;;
;;; パラメータ定義順 (shade_dr.cpp の storefront_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 Kr=4
;;;   Cpier=5 Cglass=6 Clit=7 Cshutter=8 Csign=9 Cdoor=10
;;;   BAY_W=11 BASE_H=12 SIGN_Y=13 TOP_Y=14 PIER=15 DOOR_W=16
;;;   PANES=17 MULL=18 LIT_FRAC=19 SHUT_FRAC=20 DOOR_FRAC=21 SIGN_VARY=22 RIBS=23
;;;   PHASE=24

(setq storefront-shader
(make-shader storefront :keyword :surface
  (((Ka float) 0.30) ((Kd float) 0.70) ((Ks float) 0.16) ((roughness float) 0.06)
   ((Kr float) 0.30)
   ((Cpier    color) (make-color 0.27 0.26 0.25))
   ((Cglass   color) (make-color 0.055 0.075 0.105))
   ((Clit     color) (make-color 1.00 0.84 0.55))
   ((Cshutter color) (make-color 0.21 0.22 0.23))
   ((Csign    color) (make-color 0.62 0.24 0.20))
   ((Cdoor    color) (make-color 0.115 0.10 0.09))
   ((BAY_W     float) 4.2)      ; 1店の間口 [m]
   ((BASE_H    float) 0.55)     ; 腰壁の高さ [m]
   ((SIGN_Y    float) 2.95)     ; 看板帯の下端 [m]
   ((TOP_Y     float) 3.60)     ; 店舗階の上端 [m] (これより上は素の壁)
   ((PIER      float) 0.10)     ; 柱の幅 (bay に対する片側の割合)
   ((DOOR_W    float) 0.34)     ; 扉の幅 (開口に対する割合)
   ((PANES     float) 3)        ; ショーウィンドウの縦桟の数
   ((MULL      float) 0.045)    ; 桟の太さ
   ((LIT_FRAC  float) 0.55)     ; 点灯している店の割合
   ((SHUT_FRAC float) 0.20)     ; シャッターが降りている割合
   ((DOOR_FRAC float) 0.28)     ; 入り口 bay の割合
   ((SIGN_VARY float) 0.75)     ; 看板の色の振れ幅
   ((RIBS      float) 13)       ; シャッターのリブ [本/m]
   ((PHASE     float) 0)        ; 乱数の位相 (建物ごとに変えて並びを崩す)
   ((ARCH_FRAC float) 0.30)     ; 開口の上がアーチになる bay の割合
   ((ARCH_H    float) 0.85)     ; アーチの起拱点から頂部までの高さ [m]
   ((ARCH_RING float) 1.55)     ; アーチ枠の太さ (aq 空間。1=開口の縁)
   ((WIDTH_VARY float) 0.45)    ; 間口の幅のばらつき (0=一定, <1)
   ((SIGN_H_VARY float) 0.55)   ; 看板帯の下端の振れ幅 [m] (庇の深い店/楣だけの店)
   ((EMIT_GAIN float) 0.85))    ; 店内灯の上限。**線形に振ると全部同じ明るさに見える**
                                ;  ので指数分布にしてある (building2 と同じ処置)
  (enter (
    ((NN point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((dir point) (reflect I (faceforward (normalize N) I)))
    ((Nx float) 0) ((Nz float) 0) ((bxz float) 0)
    ((hs float) 0) ((py float) 0)
    ((bb float) 0) ((bc float) 0) ((bu float) 0)
    ((hA float) 0) ((hB float) 0) ((hC float) 0) ((hD float) 0)
    ((is_shut float) 0) ((is_door float) 0) ((is_shop float) 0)
    ((in_base float) 0) ((in_mid float) 0) ((in_sign float) 0)
    ((prm float) 0) ((ou float) 0) ((tv float) 0) ((opening float) 0)
    ((dtop float) 0) ((in_dbody float) 0) ((in_tran float) 0)
    ((dmask float) 0) ((doorm float) 0) ((tranm float) 0) ((dfrm float) 0)
    ((fu float) 0) ((mln float) 0) ((hbar float) 0)
    ((glass float) 0) ((shut float) 0) ((glass_all float) 0)
    ((hE float) 0) ((hF float) 0) ((hG float) 0) ((is_arch float) 0)
    ((lcol color) (make-color 0 0 0))
    ((ccool color) (make-color 0.60 0.76 1.00))
    ((hw float) 0) ((sy float) 0)
    ((ouu float) 0) ((auu float) 0) ((d0 float) 0) ((d1 float) 0)
    ((ys float) 0) ((aq float) 0) ((bspr float) 0)
    ((shape float) 0) ((ap_rect float) 0) ((aperture float) 0) ((aring float) 0)
    ((rib float) 0) ((lit float) 0) ((bright float) 0)
    ((fres float) 0) ((ramt float) 0) ((nzc float) 0)
    ((Ct color)   (make-color 0 0 0))
    ((sgn color)  (make-color 0 0 0))
    ((emit color) (make-color 0 0 0))
    ((refl color) (make-color 0 0 0))
    ((hitp float) 0))

  ;; --- 外壁への水平投影 (X面=Pz, Z面=Px) と 高さ ---
  (setvar Nx (abs (xcomp NN)))
  (setvar Nz (abs (zcomp NN)))
  (setvar bxz (step Nz Nx))
  (setvar hs (+ (* bxz (zcomp Pg)) (* (- 1 bxz) (xcomp Pg))))
  (setvar py (ycomp Pg))

  ;; --- 間口の幅を bay ごとに振る ---
  ;; 単純な一様格子だと全店が同じ間口になる。**座標を単調に歪めてから floor** すると
  ;; セルの境界は順序を保ったまま間隔だけ変わる (stateless で不均等分割ができる)。
  ;; 単調性の条件は |dhw/dhs - 1| < 1 = 係数の総和 < 1 → WIDTH_VARY < 1 で保証。
  ;; 周期 2π/0.37≈17m と 2π/0.19≈33m の非整合な2波で、facade 上で反復して見えない。
  (setvar hw (+ hs (+ (* (/ (* 0.62 WIDTH_VARY) 0.37) (sin (* hs 0.37)))
                      (* (/ (* 0.38 WIDTH_VARY) 0.19) (sin (* hs 0.19))))))

  ;; --- 間口 (bay) 分割: bc = 何番目の店か / bu = その中の 0..1 ---
  (setvar bb (/ hw BAY_W))
  (setvar bc (floor bb))
  (setvar bu (- bb bc))

  ;; --- bay ごとの擬似乱数 6本 (種別・点灯・看板色・扉・アーチ・庇で別々に引く) ---
  ;; ⚠ **mod は使えない** — DSL の mod は fmod なので bc が負だと結果が負になり、
  ;;   直後の (step th h) が一律 0 になって **座標が負の側は全部ショーウィンドウ**に
  ;;   なる (通りの片側だけ扉もシャッターも出ない)。frac(x)=x-floor(x) を使う。
  (setvar hA (+ (* bc 0.7548) (+ 0.3187 PHASE)))
  (setvar hA (- hA (floor hA)))
  (setvar hB (+ (* bc 0.3113) (+ 0.7411 PHASE)))
  (setvar hB (- hB (floor hB)))
  (setvar hC (+ (* bc 0.5417) (+ 0.1234 PHASE)))
  (setvar hC (- hC (floor hC)))
  (setvar hD (+ (* bc 0.9271) (+ 0.6042 PHASE)))
  (setvar hD (- hD (floor hD)))
  (setvar hE (+ (* bc 0.1847) (+ 0.4519 PHASE)))
  (setvar hE (- hE (floor hE)))
  (setvar hF (+ (* bc 0.6293) (+ 0.2708 PHASE)))
  (setvar hF (- hF (floor hF)))
  (setvar hG (+ (* bc 0.4162) (+ 0.8371 PHASE)))
  (setvar hG (- hG (floor hG)))
  ;; 看板帯の下端を店ごとに下げる = 庇の深い店 / 楣だけの店 が混ざる
  (setvar sy (- SIGN_Y (* SIGN_H_VARY hF)))

  ;; --- 種別 (排他) ---
  (setvar is_shut (step (- 1 SHUT_FRAC) hA))
  (setvar is_door (* (- 1 is_shut) (step (- 1 DOOR_FRAC) hD)))
  (setvar is_shop (- 1 (+ is_shut is_door)))
  (setvar is_arch (step (- 1 ARCH_FRAC) hE))

  ;; --- 縦の3段: 腰壁 / 開口 / 看板帯 ---
  (setvar in_base (- 1 (step BASE_H py)))
  (setvar in_sign (* (step sy py) (- 1 (step TOP_Y py))))
  (setvar in_mid  (* (step BASE_H py) (- 1 (step sy py))))

  ;; --- 柱 pier (bay の両端) と 開口内の横位置 ou / 縦位置 tv ---
  (setvar prm (clamp (+ (- 1 (step PIER bu)) (step (- 1 PIER) bu)) 0 1))
  (setvar ou (clamp (/ (- bu PIER) (- 1 (* 2 PIER))) 0 1))
  (setvar tv (clamp (/ (- py BASE_H) (- sy BASE_H)) 0 1))
  (setvar opening (* in_mid (- 1 prm)))

  ;; --- 入り口: 扉本体 + その上の欄間 ---
  (setvar dtop (- sy 0.45))
  (setvar in_dbody (* (step BASE_H py) (- 1 (step dtop py))))
  (setvar in_tran  (* (step dtop py) (- 1 (step sy py))))
  (setvar dmask (- (step (- 0.5 (* 0.5 DOOR_W)) ou)
                   (step (+ 0.5 (* 0.5 DOOR_W)) ou)))
  ;; --- アーチ: アパーチャ (この bay で開いている矩形) の上端を半楕円で抜く ---
  ;;   shop/shutter は開口いっぱい / door は扉幅を基準にする。
  ;;   **クランプしない座標** (ouu/auu) で楕円式を評価する — クランプすると
  ;;   アパーチャの外がすべて aq=一定になり、枠が横に伸びてしまう。
  (setvar d0 (- 0.5 (* 0.5 DOOR_W)))
  (setvar d1 (+ 0.5 (* 0.5 DOOR_W)))
  (setvar ouu (/ (- bu PIER) (- 1 (* 2 PIER))))
  (setvar auu (+ ouu (* is_door (- (/ (- ouu d0) (- d1 d0)) ouu))))
  (setvar ys (- sy ARCH_H))
  (setvar aq (+ (* (* (- auu 0.5) 2) (* (- auu 0.5) 2))
                (* (/ (- py ys) ARCH_H) (/ (- py ys) ARCH_H))))
  (setvar bspr (- 1 (step ys py)))                    ; 起拱点より下
  (setvar shape (+ (* (- 1 is_arch) 1)
                   (* is_arch (clamp (+ bspr (- 1 (step 1.0 aq))) 0 1))))
  (setvar ap_rect (+ (- 1 prm) (* is_door (- (* (- 1 prm) dmask) (- 1 prm)))))
  (setvar aperture (* in_mid (* ap_rect shape)))
  ;; アーチ枠 (アーキボルト): 楕円の外側の細い帯
  (setvar aring (* is_arch (* (- 1 prm) (* in_mid (* (- 1 bspr)
                  (* (step 1.0 aq) (- 1 (step ARCH_RING aq))))))))

  (setvar doorm (* aperture (* is_door in_dbody)))
  (setvar tranm (* aperture (* is_door in_tran)))
  ;; 扉枠 (リビール): 扉+欄間より一回り広い帯から本体を抜いた輪郭。
  ;; これが無いと扉が「壁に貼った暗い矩形」に見える。
  (setvar dfrm (- (step (- 0.5 (* 0.5 (+ DOOR_W 0.12))) ou)
                  (step (+ 0.5 (* 0.5 (+ DOOR_W 0.12))) ou)))
  (setvar dfrm (* is_door (* (- 1 prm) (* dfrm in_mid))))
  (setvar dfrm (clamp (- dfrm (clamp (+ doorm tranm) 0 1)) 0 1))

  ;; --- ショーウィンドウの桟 (縦 PANES 本 + 上部の横桟) ---
  (setvar fu (mod (* ou PANES) 1.0))
  (setvar mln (clamp (+ (- 1 (step MULL fu)) (step (- 1 MULL) fu)) 0 1))
  (setvar hbar (* (- 1 is_arch) (- (step 0.80 tv) (step 0.87 tv))))
  (setvar mln (clamp (+ mln hbar) 0 1))
  (setvar glass (* aperture (* is_shop (- 1 mln))))

  ;; --- シャッター (波板) ---
  (setvar shut (* aperture is_shut))
  (setvar rib (+ 0.70 (* 0.30 (sin (* (* py RIBS) 6.28319)))))

  ;; --- 点灯 (シャッターの店は消灯) ---
  (setvar lit (* (step (- 1 LIT_FRAC) hB) (- 1 is_shut)))
  ;; 店内灯: 大半は控えめ・一部だけ明るい (線形だと全店が同じ明るさに見える)。
  ;; 色も 白熱(暖) と 蛍光灯(寒) を混ぜる — 実際の商店街は色温度がばらばら。
  (setvar bright (* EMIT_GAIN (+ 0.08 (* 0.92 (pow hC 2.6)))))
  (setvar lcol (mix Clit ccool (step 0.72 hG)))
  (setvar glass_all (clamp (+ glass tranm) 0 1))

  ;; --- 色を積む: 壁 → 腰壁 → 看板 → ガラス/扉/シャッター ---
  (setvar nzc (noise (* 6.0 Pg)))
  (setvar Ct (* Cpier (+ 0.82 (* 0.34 nzc))))
  (setvar Ct (mix Ct (* Cpier 0.52) in_base))
  ;; 看板は bay ごとに色を振る (通りの雑多さの主役)
  (setvar sgn (make-color (* (comp Csign 0) (+ (- 1 SIGN_VARY) (* SIGN_VARY (+ 0.35 hC))))
                          (* (comp Csign 1) (+ (- 1 SIGN_VARY) (* SIGN_VARY (+ 0.25 hA))))
                          (* (comp Csign 2) (+ (- 1 SIGN_VARY) (* SIGN_VARY (+ 0.25 hD))))))
  ;; 看板は店舗 (営業中/シャッター) のみ。入り口 bay は石の楣にする —
  ;; 集合住宅のエントランスに店の庇は付かない。
  (setvar Ct (mix Ct sgn (* in_sign (- 1 is_door))))
  (setvar Ct (mix Ct (* Cpier 0.88) (* in_sign is_door)))
  (setvar Ct (mix Ct (mix Cglass (* lcol 0.14) lit) glass))
  (setvar Ct (mix Ct (* Cpier 1.12) aring))
  (setvar Ct (mix Ct (* Cpier 0.42) dfrm))
  (setvar Ct (mix Ct Cdoor doorm))
  (setvar Ct (mix Ct (mix Cglass (* lcol 0.14) lit) tranm))
  (setvar Ct (mix Ct (* Cshutter rib) shut))

  ;; --- 反射と室内灯 (ガラス面のみ) ---
  (setvar fres (- 1 (dot NN Ir)))
  (setvar ramt (* Kr (+ 0.20 (* 0.80 fres))))
  (setvar refl (trace P dir hitp))
  (setvar emit (* lcol (* bright lit)))

  (setvar Oi Os)
  (setvar Ci (* Oi (+ (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse NN))))
                         (* Ks (specular NN Ir roughness)))
                      (+ (* refl (* ramt glass_all))
                         (* emit glass_all))))))))

(compile-shader storefront-shader)
(append-shader storefront-shader)
