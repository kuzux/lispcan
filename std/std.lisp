(defmacro_ defmacro (lambda_ (name args body)
  `(defmacro_ ,name (lambda_ ,args ,body))))
(defmacro defun (name args body)
  `(define ,name (lambda_ ,args ,body)))
(defun apply (fn @args) (eval (cons fn args)))

(define t 't)
(define nil 'nil)

(defun list (@lst) (if (= (cdr lst) nil) (car lst) lst))

(defmacro set! (lhs rhs)
  (if (cons? lhs)
    (cond
      ((= (car lhs) '+) `(set! ,(cadr lhs) (- ,rhs ,(caddr lhs))))
      ((= (car lhs) '-) `(set! ,(cadr lhs) (+ ,rhs ,(caddr lhs))))
      ((= (car lhs) '*) `(set! ,(cadr lhs) (/ ,rhs ,(caddr lhs))))
      ((= (car lhs) '/) `(set! ,(cadr lhs) (* ,rhs ,(caddr lhs))))
      ((= (car lhs) 'sqrt) `(set! ,(cadr lhs) (* ,rhs ,rhs)))
      ((= (car lhs) 'sin) `(set! ,(cadr lhs) (asin ,rhs)))
      ((= (car lhs) 'cos) `(set! ,(cadr lhs) (acos ,rhs)))
      ((= (car lhs) 'tan) `(set! ,(cadr lhs) (atan ,rhs)))
      ((= (car lhs) 'car) `(rplaca! ,(cadr lhs) ,rhs)))
    `(set_ ,lhs ,rhs)))

(defmacro \ (args code) `(lambda ,args ,code))
(defmacro progn (@code) `(eval ',code))

(defmacro let1 (binding body)
  `((lambda 
     (,(car binding)) ,body)
  ,(car (cdr binding))))
(defmacro let (bindings body)
  (foldr
    (lambda (binding acc)
      `(let1 ,binding ,acc))
    body bindings))

(defun .. (init @msgs)
  (foldr (lambda (msg acc)
    (cons '. (cons (acc msg)))) init msgs))

(defun read-file (filename) (. (ruby File) read filename))
(defun parse (str) (. *interpreter_* parse str))
(defun load (filename) (. *interpreter_* load_file filename))

(load "math.lisp")
(load "comp.lisp")
(load "list.lisp")
(load "func.lisp")
(load "vector.lisp")
(load "hash.lisp")
(load "doc.lisp")
(load "conv.lisp")

(defun defstruct (name attrs)
  (let1 (str (. (ruby Struct) new (vector attrs)))
    `(progn
       (defun (to-sym (+ "make-" (to-str ,name))) (@atts) (. ,str new atts))
       ,(map (\ (attr) `(defun (to-sym (+ (to-str ,name) (+ "-" ,attr))))) attrs)
       (defun (to-sym (+ "is-" (+ ,name "?"))) (x) (= (. x class) str)))))

(defun regexp (rx) (. (ruby Regexp) new rx))
(defun match? (str regex) (. str =~ regex))
(defun sub (str regex rep) (. str sub regex rep))
(defun gsub (str regex rep) (. str gsub regex rep))

(defun range (begin end) (. (ruby Range) new begin end))

(defun print1 (arg) (. (ruby Kernel) puts arg))
(defun print (@args) (. (ruby Kernel) puts (. args arrayify)))
(defun gets () (. (ruby STDIN) gets))

(defun exit () (. (ruby Kernel) exit))
(define quit exit)

