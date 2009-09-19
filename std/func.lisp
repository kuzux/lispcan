(defun flip (fn) (lambda (a1 a2) (fn a2 a1)))
(defmacro curry (fn arg) `(lambda (x) (,fn (cons ,arg (list x)))))

(defun foldr (fn end lst)
  (if (nil? lst)
      end
      (fn (car lst) (foldr fn end (cdr lst)))))
(defun foldl (fn acc lst)
  (if (nil? lst)
      acc
      (foldl fn (fn acc (car lst)) (cdr lst))))
(define fold foldl)
(define reduce fold)
(defun unfold (func init pred)
  (if (pred init)
      (cons init '())
      (cons init (unfold func (func init) pred))))

(defun sum (lst) (fold + 0 lst))
(defun product (lst) (fold * 1 lst))

(defun reverse (lst) (fold (flip cons) '() lst))
(defun map (fn lst)
  (foldr (lambda (x acc)
    (cons (fn x) acc)) '() lst))
(defun filter (fn lst)
  (foldr
    (lambda (x acc)
      (if (fn x)
          (cons x acc)
          acc))
    '() lst))

(defun min (lst) (fold (\ (old new) (if (< old new) old new)) (car lst) (cdr lst)))
(defun max (lst) (fold (\ (old new) (if (> old new) old new)) (car lst) (cdr lst)))
