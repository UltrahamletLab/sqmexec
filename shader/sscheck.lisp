;;; sscheck — shader 空間の3Dチェッカー ((transform "shader" P) のデモ/回帰)
;;;
;;; shader 空間 (2026-08-09 新設) の最小の使用例:
;;;   (surface .. (shader-space (translate ..)(rotate ..)(scale ..)))
;;; で宣言したテクスチャフレームへ (transform "shader" Pg) で座標を移し、
;;; そこで 3D チェッカーを刻む。**ジオメトリを動かさずに模様だけ**回転・
;;; 移動・拡縮できる。宣言が無ければ transform は恒等 = ワールドのチェッカー。
;;;
;;; パラメータ定義順 (shade_dr.cpp の sscheck_params[] と一致必須):
;;;   Kd=0 Ka=1 frequency=2 black-color=3

(setq sscheck-shader

(make-shader sscheck :keyword :surface
      (
       ((Kd float) 0.80)
       ((Ka float) 0.18)
       ((frequency float) 4.0)                       ; セル密度 (shader 空間単位あたり)
       ((black-color color) (make-color 0.08 0.08 0.10))
       )

  (enter (((Nf point) (faceforward (normalize N) I))
          ((q  point) (make-point 0 0 0))
          ((f  float) 0.0)
          ((ct color) (make-color 1 1 1)))

    ;; ワールド → shader 空間 (未宣言なら恒等)
    (setvar q (transform "shader" Pg))
    (setvar q (* q frequency))

    ;; 3D チェッカー: floor基準の mod(Σ floor(qi), 2)。
    ;; ⚠ C の fmod は負で符号が残る (mod(-9,2)=-1) → mix が外挿して黒に潰れる。
    ;;   負の座標でも {0,1} になるよう x - 2*floor(x/2) で書く (既知の mod の罠)。
    (setvar f (+ (floor (xcomp q))
                 (+ (floor (ycomp q)) (floor (zcomp q)))))
    (setvar f (- f (* 2.0 (floor (/ f 2.0)))))

    (setvar ct (mix black-color Cs f))
    (setvar Oi Os)
    (setvar Ci (* Oi ct (+ (* Ka (ambient)) (* Kd (diffuse Nf)))))
)))

(compile-shader sscheck-shader)
(append-shader sscheck-shader)
