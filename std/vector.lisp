(defmacro vector (lst)
  `(. (ruby Array) from_cons
    ',(map (lambda (x) (eval x)) lst)))

(defmacro quoted-vector (lst) `(. (ruby Array) from_cons ',lst))

(defun make-vector (fn n) (. (ruby Array) new n fn))
(defun vector-push (vec elem) (. vec push elem))
(defun vector-pop (vec) (. vec pop))
(defun vector-len (vec) (. vec length))
(defun vector-get (ind vec) (. vec "[]" ind))

(defun vector-do (fn vec) (. vec each fn))
(defun vector-map (fn vec) (. vec map fn))
(defun vector-filter (fn vec) (. vec select fn))
(defun vector-sort (vec) (. vec sort))
(defun vector-reduce (fn acc vec) (. vec inject acc fn))
(define vector-fold vector-reduce)
