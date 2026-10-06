;;; dfcrust — blob deform の DSL 模様: ドメインワープ付きリッジノイズの地殻
;;;
;;; :displacement クラス。用途は **ネイティブ blob の (deform (mode dsl)..)**。
;;; 受け取る P は blob ローカル座標、返す値は [-1,1] 想定 (エンジン側で clamp)。
;;;
;;; これが DSL 化の**本題**: 解析 mode 0〜3 は全て「線形引数の sin の和/積」なので、
;;; どう組み合わせても格子状の規則模様にしかならない。fBm を通した非周期の稜線は
;;; C 側に case を足さない限り書けなかった。
;;;
;;;   qw = P + warp·(vfbm(P·wfreq, 2) − 0.5)     ; 輪郭自体を歪める (同心円化を防ぐ)
;;;   n  = vfbm(qw·freq, 4)                       ; [0,1]
;;;   r  = (1 − |2n − 1|)^sharp                   ; 稜線 (ridged): 谷が広く尾根が細い
;;;   g  = 2r − 1                                 ; [-1,1] へ
;;;
;;; Lipschitz (ローカル座標での |∇g| の上界):
;;;
;;;   L ≈ 8 · sharp · freq · (1 + warp·wfreq)
;;;
;;;   導出は |∇g| <= 4·sharp·|∇n| / |∇n| <= freq·(1+warp·wfreq)·|∇vfbm| で、
;;;   4オクターブ vfbm の実効勾配 |∇vfbm|≈2 を入れたもの。**机上の式は当てにせず
;;;   下の掃引で必ず裏を取ること** — 最初に 2·sharp·freq·(1+warp·wfreq)·2 と見積もって
;;;   実測の 1/4 で、demo シーンが静かに壊れていた (2026-08-01)。
;;;
;;;   実測 (560×420 A2、L を倍々にして「絵が変わらなくなる」点):
;;;     freq 2.5 / warp 0.30 / wfreq 1.0 / sharp 1.5 → L=40  (式 39)
;;;     freq 5.0 / warp 0.45 / wfreq 1.6 / sharp 2.5 → L=160 (式 172)
;;;
;;; **L が小さすぎると区間包囲が真値を外して稜線が食われ輪郭がぼろぼろになる**。
;;; 見分け方: L を2倍にして絵が変われば、元の L は足りていない。変わらなくなるまで
;;; 上げるのが唯一確実な確認方法 (穴は「それらしい岩肌」に見えるので目視では騙される)。
;;; 大きすぎる分は安全だが細分が増えて遅くなるだけ。
;;;
;;; 使い方 (シーン):
;;;   (deform (mode dsl)(shader dfcrust)(amp 0.45)(lipschitz 40)
;;;           (param freq 2.5)(param warp 0.3)(param wfreq 1.0)(param sharp 1.5))

(setq dfcrust-shader

(make-shader dfcrust :keyword :displacement
      (((freq  float) 2.5)     ; 稜線の細かさ
       ((warp  float) 0.3)     ; ドメインワープ量 (0=素直な fBm・大きいと渦を巻く)
       ((wfreq float) 1.0)     ; ワープ場の周波数
       ((sharp float) 1.5))    ; 稜線の鋭さ (大きいほど尾根が細く谷が広い)

  (enter (((qw point) (make-point 0 0 0))
          ((n  float) 0.0)
          ((r  float) 0.0))

    ;; 塊の輪郭そのものを歪める (rock.lisp と同じ考え方)
    (setvar qw (+ P (* warp (- (vfbm (* P wfreq) 2) 0.5))))

    (setvar n (vfbm (* qw freq) 4))

    ;; ridged: 0.5 を境に折り返して稜線化 → pow で尾根を締める
    (setvar r (- 1.0 (abs (- (* 2.0 n) 1.0))))
    (setvar r (pow (clamp r 0.0 1.0) sharp))

    (setvar disp (- (* 2.0 r) 1.0))
)))

(compile-shader dfcrust-shader)
(append-shader dfcrust-shader)
