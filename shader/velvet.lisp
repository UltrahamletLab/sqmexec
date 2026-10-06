;;; velvet.lisp — ベルベット / ベロア (毛羽立った布の逆フレネル・シーン)
;;;
;;; ベルベットの肝は「正面はマットに沈み、シルエット(かすめ角)ほど毛羽が光を捕えて
;;; 明るく光る」逆フレネル。通常のスペキュラとは逆の輝度分布になる。
;;;   - リムシーン: pow(1 - N·V, edge-power) を sheen-color で加算。これが布の縁光り
;;;   - シーンの光追従: シーンを (sheen-lit) で diffuse(Nf) と ambient フロアに混ぜ、
;;;     光の当たる側の縁ほど強く、影側でも ambient で淡く光らせる
;;;   - 織りノイズ(nap): 3Dノイズでシーン/本体を微変調し、毛並み/織り目のざらつきを出す
;;;   - 本体の沈み(body-dark): 正面(N·V大)ほど拡散を僅かに落として velvet の深いマット感
;;;   - 裏散乱(backscatter): 反転法線拡散で薄い部分や縁に回り込む柔らかい透け
;;;   - soft spec: 粗い roughness の広く柔らかいハイライト (布の鈍い艶)
;;;
;;; パラメータ定義順 (shade_dr.c の velvet_params[] と一致必須, 最大16):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 sheen-color=4 edge-power=5 sheen=6
;;;   backscatter=7 nap=8 nap-scale=9 body-dark=10 sheen-lit=11

(setq velvet-shader
(make-shader velvet :keyword :surface
  (((Ka float) 0.20) ((Kd float) 0.38) ((Ks float) 0.15) ((roughness float) 0.30)
   ((sheen-color color) (make-color 0.85 0.55 0.65))  ; 縁光りの色 (ベース色の明るい縁)
   ((edge-power  float) 2.8)    ; フレネル指数 (大=細い縁, 小=広いグロー)
   ((sheen       float) 2.40)   ; リムシーンの強さ
   ((backscatter float) 0.20)   ; 反転法線の裏散乱量 (柔らかい透け)
   ((nap         float) 0.35)   ; 織り/毛並みノイズの量
   ((nap-scale   float) 8.0)    ; 織りノイズのスケール (大=細かい目)
   ((body-dark   float) 0.50)   ; 正面の沈み (大=本体が深く沈む)
   ((sheen-lit   float) 0.50))  ; リムの光追従度 (1=光側のみ, 0=全周一様)
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((facing float) 0) ((fres float) 0) ((rim float) 0)
    ((nz float) 0) ((napf float) 1)
    ((ld color) (make-color 0 0 0))
    ((litrim color) (make-color 0 0 0))
    ((body color) (make-color 0 0 0))
    ((back color) (make-color 0 0 0))
    ((sheenc color) (make-color 0 0 0))
    ((soft color) (make-color 0 0 0)))
  ;; --- 視線項: facing=正面で1, かすめ角で0 / fres=その逆 ---
  (setvar facing (clamp (dot Nf Ir) 0 1))
  (setvar fres (- 1 facing))
  (setvar rim (pow fres edge-power))
  ;; --- 織り/毛並みノイズ (中心化して全体輝度を保つ) ---
  (setvar nz (noise (* nap-scale Pg)))
  (setvar napf (+ 1 (* nap (- nz 0.5))))
  ;; --- 拡散と本体 (正面を body-dark で沈めて深いマット) ---
  (setvar ld (diffuse Nf))
  (setvar body (* Cs (+ (* Ka (ambient)) (* Kd ld napf (- 1 (* body-dark facing))))))
  ;; --- 裏散乱: 反転法線拡散で縁に回り込む柔らかい透け ---
  (setvar back (* backscatter Cs (diffuse (- Nf))))
  ;; --- リムシーン: 光追従(sheen-lit) + ambientフロア。布の縁光り ---
  (setvar litrim (+ (* sheen-lit ld) (* (- 1 sheen-lit) (ambient))))
  (setvar sheenc (* sheen-color sheen rim napf litrim))
  ;; --- 柔らかい広いハイライト (鈍い布の艶) ---
  (setvar soft (* Ks sheen-color (specular Nf Ir roughness)))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ body back sheenc soft))))))

(compile-shader velvet-shader)
(append-shader velvet-shader)
