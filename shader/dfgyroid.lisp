;;; dfgyroid — blob deform の DSL 模様: gyroid (TPMS 風の有機的セル)
;;;
;;; :displacement クラスだが用途は **ネイティブ blob の (deform (mode dsl)..)**。
;;; SDF 変位と同じ ABI (_dispfield_<name>) を共有しているのでクラスは同じでよい。
;;; 受け取る P は **blob ローカル座標** (解析モードの sin(f·Lx+ph) と同じ土俵)。
;;; 返す値は [-1,1] 想定 — エンジン側で clamp されるので、はみ出しても穴は開かないが
;;; 頭打ちになって模様が潰れる。
;;;
;;; これは C 側の解析 mode 2 の**完全な複製**。新機能ではなく検証用の基準線で、
;;; 「同じ模様を DSL 経路に流して解析経路と一致するか」を測るために置いてある
;;; (一致すれば Lipschitz 区間包囲が正しいことの証拠になる)。
;;;
;;;   g = ( sin(f·x+ph)·cos(f·y+ph)
;;;       + sin(f·y+ph)·cos(f·z+ph)
;;;       + sin(f·z+ph)·cos(f·x+ph) ) / 3
;;;
;;; Lipschitz (ローカル座標での |∇g| の上界):
;;;   ∂g/∂x = f·(cx·cy − sz·sx)/3  →  |∂g/∂x| <= 2f/3
;;;   |∇g| <= √3·(2f/3) = 2f/√3 ≈ 1.155·f
;;;   → シーンには (lipschitz (* 1.16 freq)) 相当の値を書く。
;;;
;;; 使い方 (シーン):
;;;   (deform (mode dsl)(shader dfgyroid)(amp 0.05)(lipschitz 3.5)
;;;           (param freq 3.0)(param phase 0.0))

(setq dfgyroid-shader

(make-shader dfgyroid :keyword :displacement
      (((freq  float) 3.0)     ; 空間周波数 (ローカル座標)
       ((phase float) 0.0))    ; 位相オフセット

  (enter (((sx float) 0.0) ((sy float) 0.0) ((sz float) 0.0)
          ((cx float) 0.0) ((cy float) 0.0) ((cz float) 0.0))

    (setvar sx (sin (+ (* freq (xcomp P)) phase)))
    (setvar sy (sin (+ (* freq (ycomp P)) phase)))
    (setvar sz (sin (+ (* freq (zcomp P)) phase)))
    (setvar cx (cos (+ (* freq (xcomp P)) phase)))
    (setvar cy (cos (+ (* freq (ycomp P)) phase)))
    (setvar cz (cos (+ (* freq (zcomp P)) phase)))

    (setvar disp (/ (+ (+ (* sx cy) (* sy cz)) (* sz cx)) 3.0))
)))

(compile-shader dfgyroid-shader)
(append-shader dfgyroid-shader)
