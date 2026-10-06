;;; aniso.lisp — 異方性ハイライト (Kajiya-Kay)。髪/ブラッシュド・メタル風の流れる筋ハイライト。
;;;
;;; 参考: Shadertoy の Kajiya-Kay ハイライト (HairRendering.pdf, J.Kajiya & T.Kay)。
;;;   - 接線場 T: 法線と「流れ方向 up-dir」から接平面へ射影 T = normalize(up - N(N·up))。
;;;     これが毛流れ/ブラシ目の向き。up-dir を変えると異方性の向きが変わる。
;;;   - 接線シフト: T を法線方向へ shift だけ傾ける (ハイライト帯を上下にずらす)。
;;;     aniso-jitter>0 でノイズを足すと毛束のばらつき。
;;;   - Kajiya-Kay: spec = step(0,N·L)·smoothstep(-1,0,T·H)·pow(sinTH, exponent)。
;;;     T·H から sinTH=√(1-(T·H)²) を作り、視線・光のハーフベクトル H に対する筋を出す。
;;;   - 元コード同様、筋は単一のキー光方向 light-dir に対して出す (シーン光に依らず安定)。
;;;     拡散ベースはエンジン (diffuse) でシーンの光に追従させ、両者を加算。
;;;
;;; パラメータ定義順 (shade_dr.c の aniso_params[] と一致必須):
;;;   Ka=0 Kd=1 Ks=2 roughness=3 spec-color=4 exponent=5 shift=6
;;;   light-dir=7 up-dir=8 aniso-jitter=9

(setq aniso-shader
(make-shader aniso :keyword :surface
  (((Ka float) 0.15) ((Kd float) 0.70) ((Ks float) 1.0) ((roughness float) 0.05)
   ((spec-color  color) (make-color 1.0 1.0 1.0))   ; ハイライト色 (金属/髪のツヤ色)
   ((exponent    float) 400.0)                       ; 筋の鋭さ (大=細く鋭い)
   ((shift       float) 0.0)                          ; 接線を法線方向へ傾ける量
   ((light-dir   point) (make-point 0.0 0.5 1.0))     ; 筋を出すキー光方向
   ((up-dir      point) (make-point 0.0 1.0 0.0))     ; 毛流れ/ブラシ目の向き (接線基準)
   ((aniso-jitter float) 0.0))                        ; 接線シフトのノイズ揺らぎ (毛束感)
  (enter (
    ((Nf point) (faceforward (normalize N) I))
    ((Vd point) (normalize (- I)))
    ((Ld point) (make-point 0 0 1))
    ((Hd point) (make-point 0 0 1))
    ((Traw point) (make-point 1 0 0))
    ((Tang point) (make-point 1 0 0))
    ((tlen float) 0) ((dotTH float) 0) ((sinTH float) 0) ((datt float) 0)
    ((nl float) 0) ((shiftv float) 0) ((jit float) 0) ((spec float) 0)
    ((bodyc color) (make-color 0 0 0))
    ((streak color) (make-color 0 0 0)))
  ;; --- key light + half vector ---
  (setvar Ld (normalize light-dir))
  (setvar Hd (normalize (+ Vd Ld)))
  ;; --- tangent field: up-dir projected onto the tangent plane (guard at poles) ---
  (setvar Traw (- up-dir (* Nf (dot Nf up-dir))))
  (setvar Tang (normalize (+ Traw (make-point 0.0001 0.0 0.0))))
  ;; --- shift tangent along normal (+ optional hair jitter) ---
  (setvar jit (* aniso-jitter (- (noise (* 6 Pg)) 0.5)))
  (setvar shiftv (+ shift jit))
  (setvar Tang (normalize (+ Tang (* shiftv Nf))))
  ;; --- Kajiya-Kay anisotropic highlight ---
  (setvar dotTH (dot Tang Hd))
  (setvar sinTH (sqrt (clamp (- 1 (* dotTH dotTH)) 0 1)))
  (setvar datt (smoothstep -1 0 dotTH))
  (setvar nl (dot Nf Ld))
  (setvar spec (* (step 0 nl) (* datt (pow sinTH exponent))))
  ;; --- assemble: engine diffuse base (scene lights) + anisotropic streak ---
  (setvar bodyc (* Cs (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))
  (setvar streak (* spec-color (* Ks spec)))
  (setvar Oi Os)
  (setvar Ci (* Oi (+ bodyc streak))))))

(compile-shader aniso-shader)
(append-shader aniso-shader)
