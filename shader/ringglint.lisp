;;;; ringglint.lisp — pbrsurface + 太陽方向グリント (十字フレアの種火)。
;;;;
;;;; 目的: エンジンの -S クロス/スターフレア後処理は「HDR輝度がしきいを超えた明部」から
;;;;   光条を引く。ところが銅リング (torus) では GGX 鏡面が破綻し、キラッの種火が出ない:
;;;;     ・実測: Ks を 1.6→60 (37倍) にしても変化は 39画素/最大差10 = ほぼ無反応。
;;;;       反射ベクトル reflect(I,N) が太陽と揃う点が「見えているリング面」に存在しない。
;;;;     ・加えて材質の (displace (freq 120)) が微細な法線ノイズを与え、鋭い GGX ローブを
;;;;       スペックルに散らしてしまう。
;;;;   → 鏡面(reflect·sundir)に頼るのをやめ、N·L を直接使う明示的なグリント項を持つ。
;;;;      トーラスは管が360°回るので「法線が太陽を向く点」は必ず存在する = 確実に着地する。
;;;;      物理的には鏡面反射ではないが、画としては「太陽を捉えた瞬間のキラッ」に読める。
;;;;
;;;; ベースは pbrsurface と完全に同一 (Ka/Kd/Ks/roughness/metallic/Kr の意味も同じ)。
;;;; glint-amp=0 なら pbrsurface と同じ絵になる → 既存の承認済みリング材質を壊さない。
;;;;
;;;; パラメータ定義順 (shade_dr.c の ringglint_params[] と一致させること):
;;;;   Ka=0 Kd=1 Ks=2 roughness=3 metallic=4 Kr=5
;;;;   glint-amp=6 glint-sharp=7 glint-gain=8 glint-color=9 sundir=10
(setq ringglint-shader
(make-shader ringglint :keyword :surface
      (  ;; ── params: 並び順 == surfaceArgs index 0,1,2,... ──
       ((Ka float) 0.2)
       ((Kd float) 1.0)
       ((Ks float) 1.0)
       ((roughness float) 0.3)
       ((metallic float) 0.0)
       ((Kr float) 1.0)
       ((glint-amp   float) 0.0)      ; 0..1 グリントの強さ。アニメでパルスさせる (0=無効=pbrsurface同等)
       ((glint-sharp float) 90.0)     ; 大きいほど輝点が小さく鋭い (N·L の指数)。90=単一の細いX字
       ((glint-gain  float) 40.0)     ; HDR 輝度の倍率。-S の threshold を超えるのに必要。40=控えめ
       ((glint-color color) (make-color 1.0 0.95 0.85))   ; 太陽色
       ((sundir      point) (make-point -0.45 0.62 -0.40))
      )
  (enter (((Nf point)         (faceforward (normalize N) I))
          ((Ir point)         (normalize (- I)))
          ((dielectric color) (make-color 0.04 0.04 0.04))
          ((F0 color)         (make-color 0 0 0))
          ((direct color)     (make-color 0 0 0))
          ((amb color)        (make-color 0 0 0))
          ((refl color)       (make-color 0 0 0))
          ((sd point)         (make-point 0 1 0))
          ((gl float)         0)
          ((gv float)         0))
    ;; ── ベース: pbrsurface と同一 ──
    (setvar F0 (mix dielectric Cs metallic))
    (setvar direct (pbr Nf Ir roughness metallic F0 Kd Ks))
    (setvar refl (pbrenv Nf Ir roughness F0))
    (setvar amb  (ambient))
    ;; ── 太陽方向グリント: 法線が太陽を向くほど鋭く発光 ──
    ;;   gl = max(N·sundir, 0) を glint-sharp 乗して輝点を絞る。
    ;;   ※ 影 (vis) を見ない: pbr の GGX 鏡面はリング自身の影で vis=0 になり、
    ;;      Ks を 1.6→60 (37倍) にしても変化 39画素/最大差10 = ほぼ無反応だった (実測)。
    ;;      グリントは演出なので遮蔽を無視して確実に焚く。
    ;;   ※ sharp/gain のバランスが肝: 太陽が後方だと見える面の N·L 最大は ~0.95 止まり。
    ;;      sharp を上げすぎる (400+) と 0.95^400≈0 で光条が消え、下げすぎると広い弧が
    ;;      光って X字が平行に多重化する。sharp 90 / gain 40 が単一の細いX字になる (実測)。
    (setvar sd (normalize sundir))
    (setvar gl (clamp (dot Nf sd) 0 1))
    (setvar gv (* glint-gain (* glint-amp (pow gl glint-sharp))))
    (setvar Oi Os)
    ;; 最終 = pbrsurface の絵 + グリント (加算発光)
    (setvar Ci (* Oi (+ (+ (+ (* Cs (* Ka (* (- 1 metallic) amb))) direct)
                          (* Kr refl))
                        (* glint-color gv)))))))
(compile-shader ringglint-shader)
(append-shader ringglint-shader)
