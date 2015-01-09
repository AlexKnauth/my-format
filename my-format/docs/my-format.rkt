#lang scribble/manual

@(require scribble/eval
          (for-label my-format
                     racket))

@title{my-format}

@defmodule[my-format]

@section{Functions}

@defproc[(-format [arg any/c] ...) string?]{
sort of like @racket[format], except that if a "group of arguments" is a format string followed by the
number of place-filler arguments that the format string accepts, then @racket[-format] can take any
number of "groups of arguments."  It combines these groups of arguments together into a format string
and place-filler arguments using @racket[parse-format-args], and then passes those to @racket[format].

@racket[-format] can be used as a normal s-expr function, or it can be used with
@"@-expressions", although this is more prone to mistakes (see @secref["my-format with at-exp"]), so
be careful.

You can use this to put the place-fillers close or right next to the place-holders.
@examples[
  (define s string-append)
  (define-values (who a b c d) (values 'world 1 2 8 13))
  (display
   (format (s "hello ~a, here are some examples of adding numbers in racket:\n"
              "  to add ~v and ~v, type ~a, and it will return ~v\n"
              "  or for adding ~v and ~v, ~a = ~v")
           who a b `(+ ,a ,b) (+ a b) c d `(+ ,c ,d) (+ c d)))
  (require my-format)
  (display
   (-format "hello ~a, " who "here are some examples of adding numbers in racket:\n"
            "  to add ~v and ~v, " a b "type ~a, " `(+ ,a ,b) "and it will return ~v" (+ a b) "\n"
            "  or for adding ~v and ~v, " c d "~a = ~v" `(+ ,c ,d) (+ c d)))
]
An example with @"@-expressions":
@codeblock[#:keep-lang-line? #f]|{
#lang at-exp racket
@-format{hello ~a@who, here are some examples of adding numbers in racket:
           to add ~v and ~v@|a b|, type ~a@`(+ ,a ,b), and it will return ~v@(+ a b)
           or for adding ~v@c and ~v@d, ~a = ~v@|`(+ ,c ,d) (+ c d)|}
}|}

@defproc[(-printf [arg any/c] ...) void?]{
like @racket[-format], it translates its @racket[arg]s into a format string + place-fillers
using @racket[parse-format-args], but it passes the resulting arguments to @racket[printf]
instead of @racket[format].

This can be useful for printing images, syntax objects, or fractions in environments such as DrRacket,
where functions like @racket[~v] and @racket[~a] wouldn't be able to convert them to strings properly.
@examples[
  (require my-format)
  (define-values (who a b c d) (values 'world 1 2 8 13))
  (-printf "hello ~a, " who "here are some examples of adding numbers in racket:\n"
           "  to add ~v and ~v, " a b "type ~a, " `(+ ,a ,b) "and it will return ~v" (+ a b) "\n"
           "  or for adding ~v and ~v, " c d "~a = ~v" `(+ ,c ,d) (+ c d))
]}

@defproc[(-fprintf [out output-port?] [arg any/c] ...) void?]{
like @racket[-printf] in how it treats its @racket[arg]s, but has an output port argument like
@racket[fprintf].
}

@defproc[(-eprintf [arg any/c] ...) void?]{
like @racket[-printf], but prints to the @racket[current-error-port] like @racket[eprintf].
}

@defproc*[([(-error [sym symbol?]) nothing]
           [(-error [sym symbol?] [arg any/c] ...) nothing]
           [(-error [arg any/c] ...) nothing])]{
like @racket[error], but for the second case it treats the @racket[arg]s like @racket[-format] does
using @racket[parse-format-args], and then passes those to @racket[error].
}

@defproc[(parse-format-args [args (listof any/c)]) (cons/c string? (listof any/c))]{
a helper function to combine "groups of arguments," each with a format string and some number of
place-fillers, into one "group of arguments," with one format string and all the place-fillers after
it.
}

@defboolparam[parse-format-args-warn-about-newline? warn? #:value #t]{
a parameter that controlls whether @racket[parse-format-args] warns you if it thinks you might be
making the newline mistake (see @secref["my-format with at-exp"]).
}

@section[#:tag "my-format with at-exp"]|{Using my-format with @-expressions}|

If you're using the functions from @racketmodname[my-format] in @"@-expressions", then there are some
special rules you have to follow for it to work properly.
@itemize[
  @item{The place-fillers must always be on the same line as the place-holders.
        Do not insert newlines in between place-holders and place-fillers.
        If they aren't on the same line, then there will be an extra @racket["\n"] argument
        where there shouldn't be, and then the rest of the place-fillers will be off by one, and the
        last place-filler will be parsed as a format string (which normally wouldn't happen).
        If one of the place-fillers is the string @racket["\n"] and the value of the
        @racket[parse-format-args-warn-about-newline?] parameter is true, @racket[parse-format-args]
        will give a warning about it.}
  @item{Remember that if the place-filler is right next to the place-holder, it should look like
        @code[#:lang "at-exp racket"]|{@-format{... ~v@|value| ...}}|, @bold{@italic{not}}
        @code[#:lang "at-exp racket"]|{@-format{... @~v[value] ...}}|}
]



