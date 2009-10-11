; Right now there are no syntactic forms defined or anything
; Basically we have the primitive forms and some data primtives

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

(define (null? x)
  (eq? x '()))


