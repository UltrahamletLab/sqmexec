;;; ceramictiles — 浴室のセラミックタイル (タイル+目地+斑+縁+斑点+タイル毎の色ばらつき)
;;;
;;; 移植元: BMRT ceramictiles.sl (+ patterns.h tilepattern/tiletexture/varyEach/
;;;         smoothpulse, locillum.h LocIllumGlossy, material.h MaterialCeramicTiles)
;;;   (c) Copyright 1990-2000 Exluna, Inc. and Larry Gritz.
;;;
;;; 構成 (原典どおり):
;;;   ① tilepattern: パルス列で「タイル内=1 / 目地=0」(intile) と、タイル内座標
;;;      (stile,ttile)・タイル番号 tileindex を得る
;;;   ② tiletexture: 斑 (fBm mix) + 縁の色 (ragged smoothpulse) + 斑点 (閾値化 noise)
;;;   ③ varyEach: タイル番号ハッシュで色相/彩度/明度をタイル毎に揺らす
;;;   ④ 目地はモルタル色 × 高周波 fBm
;;;   ⑤ 照明 = fkt*(Ka*ambient + kd*diffuse) + Ks*intile*LocIllumGlossy
;;;            + fkr*Kr*intile*trace   (fkr = Schlick フレネル)
;;;
;;; ── sqm 版の違い ────────────────────────────────────────────────
;;; ・ProjectTo2D/mx → **(transform "shader" Pg)** + axis 投影 (0=yz 1=zx 2=xy)。
;;;   タイルの向き/位相はシーンの (shader-space ..) で操作する (2026-08-09 新設の実戦初投入)。
;;;   spacing は**ワールド単位** (原典の st 空間 spacing 10 は写像不能)。
;;; ・filtered* 系 (filterwidth による帯域制限) は微分が無いので落とし、
;;;   パルス列の縁は固定 fuzz=0.02 (タイル比) の smoothstep。遠景は本番解像度で確認。
;;; ・cellnoise(整数) は sqm の noise だと**格子点で常に 0.5** になる → 黄金比
;;;   0.618.. を掛けて格子から外す (rnd(k) = noise((tileindex+k)*φ))。
;;; ・varyEach の HSL 変換は DSL に無い:
;;;     色相 = グレー軸まわりの Rodrigues 回転 (角 2π*varyhue*(rnd-0.5)) で等価品
;;;     彩度 = 輝度グレーへの mix / 明度 = スカラー倍 — HSL とは厳密一致しないが同じ意図
;;; ・目地の変位と「タイル毎の法線ジッタ」(原典 Displace/N摂動) は :surface では
;;;   N に書けないので落とした。**実変位は相棒の ceramictilesdisp** (:displacement) を
;;;   同じ spacing/groove で重ねる (brick ←→ brickbump と同じ対)。
;;; ・blur は落とした (既定 0 = 原典既定と同じ。要るときは pbrenv 代替 —
;;;   docs/2026-08-09_trace拡張_見送りと代替.md)。rayjitter/raysamples/env* も対象外。
;;;
;;; パラメータ定義順 (shade_dr.cpp の ceramictiles_params[] と一致必須):
;;;   Ka=0 Kdtile=1 Kdmortar=2 Ks=3 roughness=4 specsharpness=5 Kr=6 eta=7
;;;   mortar-color=8 stilespacing=9 ttilespacing=10 groovewidth=11 grooveheight=12
;;;   axis=13 edgevary=14 mottling=15 speckly=16 mottlefreq=17
;;;   Cbase=18 Cedge=19 Cmottle=20 Cspeck=21 varyhue=22 varysat=23 varylum=24

(setq ceramictiles-shader

(make-shader ceramictiles :keyword :surface
      (
       ((Ka            float) 1.0)
       ((Kdtile        float) 0.5)
       ((Kdmortar      float) 0.8)
       ((Ks            float) 0.75)
       ((roughness     float) 0.1)
       ((specsharpness float) 0.5)
       ((Kr            float) 1.0)     ; フレネル込みなので 1 でも控えめに映る
       ((eta           float) 1.5)
       ((mortar-color  color) (make-color 0.5 0.5 0.5))
       ((stilespacing  float) 1.0)     ; タイルピッチ (ワールド単位)
       ((ttilespacing  float) 1.0)
       ((groovewidth   float) 0.06)    ; 目地幅 (タイルピッチ比)
       ((grooveheight  float) 0.06)
       ((axis          float) 2.0)     ; 投影面 0=yz 1=zx 2=xy
       ((edgevary      float) 1.0)
       ((mottling      float) 1.0)
       ((speckly       float) 1.0)
       ((mottlefreq    float) 7.0)
       ((Cbase         color) (make-color 0.05 0.075 0.6))
       ((Cedge         color) (make-color 0.025 0.025 0.2))
       ((Cmottle       color) (make-color 0.2 0.2 0.7))
       ((Cspeck        color) (make-color 0.015 0.015 0.015))
       ((varyhue       float) 0.025)
       ((varysat       float) 0.4)
       ((varylum       float) 0.5)
       )

  (enter (((Nf   point) (faceforward (normalize N) I))
          ((Vd   point) (normalize (- I)))
          ((q    point) (make-point 0 0 0))
          ((su   float) 0.0) ((tv  float) 0.0)     ; タイル格子座標
          ((msu  float) 0.0) ((mtv float) 0.0)     ; パルス列の位相
          ((fz   float) 0.02)                       ; 縁の fuzz (タイル比)
          ((itile float) 0.0)                       ; 1=タイル / 0=目地
          ((stl  float) 0.0) ((ttl float) 0.0)     ; タイル内座標 [0,1]
          ((tdx  float) 0.0)                        ; タイル番号
          ((Ct   color) (make-color 1 1 1))
          ((pp   point) (make-point 0 0 0))
          ((famp float) 0.0) ((facc float) 0.0) ((j float) 0.0)
          ((so   float) 0.0) ((to2 float) 0.0) ((edgy float) 0.0)
          ((spk  float) 0.0)
          ((r1   float) 0.0) ((r2 float) 0.0) ((r3 float) 0.0)
          ((cp   point) (make-point 0 0 0))
          ((axv  point) (make-point 0.5773502692 0.5773502692 0.5773502692))
          ((th   float) 0.0) ((cth float) 0.0) ((sth float) 0.0)
          ((gry  float) 0.0)
          ((cmort color) (make-color 0.5 0.5 0.5))
          ((base  color) (make-color 0 0 0))
          ((kd    float) 0.0)
          ((cosv  float) 0.0) ((F0 float) 0.0) ((fkr float) 0.0)
          ((wg    float) 0.0) ((expo float) 0.0)
          ((nl    float) 0.0) ((g float) 0.0) ((nh float) 0.0)
          ((H     point) (make-point 0 0 1))
          ((spec  color) (make-color 0 0 0))
          ((krr   float) 0.0)
          ((rdir  point) (make-point 0 0 1))
          ((refl  color) (make-color 0 0 0))
          ((hitf  float) 0.0))

    ;; ── ① 座標: shader 空間 → axis 投影 → タイル格子 ──────────────
    (setvar q (transform "shader" Pg))
    (setvar su (xcomp q))
    (setvar tv (ycomp q))
    (if (< axis 0.5) (setvar su (zcomp q)))                       ; axis 0: (z, y)
    (if (and (> axis 0.5) (< axis 1.5)) (setvar tv (zcomp q)))    ; axis 1: (x, z)
    (setvar su (/ su stilespacing))
    (setvar tv (/ tv ttilespacing))

    ;; tilepattern: intile = パルス列2枚の積 (fuzz 付き)。mod は floor 基準で書く
    (setvar msu (+ su (* groovewidth 0.5)))
    (setvar msu (- msu (floor msu)))
    (setvar mtv (+ tv (* grooveheight 0.5)))
    (setvar mtv (- mtv (floor mtv)))
    (setvar itile (* (- (smoothstep groovewidth (+ groovewidth fz) msu)
                        (smoothstep (- 1.0 fz) 1.0 msu))
                     (- (smoothstep grooveheight (+ grooveheight fz) mtv)
                        (smoothstep (- 1.0 fz) 1.0 mtv))))
    (setvar stl (- su (floor su)))
    (setvar ttl (- tv (floor tv)))
    (setvar tdx (+ (floor su) (* 13.0 (floor tv))))

    ;; ── ② tiletexture ───────────────────────────────────────────
    (setvar Ct Cbase)
    ;; 斑: 4オクターブ符号つき fBm (lac 2, gain 0.65)
    (setvar pp (make-point (* stl mottlefreq) (* ttl mottlefreq) (* tdx 1.0)))
    (setvar famp 1.0)
    (setvar facc 0.0)
    (repeat (j 4)
      (setvar facc (+ facc (* famp (- (* 2.0 (noise pp)) 1.0))))
      (setvar famp (* famp 0.65))
      (setvar pp (* pp 2.0)))
    (setvar Ct (mix Ct Cmottle (clamp (* mottling (+ 0.2 (* 0.6 facc))) 0.0 1.0)))
    ;; 縁: ragged オフセット (2オクターブ fBm) + smoothpulse
    (setvar pp (make-point (* stl 10.0) (* ttl 10.0) (+ tdx 10.0)))
    (setvar so (* 0.05 (+ (- (* 2.0 (noise pp)) 1.0)
                          (* 0.5 (- (* 2.0 (noise (* pp 2.0))) 1.0)))))
    (setvar pp (make-point (* stl 10.0) (* ttl 10.0) (- tdx 3.0)))
    (setvar to2 (* 0.05 (+ (- (* 2.0 (noise pp)) 1.0)
                           (* 0.5 (- (* 2.0 (noise (* pp 2.0))) 1.0)))))
    (setvar edgy (- 1.0 (* (- (smoothstep 0.05 0.15 (+ stl so))
                              (smoothstep 0.85 0.95 (+ stl so)))
                           (- (smoothstep 0.05 0.15 (+ ttl to2))
                              (smoothstep 0.85 0.95 (+ ttl to2))))))
    (setvar Ct (mix Ct Cedge (clamp (* edgevary edgy) 0.0 1.0)))
    ;; 斑点: 閾値化 noise
    (setvar spk (smoothstep 0.55 0.7
                            (- (* 2.0 (noise (make-point (* stl 7.0) (* ttl 7.0)
                                                         (+ tdx 8.0)))) 1.0)))
    (setvar Ct (mix Ct Cspeck (clamp (* speckly spk) 0.0 1.0)))

    ;; ── ③ varyEach: タイル毎の色ばらつき ─────────────────────────
    ;; cellnoise 代替: 整数格子を黄金比で外す (整数入力の noise は常に 0.5 の罠)
    (setvar r1 (noise (* (+ tdx 3.0) 0.6180339887)))
    (setvar r2 (noise (* (- tdx 14.0) 0.6180339887)))
    (setvar r3 (noise (* (+ tdx 37.0) 0.6180339887)))
    ;; 色相: グレー軸まわりの Rodrigues 回転 (HSL の hue シフト等価品)
    (setvar th (* 6.283185307 (* varyhue (- r1 0.5))))
    (setvar cth (cos th))
    (setvar sth (sin th))
    (setvar cp (make-point (comp Ct 0) (comp Ct 1) (comp Ct 2)))
    (setvar cp (+ (* cp cth)
                  (+ (* (cross axv cp) sth)
                     (* axv (* (dot axv cp) (- 1.0 cth))))))
    ;; 彩度: 輝度グレーへ寄せる / 明度: スカラー倍
    (setvar gry (+ (* 0.299 (xcomp cp)) (+ (* 0.587 (ycomp cp)) (* 0.114 (zcomp cp)))))
    (setvar cp (+ (* (make-point 1 1 1) gry)
                  (* (- cp (* (make-point 1 1 1) gry))
                     (clamp (- 1.0 (* varysat (- r2 0.5))) 0.0 2.0))))
    (setvar cp (* cp (clamp (- 1.0 (* varylum (- r3 0.5))) 0.0 2.0)))
    (setvar Ct (make-color (clamp (xcomp cp) 0.0 1.0)
                           (clamp (ycomp cp) 0.0 1.0)
                           (clamp (zcomp cp) 0.0 1.0)))

    ;; ── ④ モルタル: 高周波 fBm (3オクターブ, gain 0.6) で汚す ─────────
    (setvar pp (make-point (* su 20.0) (* tv 20.0) 0.0))
    (setvar famp 1.0)
    (setvar facc 0.0)
    (repeat (j 3)
      (setvar facc (+ facc (* famp (- (* 2.0 (noise pp)) 1.0))))
      (setvar famp (* famp 0.6))
      (setvar pp (* pp 2.0)))
    (setvar cmort (* mortar-color
                     (smoothstep 0.0 1.0 (+ 0.5 (* 0.4 facc)))))

    ;; ── ⑤ 照明 (MaterialCeramicTiles) ───────────────────────────
    (setvar cosv (clamp (dot Nf Vd) 0.0 1.0))
    (setvar F0 (pow (/ (- eta 1.0) (+ eta 1.0)) 2.0))
    (setvar fkr (+ F0 (* (- 1.0 F0) (pow (- 1.0 cosv) 5.0))))
    (setvar base (mix cmort Ct itile))
    (setvar kd (+ Kdmortar (* (- Kdtile Kdmortar) itile)))
    (setvar Ci (* base (* (- 1.0 fkr)
                          (+ (* Ka (ambient)) (* kd (diffuse Nf))))))
    ;; LocIllumGlossy (閾値化ハイライト) — タイル部だけ
    (setvar wg (* 0.18 (- 1.0 specsharpness)))
    (setvar expo (/ 10.0 (max roughness 0.0001)))
    (setvar nl (lightcount))
    (repeat (j nl)
      (setvar g (lightsel j))
      (setvar H (normalize (+ (normalize L) Vd)))
      (setvar nh (max (dot Nf H) 0.0))
      (setvar spec (+ spec (* Cl (smoothstep (- 0.72 wg) (+ 0.72 wg)
                                             (pow nh expo))))))
    (setvar Ci (+ Ci (* spec (* Ks itile))))
    ;; フレネル反射 — タイル部だけ
    (setvar krr (* fkr (* Kr itile)))
    (if (> krr 0.001)
        (progn
          (setvar rdir (reflect I Nf))
          (setvar refl (trace P rdir hitf))
          (setvar Ci (+ Ci (* refl krr)))))

    (setvar Oi Os)
    (setvar Ci (* Oi Ci))
)))

(compile-shader ceramictiles-shader)
(append-shader ceramictiles-shader)
