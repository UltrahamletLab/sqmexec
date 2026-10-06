;;; fur — 毛皮の房 (変位シェーダー)
;;;
;;; :displacement クラス (2026-07-28 改修) のテストケース第2号。threads.lisp と同じく
;;; **パターンは .lisp 側**にあり、エンジンの再ビルドなしで毛の形を変えられる。
;;;
;;; 原理: 値ノイズ2オクターブを pow で尖らせた「房場」。ノイズの山だけが
;;;   スパイク状に残り (pow^sharp で谷は潰れる)、密度は P のスケールで決まる。
;;;   エンジンが d -= amp*disp するので、房はシルエットにも影にも出る
;;;   (= bump と違い本物の凹凸)。
;;;
;;;   h = pow( clamp( (1-detail)*vnoise(P*density) + detail*vnoise(P*density*2.17) ), sharp )
;;;
;;; vnoise は共有ノイズモジュール (noise.cpp) の値ノイズ = SDF/ボリュームと同一系統。
;;; stf 経由 (sqm 側の実装を呼ぶ) なので inline 化対象外だが、per-step でも実用速度
;;; (threads の実測で確認済みの経路)。
;;;
;;; 使い方 (シーン):
;;;   (displace (amp 0.03) (mode dsl) (shader fur) (lipschitz 60)
;;;             (param density 40) (param sharp 3) (param detail 0.35)
;;;             (param ymin 0.02))
;;;   ※ lipschitz ≈ 1.5〜2.5 × density が目安 (小さすぎると球面追跡が毛を貫通する)。
;;;   ※ grid SDF に載せるときは **SQM_SDF_GRID_NEPS=0.3** を忘れない —
;;;     既定の法線差分幅3ボクセルは毛程度の高周波を撫で消す
;;;     (docs/2026-07-21_SDFグリッドの法線差分幅とdisplacement.md)。

(setq fur-shader

(make-shader fur :keyword :displacement
      (((density float) 22.0)     ; 房の密度 (単位長あたりのノイズ周期)
       ((sharp   float) 3.0)      ; 尖り。大きいほど房が細く疎らに
       ((detail  float) 0.35)     ; 第2オクターブ (×2.17) の重み = 房の不揃い
       ((ymin    float) -1000.0)) ; これ未満の高さは毛なし (足裏の接地を守る)

  (enter (((q1 point) (make-point 0 0 0))
          ((q2 point) (make-point 0 0 0))
          ((n1 float) 0.0)
          ((n2 float) 0.0)
          ((h  float) 0.0))

    ;; 2オクターブの値ノイズ (周波数比 2.17: 整数比だと格子が揃って縞になる)
    (setvar q1 (* P density))
    (setvar n1 (vnoise q1))
    (setvar q2 (* P (* density 2.17)))
    (setvar n2 (vnoise q2))

    ;; 混合 → pow で山だけ残す = 房
    (setvar h (clamp (+ (* (- 1.0 detail) n1) (* detail n2)) 0.0 1.0))
    (setvar h (pow h sharp))

    ;; 接地際 (足裏) は滑らかにフェードアウト — 毛が床にめり込むのを防ぐ
    (setvar h (* h (smoothstep ymin (+ ymin 0.05) (ycomp P))))

    (setvar disp h)
)))

(compile-shader fur-shader)
(append-shader fur-shader)
