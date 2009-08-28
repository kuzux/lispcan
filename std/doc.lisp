(define *documentation_* (hash-new))
(defun document-fn (fns doc) 
  (if (atom? fns) 
    (hash-set fns doc *documentation_*)
    (map (\ (n) (hash-set n doc *documentation_*)) fns)))
    
(defun doc (fn) `(,fn : ,(hash-get fn *documentation_*)))
(define help doc)

(document-fn 'document-fn "(fns doc) => Document the function/list of functions fns with the docstring doc")
(document-fn '(doc help) "(fn) => learn about the function fn")
