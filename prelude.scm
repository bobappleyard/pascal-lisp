; Right now there are no syntactic forms defined or anything
; Basically we have the primitive forms and some data primtives
; It's basically a race to define quasiquote, and then we're a bit happier.

(add-global 'list 
  (lambda x x))

(add-global 'definition 
  (lambda (d s h b)
    (if (pair? h)
      (list d 
            (car h)
            (cons 'lambda
                  (cons (cdr h)
                        b)))
      (list s (list 'quote h) (car b)))))

(add-syntax 'define-macro
  (lambda (h . b)
    (definition 'define-macro 'add-syntax h b)))

(define-macro (define h . b)
  (definition 'define 'add-global h b))

; That's some of the really rough stuff out of the way

(define (null? x)
  (eq? x '()))

(define (zero? x)
  (if (eqv? x 0)
    #t
    (eqv? x 0.0)))

(define (void)
  #v)
  
(define (1- x)
  (fixnum-subtract x 1))

(define (1+ x)
  (fixnum-add x 1))

; Fold and map get better definitions below

(define (fold p i l)
  (if (null? l)
    i
    (fold p (p (car l) i) (cdr l))))

(define (reverse l)
  (fold cons '() l))

(define (map p l)
  (reverse (fold  (lambda (x acc) (cons (p x) acc))
                  '()
                  l)))

(define (append . ls)
  (if (null? ls)
    ls
    (if (null? (cdr ls))
      (car ls)
      (fold cons (apply append (cdr ls)) (reverse (car ls))))))

(define (compose f g)
  (lambda args (f (apply g args))))

; list accessors

(define   caar (compose car car))
(define   cadr (compose car cdr))
(define   cdar (compose cdr car))
(define   cddr (compose cdr cdr))
(define  caaar (compose car caar))
(define  caadr (compose car cadr))
(define  cadar (compose car cdar))
(define  caddr (compose car cddr))
(define  cdaar (compose cdr caar))
(define  cdadr (compose cdr cadr))
(define  cddar (compose cdr cdar))
(define  cdddr (compose cdr cddr))
(define caaaar (compose car caaar))
(define caaadr (compose car caadr))
(define caadar (compose car cadar))
(define caaddr (compose car caddr))
(define cadaar (compose car cdaar))
(define cadadr (compose car cdadr))
(define caddar (compose car cddar))
(define cadddr (compose car cdddr))
(define cdaaar (compose cdr caaar))
(define cdaadr (compose cdr caadr))
(define cdadar (compose cdr cadar))
(define cdaddr (compose cdr caddr))
(define cddaar (compose cdr cdaar))
(define cddadr (compose cdr cdadr))
(define cdddar (compose cdr cddar))
(define cddddr (compose cdr cdddr))

(define-macro (quasiquote tmplt)
  (if (pair? tmplt)
    (fold (lambda (cell acc)
            (if (pair? cell)
              (if (eq? (car cell) 'unquote) 
                (list 'cons (cadr cell) acc)
                (if (eq? (car cell) 'unquote-splicing) 
                  (list 'append (cadr cell) acc)
                  (list 'cons (list 'quasiquote cell) acc)))
              (list 'cons (list 'quote cell) acc)))
          ''()
          (reverse tmplt))
    (list 'quote tmplt)))

; Woo! Now let's get defining!

(define-macro (with-gensyms ss . b)
  `(let ,(map (lambda (s) `(,s (gensym))) ss)
    ,@b))

(define-macro (begin . b)
  `((lambda () ,@b)))

(define-macro (when t . b)
  `(if ,t (begin ,@b) #v))
  
(define-macro (unless t . b)
  `(when (not ,t) ,@b))

(define-macro (let bs . b)
  (if (pair? bs)
    `((lambda ,(map car bs) ,@b) ,@(map cadr bs))
    `(letrec ((,bs (lambda ,(map car (car b)) ,@(cdr b))))
      (,bs ,@(map cadr (car b))))))

(define-macro (let* bs . b)
  (if (null? bs)
    `(begin ,@b)
    `(let (,(car bs)) (let* ,(cdr bs) ,@b))))

(define-macro (letrec bs . b)
  `(let ,(map (lambda (b) `(,(car b) #v))
              bs)
    ,@(map  (lambda (b) `(set! ,(car b) ,(cadr b)))
            bs)
    ,@b))

(define-macro (and . cs)
  (if (null? cs)
    #t
    (if (null? (cdr cs))
      (car cs)
      `(if ,(car cs)
        (and ,@(cdr cs))
        #f))))

(define-macro (or . cs)
  (if (null? cs)
    #f
    (with-gensyms (val)
      `(let ((,val ,(car cs)))
        (if ,val 
          ,val
          (or ,@(cdr cs)))))))

(define (not x)
  (if x #f #t))
  
(define-macro (cond . cs)
  (if (null? cs)
    #v
    (let ((c (car cs)))
      (if (eq? (car c) 'else)
        `(begin ,@(cdr c))
        (if (eq? (cadr c) '=>)
          (with-gensyms (val)
            `(let ((,val ,(car c)))
              (if ,val
                (,(caddr c) ,val)
                (cond ,@(cdr cs)))))
          `(if ,(car c)
            (begin ,@(cdr c))
            (cond ,@(cdr cs))))))))

(define-macro (do vars test . cmds)
  (with-gensyms (loop)
    `(let ,loop ,(map (lambda (var) `[,(car var) ,(cadr var)]) vars)
      (if ,(car test)
        (begin 
          ,@(cdr test))
        (begin
          ,@cmds
          (,loop ,@(map (lambda (var)
                          (if (null? (cddr var))
                            (car var)
                            (caddr var)))
                        vars)))))))

; Lists

(define (list-type x)
  (cond 
    [(null? x) 'proper]
    [(pair? x)
      (let next  ([slow x]
                  [fast1 (cdr x)])
        (cond
          [(null? fast1) 'proper]
          [(not (pair? fast1)) 'improper]
          [else (let ([fast2 (cdr fast1)])
                  (cond
                    [(or  (null? slow)
                          (null? fast2))
                      'proper]
                    [(not (and  (pair? slow)
                                (pair? fast2)))
                      'improper]
                    [(or  (eq? slow fast1)
                          (eq? slow fast2))
                      'circular]
                    [else (next (cdr slow) 
                                (cdr fast2))]))]))]
    [else #f]))

(define proper-list? #f)
(define improper-list? #f)
(define circular-list? #f)
(let ([list-checker (lambda (type) 
                      (lambda (x) (eq? (list-type x) type)))])
  (set! proper-list? (list-checker 'proper))
  (set! improper-list? (list-checker 'improper))
  (set! circular-list? (list-checker 'circular)))

(define list? proper-list?)
  
(define (assert pred x msg)
  (unless (pred x)
    (error msg x)))
    
(define (assert-type pred x)
  (assert pred x "inavlid type"))

(define (assert-list l)
  (assert-type list? l))

(define (list-tail ls ref)
  (do  ([cur ls (cdr cur)] 
        [x ref (1- x)])
    ((zero? x) cur)))

(define (list-head ls ref)
  (reverse
    (do  ([cur ls (cdr cur)] 
          [x ref (1- x)] 
          [acc '() (cons (car cur) acc)])
      ((zero? x) acc))))

(define (list-ref ls ref)
  (car (list-tail ls ref)))

(define (fold-left proc init l . ls)
  (assert-list l)
  (if (null? ls)
    (if (null? l)
      init
      (fold-left proc (proc (car l) init) (cdr l)))
    (let ([lst (cons l ls)])
      (for-each assert-list ls)
      (if (fold-left  (lambda (x acc) (or acc (null? x)))
                      #f 
                      lst)
        init
        (apply  fold-left 
                proc 
                (apply proc (append (map car lst)
                                    (list init)))
                (map cdr lst))))))

(define fold fold-left)

(define (fold-right p i . ls)
  (apply fold p i (map reverse ls)))

(define (length ls)
  (fold (lambda (x acc) (1+ acc)) 0 ls))
  
(define (map proc . ls)
  (let ([ls-len (length ls)])
    (reverse (apply fold  
                    (lambda args
                      (let ([ls (list-head args ls-len)]
                            [acc (car (list-tail args ls-len))])
                        (cons (apply proc ls) acc)))
                    '()
                    ls))))

(define (for-each proc . ls)
  (let ([ls-len (length ls)])
    (apply  fold
            (lambda args
              (let ([ls (list-head args ls-len)])
                (apply proc ls)))
            '()
            ls)
    (void)))
  
(define (list=? a b)
  (cond
    [(and (null? a) (null? b)) #t]
    [(and (pair? a) (pair? b)) 
      (fold (lambda (a b acc) 
              (and  acc
                    (equal? a b)))
            #t
            a
            b)]
    [else #f]))

; equal? case, case-lambda

(define (equal? a b)
  ((cond 
      [(list? a) list=?] 
      [else eqv?])
    a b))

(define-macro (case val . cs)
  (with-gensyms (tmp)
    `(let ([,tmp ,val])
      (cond ,@(map  (lambda (c)
                      (if (eq? 'else (car c))
                        c
                        `[(or ,@(map (lambda (v) `(equal? ,tmp ',v)) (car c)))
                          ,@(cdr c)]))
                    cs)))))

(define-macro (case-lambda . cs)
  (with-gensyms (args)
    `(lambda ,args 
      (apply  (case (length ,args) 
                ,@(map  (lambda (c) 
                          (if (list? (car c))
                            `[(,(length (car c))) (lambda ,@c)]
                            `[else (lambda ,@c)]))
                        cs))
              ,args))))

; Numbers

(define integer? fixnum?)

(define =
  (case-lambda 
    [() #t]
    [(a) (assert-type number? a) #t]
    [(a b .rest)
      (assert-type number? a)
      (assert-type number? b)
      (and  (eqv? a b)
            (apply = b rest))]))

(define quotient fixnum-quotient)
(define modulo fixnum-modulo)

(define (remainder n d)
  (-  n
      (* (quotient n d) d)))

(define (num-op id rec wraps-fn wraps-rl)
  (case-lambda
    [() 
      id]
    [(a) 
      (assert-type number? a) 
      (rec id a)]
    [(a b)
      (assert-type number? a)
      (assert-type number? b)
      (if (and (fixnum? a) (fixnum? b))
        (wraps-fn a b)
        (wraps-rl (fixnum->real a) (fixnum->real b)))]
    [(a b . rest)
      (apply rec (rec a b) rest)]))

(define + (num-op 0 (lambda xs (apply + xs)) fixnum-add real-add))
(define - (num-op 0 (lambda xs (apply - xs)) fixnum-subtract real-subtract))
(define * (num-op 1 (lambda xs (apply * xs)) fixnum-multiply real-multiply))
(define / (num-op 1 
                  (lambda xs (apply / xs)) 
                  (lambda (a b) (real-divide (fixnum->real a) (fixnum->real b)))
                  real-divide))

  
  