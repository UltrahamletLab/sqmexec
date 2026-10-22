;;; firevolume.lisp — 焼いた流体グリッド (密度+温度) を炎として描く :volume シェーダー
;;;                   (2026-08-14, three.js webgpu_volume_fire の移植)
;;;
;;; flamevolume との違いは **温度が密度から独立している**こと。flamevolume は
;;; temp = f(dens) なので「濃い＝熱い」に固定され、煙だけの部分が作れない。
;;; こちらは tools/fire_sim.mjs が解いた密度(煙)と温度(炎)を別チャンネルで受けるので、
;;;   下 = 高温 → 発光する炎
;;;   上 = 低温だが密度は残る → 発光しない灰色の煙
;;; が自然に分かれる。元例が density/temperature/age を別チャンネルに持つのと同じ。
;;;
;;; SGV の読み替え (エンジン vol.cpp / dr_volume_sample が設定):
;;;   Cs = (グリッド密度, グリッド温度, 0)   ← **焼いた場。既定アルベドではない**
;;;   s  = 組み込み fBm 密度                ← マーチ時のディテールノイズに使う
;;;   u  = 容器内の正規化高さ / v = 境界から内側への距離
;;;   出力 t=密度 / Cl=散乱アルベド / Ci=発光 / Oi=RGB消散
;;;
;;; 発光を密度で重み付けしないのは、エンジン側の前方積分が
;;;   a = 1 - exp(-σ·dens·ds);  C += T·a·(emission + ...)
;;; と既に a (=密度依存) を掛けるため。ここで密度を掛けると二重になる。
;;;
;;; ⚠ 変数名に t を使わないこと。t は**出力密度の SGV** なので潰れる。

(setq firevolume-shader
(make-shader firevolume :keyword :volume
      (((density-gain float) 1.0)     ; 密度の全体ゲイン (不透明度)
       ((temp-gain    float) 1.0)     ; 温度のゲイン (大=炎が広がる)
       ((temp-gamma   float) 1.5)     ; 温度コントラスト (大=芯だけ白熱)
       ((detail       float) 0.35)    ; マーチ時ディテールノイズの強さ (0=素の格子)
       ((cool-color   color) (make-color 0.95 0.10 0.015))  ; 低温 = 暗い赤
       ((mid-color    color) (make-color 1.70 0.55 0.06))   ; 中温 = 橙
       ((hot-color    color) (make-color 2.70 2.10 1.00))   ; 高温 = 白熱
       ((smoke-color  color) (make-color 0.40 0.39 0.38))   ; 煙の散乱アルベド
       ((extinction   color) (make-color 1.00 0.88 0.66))   ; RGB消散 (青ほど吸う)
       ((emit         float) 3.2)     ; 発光ゲイン
       ((edge-width   float) 0.02))   ; 容器の縁でのフェード幅

  (enter (((dg    float) 0.0)
          ((tg    float) 0.0)
          ((dn    float) 0.0)
          ((dd    float) 0.0)
          ((edge  float) 0.0)
          ((dens  float) 0.0)
          ((tempv float) 0.0)
          ((heat  color) (make-color 0 0 0)))

    ;; ── 焼いた場を取り出す ────────────────────────────────────
    ;; ⚠ Cs は color なので xcomp/ycomp (point 専用) は使えない。色成分は comp。
    (setvar dg (comp Cs 0))           ; 密度 (煙) 0..1
    (setvar tg (comp Cs 1))           ; 温度 (炎) 0..1

    ;; ── マーチ時のディテールノイズ ────────────────────────────
    ;; 焼いた場は格子解像度で滑らかなので、そのままだと縁が丸い団子になる。
    ;; 組み込み fBm (s) で密度を乗算変調して高周波を戻す。
    (setvar dn (+ 1.0 (* detail (* 2.0 (- s 0.5)))))
    (setvar dd (clamp (* dg dn) 0.0 4.0))

    ;; ── 密度 ──────────────────────────────────────────────────
    (setvar edge (smoothstep 0.0 edge-width v))
    (setvar dens (* density-gain (* dd edge)))
    (setvar t dens)

    ;; ── 温度 → 黒体風の3色ランプ ──────────────────────────────
    (setvar tempv (pow (clamp (* tg temp-gain) 0.0 1.0) temp-gamma))
    (setvar heat cool-color)
    (setvar heat (mix heat mid-color (smoothstep 0.12 0.48 tempv)))
    (setvar heat (mix heat hot-color (smoothstep 0.48 0.86 tempv)))

    ;; ── 出力 ──────────────────────────────────────────────────
    ;; 温度が 0 の所は発光ゼロ = 灰色の煙として散乱だけする。
    (setvar Cl smoke-color)
    (setvar Oi extinction)
    (setvar Ci (* heat (* emit tempv)))
)))

(compile-shader firevolume-shader)
(append-shader firevolume-shader)
