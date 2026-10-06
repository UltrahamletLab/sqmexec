;;; threads — y軸まわりの螺旋ねじ山 (変位シェーダー)
;;;
;;; Converted from:
;;;   Listing 16.24 "Displacement shader providing light-bulb threads to cylinder"
;;;   (The RenderMan Interface / 電球の作例, Plate 9)
;;;
;;;   magnitude = sin(PI*2*(t*frequency + s + phase) + offset) * Km;
;;;   if (t > 1-dampzone)  magnitude *= (1.0-t)/dampzone;
;;;   else if (t < dampzone) magnitude *= t/dampzone;
;;;   P += normalize(N) * magnitude;  N = calculatenormal(P);
;;;
;;; sqm 版の違い:
;;;  ・**距離関数の中から呼ばれる** (:displacement クラス)。入力は3D点 P だけで、
;;;    出力は高さ `disp`。P を動かすのでも N を作るのでもなく「高さを返す」形。
;;;    エンジンが d -= amp*disp して距離場ごと変位させるので、法線もシルエットも
;;;    自動で付いてくる (calculatenormal 相当は engine の中心差分)。
;;;  ・s,t は shader に渡ってこない (SDF は s,t を持たない) ので **P から解析的に復元**する。
;;;      s = atan2(P.z, P.x)/2π   t = (P.y - ymin)/height
;;;    s は1周で 1 増える → 2π*s は 2π 跳ぶ = sin は継ぎ目で連続 (だから螺旋が閉じる)。
;;;  ・戻り値は [0,1] に正規化 (0.5+0.5*sin)。円筒半径が谷径、山が amp だけ外へ出る。
;;;
;;; 使い方 (シーン):
;;;   (displace (mode dsl) (shader threads) (amp 0.038) (lipschitz 2.4)
;;;             (param frequency 7) (param ymin 0.03) (param height 0.60)
;;;             (param dampzone 0.10))
;;;   ※ lipschitz は |∇disp| の上界を**シーン側が申告する**。engine は任意の .lisp から
;;;     導出できないため。この式では sqrt((π*freq/height)^2 + (0.5/rmin)^2) が上界。
;;;     小さすぎると球面追跡がオーバーシュートして穴が開く。
;;;
;;; ※ この移植のために DSL に **atan2 (2引数)** を追加した (既存の atan は1引数のみ)。

(setq threads-shader

(make-shader threads :keyword :displacement
      (((frequency float) 5.0)     ; ねじ長あたりの巻き数
       ((phase     float) 0.0)     ; 螺旋の位相
       ((ymin      float) 0.0)     ; ねじを切り始める y
       ((height    float) 1.0)     ; ねじを切る軸方向の長さ
       ((dampzone  float) 0.05))   ; 両端で山を0に落とす帯 (t比)

  (enter (((r   float) 0.0)
          ((tt  float) 0.0)
          ((ss  float) 0.0)
          ((h   float) 0.0)
          ((g   float) 0.0))

    ;; 円筒座標を P から復元
    (setvar r  (sqrt (+ (* (xcomp P) (xcomp P)) (* (zcomp P) (zcomp P)))))
    (setvar tt (/ (- (ycomp P) ymin) height))
    (setvar ss (* (atan2 (zcomp P) (xcomp P)) 0.15915494309189535))  ; 1/(2π)

    ;; 原典の magnitude。[0,1] へ正規化して返す
    (setvar h (+ 0.5 (* 0.5 (sin (+ (* 6.283185307179586
                                       (+ (* tt frequency) ss))
                                    phase)))))

    ;; 両端の dampzone (原典どおり) + 範囲外は山なし
    (if (< tt 0.0) (setvar h 0.0))
    (if (> tt 1.0) (setvar h 0.0))
    (if (< tt dampzone)
        (setvar h (* h (/ tt dampzone))))
    (if (> tt (- 1.0 dampzone))
        (setvar h (* h (/ (- 1.0 tt) dampzone))))

    ;; 軸近傍は θ の勾配が発散する → ゲート (smoothstep で 0.02→0.05)
    (setvar g (smoothstep 0.02 0.05 r))
    (setvar disp (* h g))
)))

(compile-shader threads-shader)
(append-shader threads-shader)
