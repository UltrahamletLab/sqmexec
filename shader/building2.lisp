;;; building2.lisp — よりリアルなビル外壁シェーダー
;;;
;;; 既存 building の窓グリッドを拡張し、以下でリアリティを上げる:
;;;   - 窓を PANES_X × PANES_Y のペインに分割する桟 (mullion)
;;;   - 消灯窓はガラスとして空/環境を反射 (trace) し、フレネルでかすめ角ほど強反射
;;;   - 点灯窓は窓ごとに明るさ・暖色がランダムに変化する発光する室内灯
;;;   - 壁面コンクリートに 3D noise で軽いムラ
;;;
;;; パラメータ定義順 (shade_dr.c の building2_params[] と一致必須, 最大16):
;;;   Kd=0 Ka=1 Ks=2 roughness=3 Kr=4 Cframe=5 Cglass=6 Clit=7
;;;   EMIT_GAIN=16 Clit2=17 COOL_FRAC=18 EMIT_VARY=19
;;;   COLS=8 ROWS=9 WFRAC=10 HFRAC=11 PANES_X=12 PANES_Y=13 MULLION=14 LIT_FRAC=15

(setq building2-shader
(make-shader building2 :keyword :surface
  (((Kd float) 0.70) ((Ka float) 0.30) ((Ks float) 0.30) ((roughness float) 0.06)
   ((Kr float) 0.45)
   ((Cframe color) (make-color 0.30 0.31 0.33))
   ((Cglass color) (make-color 0.10 0.16 0.22))
   ((Clit   color) (make-color 1.00 0.90 0.62))
   ((COLS     float) 2.5)
   ((ROWS     float) 1.4)
   ((WFRAC    float) 0.66)
   ((HFRAC    float) 0.62)
   ((PANES_X  float) 2)
   ((PANES_Y  float) 2)
   ((MULLION  float) 0.10)
   ((LIT_FRAC float) 0.45)
   ;; --- 室内灯の見え方 (2026-08-09 追加) ---
   ((EMIT_GAIN      float) 0.80)     ; 発光の上限 (旧は実質 1.0 で明るすぎた)
   ((Clit2     color) (make-color 0.62 0.78 1.00))  ; 寒色の室内灯 (蛍光灯/TV)
   ((COOL_FRAC float) 0.28)     ; 寒色の窓の割合
   ((EMIT_VARY float) 3.0))     ; 明るさのばらつきの指数 (大きいほど暗い窓が多い)
  (enter (
    ((NN point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((dir point) (reflect I (faceforward (normalize N) I)))
    ((Nx float) (abs (xcomp NN)))
    ((Ny float) (abs (ycomp NN)))
    ((Nz float) (abs (zcomp NN)))
    ((Px float) (xcomp Pg)) ((Py float) (ycomp Pg)) ((Pz float) (zcomp Pg))
    ((is_top float) (step 0.7 Ny))
    ((bxz float) (step Nz Nx))
    ((ss float) 0) ((tt float) 0) ((sc float) 0) ((tc float) 0)
    ((sw float) 0) ((sh float) 0) ((in_win float) 0)
    ((uu float) 0) ((vv float) 0) ((fu float) 0) ((fv float) 0)
    ((vdiv float) 0) ((hdiv float) 0) ((mun float) 0)
    ((glass_mask float) 0) ((mun_mask float) 0)
    ((hashA float) 0) ((hashB float) 0) ((hashC float) 0)
    ((lit float) 0) ((bright float) 0) ((cool float) 0)
    ((lcol color) (make-color 0 0 0))
    ((fres float) 0) ((refl_amt float) 0) ((nzc float) 0)
    ((wall color) (make-color 0 0 0))
    ((win_surf color) (make-color 0 0 0))
    ((emit color) (make-color 0 0 0))
    ((refl color) (make-color 0 0 0))
    ((Ct color) (make-color 0 0 0))
    ((hitp float) 0))
  ;; --- 外壁への水平/垂直投影 (X面=Pz, Z面=Px / 縦=Py) ---
  (setvar ss (* COLS (+ (* bxz Pz) (* (- 1 bxz) Px))))
  (setvar tt (* ROWS Py))
  (setvar sc (floor ss)) (setvar tc (floor tt))
  (setvar ss (- ss sc)) (setvar tt (- tt tc))
  ;; --- 窓矩形マスク (セル内 WFRAC×HFRAC) ---
  (setvar sw (- (step (* 0.5 (- 1 WFRAC)) ss) (step (* 0.5 (+ 1 WFRAC)) ss)))
  (setvar sh (- (step (* 0.5 (- 1 HFRAC)) tt) (step (* 0.5 (+ 1 HFRAC)) tt)))
  (setvar in_win (* sw sh (- 1 is_top)))
  ;; --- 窓内のペイン座標と桟 (mullion) マスク ---
  (setvar uu (/ (- ss (* 0.5 (- 1 WFRAC))) WFRAC))
  (setvar vv (/ (- tt (* 0.5 (- 1 HFRAC))) HFRAC))
  (setvar fu (mod (* uu PANES_X) 1.0))
  (setvar fv (mod (* vv PANES_Y) 1.0))
  (setvar vdiv (+ (- 1 (step MULLION fu)) (step (- 1 MULLION) fu)))
  (setvar hdiv (+ (- 1 (step MULLION fv)) (step (- 1 MULLION) fv)))
  (setvar mun (clamp (+ vdiv hdiv) 0 1))
  (setvar glass_mask (* in_win (- 1 mun)))
  (setvar mun_mask   (* in_win mun))
  ;; --- 窓ごとの点灯/明るさ (擬似乱数) ---
  ;; ⚠ mod は fmod なので sc/tc が負だとハッシュが負になり、直後の step が
  ;;   一律 0 = **座標が負の側は点灯窓が1つも出ない** (2026-08-09 修正)。
  ;;   frac(x)=x-floor(x) は常に [0,1)。
  (setvar hashA (+ (* sc 0.754) (+ (* tc 0.569) 0.5)))
  (setvar hashA (- hashA (floor hashA)))
  (setvar hashB (+ (* sc 0.311) (+ (* tc 0.917) 0.137)))
  (setvar hashB (- hashB (floor hashB)))
  (setvar lit (step (- 1 LIT_FRAC) hashA))
  (setvar hashC (+ (* sc 0.487) (+ (* tc 0.233) 0.615)))
  (setvar hashC (- hashC (floor hashC)))
  ;; 明るさ: **線形に振ると全部同じに見える** — トーンマップ後の可視差が
  ;; 上端で潰れるため。指数で「大半は暗く一部だけ明るい」分布にする。
  (setvar bright (* EMIT_GAIN (+ 0.05 (* 0.95 (pow hashB EMIT_VARY)))))
  ;; 色: 白熱 (暖) と 蛍光灯/TV (寒) が混ざるのが実際の夜景
  (setvar cool (step (- 1 COOL_FRAC) hashC))
  (setvar lcol (mix Clit Clit2 cool))
  ;; --- 色を組み立て ---
  (setvar nzc (noise (* 8.0 Pg)))
  (setvar wall (* Cframe (+ 0.80 (* 0.4 nzc))))           ; コンクリのムラ
  (setvar win_surf (mix Cglass (* lcol 0.12) lit))        ; 点灯窓のガラス地は光の色に
  (setvar emit (* lcol (* bright lit)))                   ; 室内灯 (発光)
  (setvar fres (- 1 (dot NN Ir)))
  (setvar refl_amt (* Kr (* (+ 0.25 (* 0.75 fres)) (- 1 lit)))) ; 消灯窓のみ反射
  (setvar Ct wall)
  (setvar Ct (mix Ct (* Cframe 0.5) mun_mask))            ; 桟は暗いフレーム色
  (setvar Ct (mix Ct win_surf glass_mask))               ; 窓ガラス面
  ;; --- 反射トレース ---
  (setvar refl (trace P dir hitp))
  ;; --- シェーディング合成 (反射と室内灯はガラス部のみ加算) ---
  (setvar Oi Os)
  (setvar Ci (* Oi (+ (+ (* Ct (+ (* Ka (ambient)) (* Kd (diffuse NN))))
                         (* Ks (specular NN Ir roughness)))
                      (+ (* refl (* refl_amt glass_mask))
                         (* emit glass_mask)))))
)))

(compile-shader building2-shader)
(append-shader building2-shader)
