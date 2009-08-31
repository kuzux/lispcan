(defmacro hash-new () `(. (ruby Hash) new))
(defun hash-get (key hash) (. hash "[]" key))
(defun hash-set (key val hash) (. hash "[]=" key val))

(defun hash-do (fn hash) (. hash each fn))
(defun hash-dokeys (fn hash) (. hash each_key fn))
(defun hash-dovals (fn hash) (. hash each_value fn))

(defun hash-has? (key hash) (. hash has_key? key))
(defun hash-empty? (hash) (. hash empty?))
(defun hash-len (hash) (. hash length))
