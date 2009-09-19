(. (ruby Kernel) require "readline")
(. (Ruby Readline) completion_proc=
   (\ (start) (+ 
			(.. *interpreter* env (all_keys (\ (x) (match? (to-str x) (regexp (esc-regexp start))))))
			(.. *interpreter* forms (all_keys (\ (x) (match? (to-str x) (regexp (esc-regexp start)))))))))

(do (define *line* (. (ruby Readline) readline "> " t))
    (try (print (. (eval *line*) to_sexp))
		     StandardError
				 (progn (print (+ "ERROR: " (to-str *exception*)))
				        (print (to-sexp (. *interpreter* stack_trace))))))
