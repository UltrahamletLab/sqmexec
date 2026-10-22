;;; staggerbump.lisp — fundza "RSL - Repeating Patterns" (square/repeat/staggered) の移植
;;;
;;; セル内矩形 square() = 4枚の smoothstep の積を、反復セル + 互い違い行で敷く
;;; 変位。原典の s,t は :displacement に無いので xmin..xmax / ymin..ymax
;;; (オブジェクトのローカル2軸, 壁=xy) から復元する。stagger 1 で偶数行を
;;; 半セルずらす (レンガ)。原典の (s+0.5)*rep は rep 偶数で無効化する癖が
;;; あるため、正しい半セル mod(s·rep+0.5) に直した。
;;;
;;; パラメータ定義順 (shade_dr.cpp の staggerbump_dparams[] と一致必須):
;;;   xmin=0 xmax=1 ymin=2 ymax=3 s-repeats=4 t-repeats=5
;;;   min-c=6 max-c=7 taper=8 stagger=9
(setq staggerbump-shader
(make-shader staggerbump :keyword :displacement
  (((xmin float) -1.0)
   ((xmax float) 1.0)
   ((ymin float) 0.0)
   ((ymax float) 2.0)
   ((s-repeats float) 6.0)
   ((t-repeats float) 4.0)
   ((min-c float) 0.08)
   ((max-c float) 0.92)
   ((taper float) 0.10)
   ((stagger float) 1.0))
  (enter (((su float) 0) ((tv float) 0)
          ((row float) 0) ((off float) 0)
          ((cs float) 0) ((ct float) 0)
          ((h float) 0))
    (setvar su (/ (- (xcomp P) xmin) (- xmax xmin)))
    (setvar tv (/ (- (ycomp P) ymin) (- ymax ymin)))
    (setvar row (floor (* tv t-repeats)))
    ;; 偶数行を半セルずらす (stagger=0 で無効)
    (setvar off (* 0.5 stagger (- 1 (mod row 2))))
    (setvar cs (mod (+ (* su s-repeats) off) 1))
    (setvar ct (mod (* tv t-repeats) 1))
    ;; square(): セル内矩形 = smoothstep 4枚の積
    (setvar h (* (smoothstep min-c (+ min-c taper) cs)
                 (- 1 (smoothstep max-c (+ max-c taper) cs))
                 (smoothstep min-c (+ min-c taper) ct)
                 (- 1 (smoothstep max-c (+ max-c taper) ct))))
    (setvar disp h)))
)
(compile-shader staggerbump-shader)
(append-shader staggerbump-shader)
