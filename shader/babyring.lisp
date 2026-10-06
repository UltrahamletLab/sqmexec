;;; babyring — 耳の同心円リッジ (BabyToy dHead 転写用)
;;;
;;; 原典: ear += cos(dEar*30 - 3) * .01,  dEar = |tp.xy - (.1, 0)|
;;; 円柱リーフのローカル座標 v = (tp.x, tp.z-.18, -tp.y) なので
;;; dEar = sqrt((v.x-cx)^2 + (v.z-cz)^2)。engine は d - amp*h → h = -cos(...)。
;;; ※ 囲む (scale ..) が距離を min(s)≈.8 倍するので実効 amp も .8 倍 —
;;;   原典の ear*.8 と同じ縮みが自動で掛かる。
(setq babyring-shader

(make-shader babyring :keyword :displacement
      (((cx   float) 0.1)       ; リング中心 (リーフローカル x,z)
       ((cz   float) 0.0)
       ((freq float) 30.0)
       ((ph   float) -3.0))

  (enter (((ddx float) 0.0)
          ((ddz float) 0.0)
          ((rr  float) 0.0))

    (setvar ddx (- (xcomp P) cx))
    (setvar ddz (- (zcomp P) cz))
    (setvar rr (sqrt (+ (* ddx ddx) (* ddz ddz))))
    (setvar disp (- 0.0 (cos (+ (* freq rr) ph))))
)))

(compile-shader babyring-shader)
(append-shader babyring-shader)
