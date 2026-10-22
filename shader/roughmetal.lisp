;;; roughmetal
;;; Rough metal surface shader — colored specular highlights (no white reflection).
;;;
;;; Converted from:
;;;   roughmetal.sl + material.h (BMRT)
;;;   (c) 1990-2000 Exluna Inc. / Larry Gritz
;;;
;;; MaterialRoughMetal:
;;;   return basecolor * (Ka*ambient() + Kd*diffuse(Nf) + Ks*specular(Nf,-normalize(I),roughness))
;;;
;;; Recommended: Kd < 0.1, Ks > 0.5, roughness > 0.15
;;;
;;; Ksky: sky gradient fill — 法線の上向き度合いで ambient に変化を付ける。
;;;   sky_factor = 0.5 + 0.5 * max(0, dot(up, Nf))  → 上向き面: 1.0, 下向き面: 0.5
;;;   shadow side に空のグラデーションを与え、単色を回避する。
;;;   Ksky=0 でオリジナルと同じ動作。
;;;
;;; 2026-08-09: BMRT roughmetal.sl の移植依頼で精査 — 本ファイルは**一度も core に
;;;   入ったことのない未配線ソース**だった (.o 無し/build-all 未登録/param テーブル無し)。
;;;   フル配線し、既定 Ksky を 0.8→**0 = 原典と同じ絵** に変更 (拡張は opt-in の方針)。
;;;   max の (d+|d|)/2 は max フック修理前の遺物 → (max 0.0 d) に現代化。

(setq roughmetal-shader

(make-shader roughmetal :keyword :surface
      (((Ka        float)  1.0)
       ((Kd        float)  0.1)
       ((Ks        float)  0.9)
       ((roughness float)  0.4)
       ((Ksky      float)  0.0)
       ((up        point)  (make-point 0 1 0)))

  (enter (
    ((Nf     point) (faceforward (normalize N) I))
    ((Ir     point) (normalize (- I)))
    ((d      float) 0.0)
    ((dc     float) 0.0)
    ((sky    color) (make-color 0 0 0)))

    ;; sky gradient: max(0, dot(up,Nf)) → 上は明るく、下は 0.5 * ambient
    (setvar d   (dot up Nf))
    (setvar dc  (max 0.0 d))
    (setvar sky (* Ksky (ambient) (+ 0.5 (* 0.5 dc))))

    (setvar Ci (* Cs
                   (+ (* Ka (+ (ambient) sky))  ; ambient + sky fill
                      (* Kd (diffuse Nf))
                      (* Ks (specular Nf Ir roughness)))))
    (setvar Oi Os)
    (setvar Ci (* Ci Oi)))))


(compile-shader roughmetal-shader)
(append-shader roughmetal-shader)
