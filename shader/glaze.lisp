;;; glaze — 陶器の釉薬。側面を流れ落ちる縦筋 + 底での溜まり(濃色) + 縁での薄れ、
;;;         濡れた光沢(フレネル)。和茶碗の天目/飴釉の「釉だれ」を表現。
;;;   縦に引き伸ばした turbulence で縦の流れ筋を作り、高さ勾配で底=濃/縁=薄を混ぜる。

(setq glaze-shader

(make-shader glaze :keyword :surface
      (
       ((Ka float) 0.18)
       ((Kd float) 0.6)
       ((Ks float) 0.8)
       ((roughness float) 0.04)
       ((glaze-color color) (make-color 0.30 0.16 0.07))   ; 溜まり(厚い釉)=濃色
       ((thin-color  color) (make-color 0.80 0.64 0.42))   ; 薄い釉(縁/高所)=明色
       ((flow float) 0.9)            ; 縦筋のコントラスト
       ((flow-scale float) 7.0)      ; 筋の周波数
       ((pool float) 0.85)           ; 底での溜まり強度(高さ勾配)
       ((low-y float) 0.05)          ; 釉が最も溜まる高さ(底)
       ((high-y float) 0.80)         ; 釉が最も薄れる高さ(縁)
       ((spec-color color) (make-color 1.0 0.95 0.85))
       ((sheen float) 0.6)           ; フレネルで縁を濡れた光沢に
       ((spots float) 0.0)           ; 油滴天目: 銀虹斑点の強度 (0=off, 既存シーン非破壊)
       ((spot-scale float) 38.0)     ; 斑点の密度(高周波数)
       ((spot-color color) (make-color 0.78 0.80 0.84)) ; 斑点=銀色
      )
  (enter (((Nf point) (faceforward (normalize N) I))
          ((Ir point) (normalize (- I)))
          ((sp point) 0)
          ((streak float) 0)
          ((th float) 0)
          ((g float) 0)
          ((fres float) 0)
          ((base color) (make-color 0 0 0))
          ((sn float) 0)
          ((spot float) 0)
          ((irid color) (make-color 0 0 0))
          ((oct float) 5))
    ;; 縦に引き伸ばした turbulence → 縦に流れ落ちる釉の筋
    (setvar sp (make-point (* (xcomp Pg) flow-scale)
                           (* (ycomp Pg) (* flow-scale 0.11))
                           (* (zcomp Pg) flow-scale)))
    (setvar streak (turbulence sp oct))
    ;; 高さ勾配: 底(low-y)=0 → 縁(high-y)=1
    (setvar th (smoothstep low-y high-y (ycomp Pg)))
    ;; 釉の厚み g: 底の溜まり (1-th)*pool + 縦筋(濃い釉だれ) (streak-0.3)*flow
    (setvar g (clamp (+ (* (- 1 th) pool) (* (- streak 0.3) flow)) 0 1))
    (setvar base (mix thin-color glaze-color g))
    ;; フレネル(濡れた光沢): 掠め角で反射↑
    (setvar fres (- 1 (clamp (dot Nf Ir) 0 1)))
    ;; 油滴天目: 高周波値ノイズを閾値化→釉の厚い所(g)に散る銀虹斑点。
    ;;   斑点色は正面=銀、掠め角=青へ虹色シフト。spots=0で完全に無効(回帰ゼロ)。
    (setvar sn (noise (* Pg spot-scale)))
    (setvar spot (* spots (* (smoothstep 0.58 0.67 sn) g)))
    (setvar irid (mix spot-color (make-color 0.30 0.45 0.90) fres))
    (setvar base (mix base irid spot))
    (setvar Oi Os)
    (setvar Ci (* Oi (+ (* base (+ (* Ka (ambient)) (* Kd (diffuse Nf))))
                        (* spec-color
                           (* Ks (+ 1 (* sheen fres)))
                           (specular Nf Ir roughness)))))
)))

(compile-shader glaze-shader)
(append-shader glaze-shader)
