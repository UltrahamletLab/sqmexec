;;; dfdimple — ゴルフボール状のディンプル / スタッド (blob deform の DSL 模様)
;;;
;;; 解析パターン (Σ coef·Π sin) では作れない模様の代表例。
;;; sin の積は「山と谷が同じ形」で滑らかに波打つが、ディンプルが欲しいときは
;;; **大部分が平ら + 格子点だけ窪む(or 出る)** という非対称な形が要る。
;;; pow で潰すとそれが作れる — pow は解析パターンの語彙に無い。
;;;
;;;   u = sin(f·x+ph)·sin(f·y+ph)·sin(f·z+ph)    ; 格子点で ±1、その間は 0 付近
;;;   g = sign · |u|^(1/round)                    ; round<1 で尖り、round>1 で丸く広がる
;;;
;;; round を上げるほど窪みが広く浅くなり、下げるほど点状に鋭くなる。
;;; bump>0.5 で外向きのスタッド (参照画像のイボ)、それ以外は内向きのディンプル。
;;;
;;; Lipschitz: |∇g| は round<1 で発散しうる (|u|^p は p<1 で u=0 に尖点)。
;;;   実用域 (round 0.5〜3) では L ≈ 3·f/round が安全側。**必ず掃引で裏を取ること** —
;;;   L を2倍にして絵が変わらなくなるまで上げる。
;;;
;;; 使い方 (シーン):
;;;   (deform (mode dsl)(shader dfdimple)(amp 0.35)(lipschitz 60)
;;;           (param freq 7.0)(param round 1.6)(param bump 1))

(setq dfdimple-shader

(make-shader dfdimple :keyword :displacement
      (((freq  float) 7.0)     ; 格子の細かさ
       ((phase float) 0.0)
       ((round float) 1.6)     ; 窪みの丸み (小=点状に鋭い / 大=広く浅い)
       ((bump  float) 0.0))    ; >0.5 で外向きスタッド、それ以外は内向きディンプル

  (enter (((u float) 0.0)
          ((a float) 0.0)
          ((g float) 0.0))

    (setvar u (* (* (sin (+ (* freq (xcomp P)) phase))
                    (sin (+ (* freq (ycomp P)) phase)))
                 (sin (+ (* freq (zcomp P)) phase))))

    (setvar a (abs u))
    ;; |u|^(1/round): round を上げると 0 付近が持ち上がり窪みが広がる
    (setvar g (pow (clamp a 0.0 1.0) (/ 1.0 (clamp round 0.15 8.0))))

    ;; 内向き(ディンプル)を既定にする。bump で反転。
    (if (> bump 0.5) (setvar g g) (setvar g (- 0.0 g)))
    (setvar disp g)
)))

(compile-shader dfdimple-shader)
(append-shader dfdimple-shader)
