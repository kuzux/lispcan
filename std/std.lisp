(defmacro_ defmacro (lambda (name args body)
  `(defmacro_ ,name (lambda ,args ,body))))
(defmacro defun (name args body)
  `(define ,name (lambda ,args ,body)))
(defun apply (fn @args) (eval (cons fn args)))

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

(defmacro defstruct (name attrs) 
  (let1 (str (. (ruby Struct) new (vector attrs)))
    `(progn
       (defun (to-sym (+ "make-" (to-str ,name))) (@atts) (. ,str new atts))
       ,(map (lambda (attr) `(defun (to-sym (+ (to-str ,name) (+ "-" ,attr))))) attrs)
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

