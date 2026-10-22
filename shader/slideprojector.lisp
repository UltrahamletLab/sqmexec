;;; slideprojector
;;;
;;; Copyright (C) 1993, Magic Box Productions, Inc.
;;;  All rights reserved.


(setq slideprojector-shader

(make-shader slideprojector :keyword :light
      (
	((fieldofview float) (/ PI 32))
        ((from point) (make-point 8 -4 10))
        ((to point) (make-point 0 0 0))
        ((up point) (make-point 0 1 0))
        ((slide-name string) "")
        ((shadowname string) "")
        
       )
  (enter (
         ((relT point) (make-point 0 0 0))
         ((relU point) (make-point 0 0 0))
         ((relV point) (make-point 0 0 0))
         ((spread float) (/ 1.0 (tan (/ fieldofview 2))))
        ;((Ps point) (make-point 0 0 0))
         ((Pt float) 0)
         ((Pu float) 0)
         ((Pv float) 0)
     
         ((sloc float) 0) 
         ((tloc float) 0)
         ((Lt point) (make-point 0 0 0))
         )
         ;
         (setvar relT (normalize (- to from)))
         (setvar relU (cross relT up))
         (setvar relV (normalize (cross relT relU)))
         (setvar relU (cross relV relT))
         ;
         (illuminate (from relT (/ (atan (sqrt 2)) spread))
         (setvar Lt (- P from))
         (setvar Pt (dot Lt relT))
         (setvar Pu (dot Lt relU))
         (setvar Pv (dot Lt relV))
         (setvar sloc (/ (* spread Pu) Pt))
         (setvar tloc (/ (* spread Pv) Pt))
         (setvar sloc (+ (* sloc 0.5) 0.5))
         (setvar tloc (+ (* tloc 0.5) 0.5))
         ;(setvar Cl (texture slide-name))
         (setvar Cl (texture slide-name sloc tloc))

        ;(if (!= shadowname "") (setvar Cl (+ Cl)))


         )
      
         

))) 

(compile-shader slideprojector-shader)
(append-shader slideprojector-shader)
