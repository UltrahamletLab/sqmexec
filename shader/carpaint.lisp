;;; carpaint.lisp — メタリック・カーペイント (フレーク + クリアコート)
;;;
;;; 2層モデル:
;;;   - ベース: 金属パール色の拡散 + メタリックフレークの煌めき
;;;       フレーク = 高周波ノイズの疎な輝点。specular に同期させ、ライト方向で煌めく
;;;   - クリアコート: fresnel 反射層。trace で環境(空ドーム/他オブジェ)を映す
;;;       正面=弱反射、かすめ角=強反射。直った 1 バウンス反射エンジンの実演
;;;
;;; ※ scene 側の ks は低めに (ネイティブ反射との二重加算を避ける)
;;;
;;; パラメータ定義順 (shade_dr.c の carpaint_params[] と一致必須, 最大16):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 flake-color=4 flake-scale=5 flake-sharp=6
;;;   flake-amt=7 clearcoat=8 coat-bias=9 coat-power=10 spec-color=11

(setq carpaint-shader
(make-shader carpaint :keyword :surface
  (((Ka float) 0.10) ((Kd float) 0.60) ((Ks float) 0.40) ((roughness float) 0.04)
   ((flake-color color) (make-color 0.9 0.92 1.0))   ; フレークの色 (淡い金属)
   ((flake-scale float) 26.0)   ; フレークの細かさ (大=細かい)
   ((flake-sharp float) 8.0)    ; 輝点の疎らさ (大=まばらで鋭い)
   ((flake-amt   float) 1.40)   ; フレーク煌めき強度
   ((clearcoat   float) 0.85)   ; クリアコート反射の強さ
   ((coat-bias   float) 0.04)   ; 正面の最小反射 (fresnel bias)
   ((coat-power  float) 5.0)    ; fresnel の鋭さ
   ((spec-color  color) (make-color 1.0 1.0 1.0)))  ; ハイライト色
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Ir point) (normalize (- I)))
    ((dir point) (make-point 0 1 0))
    ((fl float) 0) ((flake float) 0) ((fres float) 0) ((hit float) 0)
    ((base color) (make-color 0 0 0))
    ((spk color) (make-color 0 0 0))
    ((refl color) (make-color 0 0 0)))
  ;; --- ベース拡散 (パール金属色) ---
  (setvar base (* Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))
  ;; --- メタリックフレーク: 疎な高周波輝点を specular に同期 ---
  (setvar fl (noise (* flake-scale Pg)))
  (setvar flake (pow fl flake-sharp))
  (setvar spk (specular Nf Ir roughness))
  (setvar base (+ base (* flake-color flake-amt flake spk)))
  ;; --- クリアコート: fresnel 反射 (trace で環境を映す) ---
  (setvar fres (+ coat-bias (* (- 1 coat-bias) (pow (- 1 (clamp (dot Nf Ir) 0 1)) coat-power))))
  (setvar dir (reflect I Nf))
  (setvar refl (* clearcoat fres (trace P dir hit)))
  ;; --- 合成 ---
  (setvar Oi Os)
  (setvar Ci (* Oi (+ base refl (* Ks spec-color spk)))))))

(compile-shader carpaint-shader)
(append-shader carpaint-shader)
