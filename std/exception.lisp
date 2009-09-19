(defmacro make-exception-expr (exc)
  (if (cons? exc) (list '::: exc) (list 'ruby exc)))
(defmacro try (code exc rescue)
  `(try_ ,code (make-exception-expr ',exc) ,rescue))

