;;; subsurface.lisp — サブサーフェス・スキャッタリング近似 (翡翠 / 蝋 / 肌)
;;;
;;; メタボールの丸い塊に半透明な「中まで光が透ける固体」質感を与える。
;;;   - 前面拡散: 通常の diffuse(Nf)
;;;   - 透過光(SSS近似): 法線を反転した diffuse(-Nf) で「裏から透けてくる光」を擬似
;;;     → 背後/横からのライトで縁や薄い部分がほんのり発光
;;;   - 内部密度ムラ(vein): 3Dノイズで透過量を局所変化させ、翡翠の斑/蝋のムラを出す
;;;   - フレネル sheen: かすめ角で柔らかいワックス的ハイライト
;;;
;;; パラメータ定義順 (shade_dr.c の subsurface_params[] と一致必須, 最大16):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 scatter-color=4 scatter=5 thickness=6
;;;   vein=7 vein-scale=8 rim=9

(setq subsurface-shader
(make-shader subsurface :keyword :surface
  (((Ka float) 0.18) ((Kd float) 0.55) ((Ks float) 0.45) ((roughness float) 0.05)
   ((scatter-color color) (make-color 0.55 0.85 0.45))  ; 透けてくる光の色 (翡翠=緑)
   ((scatter      float) 1.30)   ; 透過光の強さ
   ((thickness    float) 0.85)   ; 全体の透明度スケール (大=よく透ける)
   ((vein         float) 0.45)   ; 内部密度ムラの量
   ((vein-scale   float) 2.20)   ; ムラのノイズスケール
   ((rim          float) 0.60))  ; フレネル sheen の強さ
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((vn float) 0) ((dens float) 1)
    ((fres float) 0) ((sss float) 0)
    ((back color) (make-color 0 0 0))
    ((sheen color) (make-color 0 0 0))
    ((base color) (make-color 0 0 0)))
  ;; --- 内部密度ムラ: ノイズが低い所ほど薄く透ける ---
  (setvar vn (noise (* vein-scale Pg)))
  (setvar dens (- 1 (* vein vn)))
  ;; --- 透過光: 反転法線の拡散で裏からの光を擬似 ---
  (setvar back (diffuse (- Nf)))
  (setvar sss (* scatter thickness dens))
  ;; --- フレネル (縁ほど大) で柔らかい sheen ---
  (setvar fres (- 1 (clamp (dot Nf Ir) 0 1)))
  (setvar sheen (* scatter-color rim (pow fres 2.0)))
  ;; --- 前面拡散 + 環境 ---
  (setvar base (* Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))
  ;; --- 合成: 前面 + 透過(色つき) + sheen + ワックス的スペキュラ ---
  (setvar Oi Os)
  (setvar Ci (* Oi (+ base
                      (* scatter-color sss back)
                      sheen
                      (* Ks (specular Nf Ir roughness))))))))

(compile-shader subsurface-shader)
(append-shader subsurface-shader)
