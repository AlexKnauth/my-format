#lang at-exp racket/base

(provide -format
         -printf
         -fprintf
         -eprintf
         -error
         parse-format-args
         parse-format-args-warn-about-newline?
         )

(require racket/list
         racket/match
         match-string
         )
(module+ test
  (require rackunit images/logos))

(define nat? exact-nonnegative-integer?)

(define parse-format-args-warn-about-newline? (make-parameter #t (λ (x) (if x #t #f))))

(define (-format . args)
  (apply format (parse-format-args args)))

(define (-printf . args)
  (apply printf (parse-format-args args)))

(define (-fprintf out . args)
  (apply fprintf out (parse-format-args args)))

(define (-eprintf . args)
  (apply eprintf (parse-format-args args)))

(define (-error . args)
  (match args
    [(list (? symbol? sym)) (error sym)]
    [(list-rest (? symbol? sym) rst) (apply error sym (parse-format-args rst))]
    [_ (apply error args)]))

(define format-string? string?)

(define (format-arg-num-error? e)
  (and (exn:fail:contract? e)
       (match (exn-message e)
         [(string-append "format: format string requires "(? string->number)" arguments, "
                         "given "(? string->number)"; arguments were: "_)
          #t]
         [_ #f])))

;; format-string->num-of-args : Format-String -> Natural
(define (format-string->num-of-args str)
  (cond
    [(not (string? str)) (error 'format-string->num-of-args "expected a string, given: ~v" str)]
    [else
     (define thing
       (with-handlers ([format-arg-num-error? (λ (e) e)])
         (format str)))
     (cond [(string? thing) 0]
           [(exn:fail:contract? thing)
            (match (exn-message thing)
              [(string-append
                "format: format string requires "(app string->number (? nat? n))" arguments, "
                "given 0; arguments were: "_)
               n])]
           [else (error 'format-string->num-of-args "this should never happen")])]))

;; parse-format-args : (Listof Any) -> (Cons String (Listof Any))
(define (parse-format-args args)
  (match args
    [(list) (list "")]
    [(cons (? format-string? s) rst)
     (define n (format-string->num-of-args s))
     (unless (<= n (length rst))
       (error 'parse-format-args
              (string-append "format string requires ~v arguments, given ~v" "\n"
                             "  format-string: ~v"
                             "  other-arguments: ~v")
              n (length rst) s rst))
     (define-values (rst.vs rst.rst) (split-at rst n))
     (maybe-give-newline-warning #:args args #:vs rst.vs)
     (match-define (cons rst.rst.s rst.rst.vs) (parse-format-args rst.rst))
     (cons (string-append s rst.rst.s) (append rst.vs rst.rst.vs))]))

(define (maybe-give-newline-warning #:args args #:vs vs)
  (when (parse-format-args-warn-about-newline?)
    (for ([v (in-list vs)] #:when (equal? v "\n"))
      (eprintf
       (string-append
        "\n"
        "warning:" "\n"
        "  parse-format-args: place-fillers should be on the same line as the place-holders" "\n"
        "    args: ~v" "\n"
        "    if they are on the same line and you're sure that the place-filler should be ~v," "\n"
        "    then you should set the parse-format-args-warn-about-newline? parameter to #f" "\n")
       args "\n"))))

(module+ test
  (test-case "my-format"
    (check-equal? (-format) "")
    (check-equal? (-format "hello world") "hello world")
    (check-equal? (-format "hello" "world") "helloworld")
    (check-equal? (-format "hello ~a!" 'world) "hello world!")
    (check-equal? (-format "hello, ~a and ~a!" 'earth 'mars) "hello, earth and mars!")
    (check-equal? (-format "hello, ~a" 'earth " and ~a!" 'mars) "hello, earth and mars!")
    (check-equal? (-format "<~v,~v>" 1 2) "<1,2>")
    (check-equal? (-format "<~v,~v>" 1 2 " and <~v,~v>" 3 4) "<1,2> and <3,4>")
    (check-equal? @-format{<~v,~v>@|1 2| and <~v,~v>@|3 4|} "<1,2> and <3,4>")
    (check-equal? @-format{<~v@|1|,~v@|2|> and <~v@|3|,~v@|4|>} "<1,2> and <3,4>")
    (check-equal? (let ([out (open-output-string)])
                    (parameterize ([current-error-port out])
                      @-format{blah blah
                               blah blah ~v
                               @|"something"|})
                    (get-output-string out))
                  #<<>>>

warning:
  parse-format-args: place-fillers should be on the same line as the place-holders
    args: '("blah blah ~v" "\n" "something")
    if they are on the same line and you're sure that the place-filler should be "\n",
    then you should set the parse-format-args-warn-about-newline? parameter to #f

>>>
                  )
    )
  #;
  (test-case "qualitative stuff with syntax objects, fractions, and images"
    @-printf{message
               thing-1: ~v@|#'here|
               thing-2: ~s@|"idontkare"|
               thing-3: ~v@1/2 and ~v@3/2
               thing-4: ~a ~v@|1 2|
               thing-5: ~v@(plt-logo #:height 30)
             @""}
    )
  )
