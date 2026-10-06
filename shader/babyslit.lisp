;;; babyslit — 閉じた瞼のVスリット (BabyToy 転写用)
;;;
;;; 原典 (目の球に加算 = 内側へ彫る):
;;;   sf = S(z1a,z1b,p.z) * S(z2a,z2b,p.z)               ; スリットが出るzの窓
;;;   ed += S(.05*sf, 0, |ep.y - |ep.x*.6||) * .02 * sf  ; V字曲線に沿う溝
;;; engine は d - amp*h なので h = -(内側S * sf), amp=.02。
;;; P は目の球ノードのローカル座標 = 頭フレーム (球はリーフ直付けなので変換なし)。
;;; wfac*sf → 0 で除算が壊れるので下限 1e-4 でクランプ (振幅も sf で消えるので影響なし)。
(setq babyslit-shader

(make-shader babyslit :keyword :displacement
      (((cx    float) 0.0)      ; 目の中心 (ノードローカル)
       ((cy    float) 0.0)
       ((cz    float) 0.0)
       ((slope float) 0.6)      ; V字の開き |ep.y - |ep.x*slope||
       ((wfac  float) 0.05)     ; 溝幅の係数 (幅 = wfac*sf)
       ((z1a   float) -0.79)    ; z窓1 (S は逆エッジ可)
       ((z1b   float) -0.5)
       ((z2a   float) -0.1)     ; z窓2
       ((z2b   float) -0.5))

  (enter (((sf  float) 0.0)
          ((s2f float) 0.0)
          ((ag  float) 0.0)
          ((ww  float) 0.0)
          ((tt  float) 0.0))

    (setvar sf (clamp (/ (- (zcomp P) z1a) (- z1b z1a)) 0.0 1.0))
    (setvar sf (* (* sf sf) (- 3.0 (* 2.0 sf))))
    (setvar s2f (clamp (/ (- (zcomp P) z2a) (- z2b z2a)) 0.0 1.0))
    (setvar s2f (* (* s2f s2f) (- 3.0 (* 2.0 s2f))))
    (setvar sf (* sf s2f))

    (setvar ag (abs (- (- (ycomp P) cy) (abs (* (- (xcomp P) cx) slope)))))
    (setvar ww (clamp (* wfac sf) 0.0001 1.0))
    (setvar tt (clamp (/ (- ag ww) (- 0.0 ww)) 0.0 1.0))   ; S(w, 0, ag)
    (setvar tt (* (* tt tt) (- 3.0 (* 2.0 tt))))

    (setvar disp (- 0.0 (* tt sf)))
)))

(compile-shader babyslit-shader)
(append-shader babyslit-shader)
