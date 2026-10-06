;;; planks.lisp — 板目フローリング / 寄木板 (flatsawn hardwood floor)
;;;
;;; 既存 wood.lisp は「原点中心の同心円年輪 (木口/柾目)」の1993年古典。本シェーダーは
;;; 全く別物で、床/家具天板向けの *板目(flatsawn)* を狙う:
;;;   - 板割り: 世界X方向に plank-width 間隔で板を並べ、Z方向に plank-length で木口継ぎ
;;;   - カテドラル杢: 年輪は板長手(Z)に走る樹心(pith)からの距離リング。樹心の x位置/深さを
;;;     Zに沿って低周波ノイズで揺らす → リングが板上で入れ子アーチ(大聖堂杢)に湾曲する
;;;   - 板ごとの個性: 板index でランダムに明度・杢位相・樹心位置をずらし、全板を別木目に
;;;   - 導管streak: 長手に伸びた細かいノイズで縦の細い濃淡(早材/晩材の筋)
;;;   - 目地溝: 板間・木口継ぎを暗く落とし、法線バンプで彫り込む
;;;   - サテンニス: フレネルで縁が締まる薄い艶 (coat)
;;;
;;; パラメータ定義順 (shade_dr.c の planks_params[] と一致必須, 最大16):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 light-wood=4 dark-wood=5 ring-density=6
;;;   pith-depth=7 wander=8 plank-width=9 plank-length=10 seam-width=11
;;;   plank-vary=12 grain-streak=13 coat=14 bump=15

(setq planks-shader
(make-shader planks :keyword :surface
  (((Ka float) 0.30) ((Kd float) 0.72) ((Ks float) 0.40) ((roughness float) 0.04)
   ((light-wood color) (make-color 0.52 0.36 0.20))   ; 早材 (ハニーオーク)
   ((dark-wood  color) (make-color 0.20 0.11 0.05))   ; 晩材/導管の濃い筋
   ((ring-density float) 7.0)    ; 杢リングの密度
   ((pith-depth   float) 1.2)    ; 樹心の深さ (大=アーチが平たく広い)
   ((wander       float) 0.8)    ; 樹心の横揺れ量 (大聖堂杢の波打ち)
   ((plank-width  float) 1.6)    ; 板幅 (世界単位)
   ((plank-length float) 7.0)    ; 板長 (木口継ぎ間隔)
   ((seam-width   float) 0.05)   ; 目地溝の幅 (板内比率)
   ((plank-vary   float) 0.28)   ; 板ごとの明度ばらつき
   ((grain-streak float) 0.35)   ; 縦の導管streakの強さ
   ((coat         float) 0.55)   ; ニスの艶 (フレネル)
   ((bump         float) 0.5))   ; 杢/目地の法線バンプ量
  (enter (
    ((NN point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((Nb point) (make-point 0 1 0))
    ((px float) 0) ((pz float) 0)
    ((bu float) 0) ((bi float) 0) ((bf float) 0)
    ((brand float) 0) ((hue float) 1)
    ((gx float) 0) ((gz float) 0)
    ((pithx float) 0) ((pithd float) 1)
    ((rr float) 0) ((gg float) 0) ((db float) 0) ((dark float) 0)
    ((streak float) 0) ((tick float) 0)
    ((edge float) 0) ((lf float) 0) ((ledge float) 0)
    ((pmask float) 1) ((emask float) 1) ((groove float) 1)
    ((bx float) 0) ((bz float) 0) ((hx float) 0) ((hz float) 0)
    ((fres float) 0)
    ((woodcol color) (make-color 0 0 0)))
  ;; --- 板割り (X=板幅方向, Z=長手) ---
  (setvar px (xcomp Pg)) (setvar pz (zcomp Pg))
  (setvar bu (/ px plank-width))
  (setvar bi (floor bu))
  (setvar bf (- bu bi))                       ; 0..1 板内横位置
  ;; 板ごとの乱数 (明度/位相/樹心をずらす)
  (setvar brand (noise (make-point (* bi 1.7) 11.3 2.2)))
  (setvar hue (+ 1 (* plank-vary (- (* 2 brand) 1))))
  ;; 板内座標: 横は中心化, 長手は板ごとにオフセットして木目を相関させない
  (setvar gx (* (- bf 0.5) plank-width))
  (setvar gz (+ pz (* brand 9.0)))
  ;; --- カテドラル杢: 樹心(pith)をZに沿って揺らした距離リング ---
  (setvar pithx (* wander (- (noise (make-point (* gz 0.15) (* bi 5.0) 0.5)) 0.5) 2))
  (setvar pithd (+ pith-depth (* wander 0.6 (- (noise (make-point (* gz 0.15) (* bi 5.0) 9.0)) 0.5) 2)
                   (* brand 0.5)))
  (setvar rr (* ring-density (sqrt (+ (* (- gx pithx) (- gx pithx)) (* pithd pithd)))))
  ;; 杢の有機的な揺らぎ
  (setvar rr (+ rr (* 0.5 (turbulence (make-point (* gx 2.0) (* gz 0.5) 3.0) 2))))
  (setvar gg (- rr (floor rr)))               ; 0..1 リング内位相
  ;; 境界(gg→0/1)に細い暗線 = 年輪/導管
  (setvar db (- 0.5 (abs (- gg 0.5))))        ; 0=境界, 0.5=中央
  (setvar dark (- 1 (smoothstep 0 0.12 db)))  ; 境界付近=1(暗線)
  ;; --- 縦の導管streak (長手に伸びた細かいノイズ) ---
  (setvar streak (noise (make-point (* gx 26.0) (* gz 1.8) 5.0)))
  (setvar tick (* grain-streak (smoothstep 0.55 0.78 streak)))
  ;; --- 木材色: 早材(light)に暗線+streakで dark を載せ, 板ごと明度 ---
  (setvar woodcol (mix light-wood dark-wood (clamp (+ dark tick) 0 1)))
  (setvar woodcol (* woodcol hue))
  ;; --- 目地溝 (板間 + 木口継ぎ) ---
  (setvar edge (- 0.5 (abs (- bf 0.5))))
  (setvar pmask (smoothstep 0 seam-width edge))
  (setvar lf (- (/ gz plank-length) (floor (/ gz plank-length))))
  (setvar ledge (- 0.5 (abs (- lf 0.5))))
  (setvar emask (smoothstep 0 (* seam-width 0.6) ledge))
  (setvar groove (* pmask emask))
  (setvar woodcol (* woodcol (+ 0.22 (* 0.78 groove))))
  ;; --- バンプ: 杢の濃淡 + 目地溝を法線に彫る ---
  (setvar bx (* gx 8.0)) (setvar bz (* gz 1.2))
  (setvar hx (- (noise (make-point (+ bx 0.5) bz 7.0)) (noise (make-point (- bx 0.5) bz 7.0))))
  (setvar hz (- (noise (make-point bx (+ bz 0.5) 7.0)) (noise (make-point bx (- bz 0.5) 7.0))))
  ;; 目地溝の落ち込みも法線に反映 (溝の縁で傾ける)
  (setvar hx (+ hx (* 2.5 (- 1 pmask) (- bf 0.5))))
  (setvar Nb (normalize (make-point (- (xcomp NN) (* bump (+ hx (* 0.6 tick))))
                                    (ycomp NN)
                                    (- (zcomp NN) (* bump hz)))))
  ;; --- サテンニス (フレネルで縁が締まる艶) ---
  (setvar fres (pow (- 1 (clamp (dot Nb Ir) 0 1)) 3))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ (* woodcol (+ (* Ka (ambient)) (* Kd (diffuse Nb))))
                      (* coat (+ 0.3 (* 0.7 fres)) Ks (specular Nb Ir roughness))))))))

(compile-shader planks-shader)
(append-shader planks-shader)
