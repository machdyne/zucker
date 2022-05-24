; Lone Lisp Standard Library
; Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.

(begin

(define quit exit)

(define f '())

(defun null (x)
	(eq x '()))

(defun and (x y)
	(cond (x (cond (y 't) ('t '()))) ('t '())))

(defun or (x y)
	(cond (x 't) (y 't) ('t '())))

(defun not (x)
	(cond (x '())
		('t 't)))

(defun append (x y)
	(cond ((null x) y)
		('t (cons (car x) (append (cdr x) y)))))

(defun pair (x y)
	(cond ((and (null x) (null y)) '())
		((and (not (atom? x)) (not (atom? y)))
		(cons (list (car x) (car y))
			(pair (cdr x) (cdr y))))))

(defun assoc (x y)
	(cond ((eq (caar y) x) (cadar y))
		('t (assoc x (cdr y)))))

(define eq? eq)
(define eqv? eqv)
(define #t 't)
(define #f '())
(define else 't)
(define null? nil?)

(define first car)
(define rest cdr)

(define last (lambda (l) (list-ref l (- (length l) 1))))

(define nil? (lambda (x)
	(eq x '())))

(define append (lambda (x y)
   (cond ((nil? x) y)
      (#t (cons (car x) (append (cdr x) y))))))

(define length (lambda (l)
	(if (nil? l) 0
		(+ 1 (length (rest l))))))

(define list-length length)

(define (reverse l)
	(if (nil? l)
		'()
		(append (reverse (cdr l))
			(list (car l)))))

(define list-ref (lambda (l i)
	(if (= i 0)
		(first l)
		(list-ref (rest l) (- i 1)))))

(define list-eq? (lambda (la lb a b)
	(cond
		((not (eq (length la) (length lb))) #f)
		((not (eq a b)) #f)
		((and (nil? la) (nil? lb)) #t)
		('t (list-eq? (cdr la) (cdr lb) (car la) (car lb))))))

(define range (lambda (a b)
	(cond
		((>= a b) '())
		((< a b) (cons a (range (+ a 1) b))))))

(defun member? (l x)
	(cond
		((nil? l) '())
		((eq? (car l) x) 't)
		('t (member? (cdr l) x))))

(defun count (l x a)
	(cond
		((nil? l) a)
		((eq? (car l) x) (count (cdr l) x (+ 1 a)))
		('t (count (cdr l) x a))))

(define map (lambda (f x)
	(if (nil? x) '()
		(cons (f (car x)) (map f (cdr x))))))

(define reduce (lambda (f a l)
	(if (nil? l)
		a
		(reduce f (f a (car l)) (cdr l)))))

(define filter (lambda (pred l)
	(cond
		((nil? l) (list))
		((pred (first l))
			(cons (first l) (filter pred (rest l))))
		(#t (filter pred (rest l))))))

(define remove (lambda (pred l)
	(cond
		((nil? l) (list))
		((not (pred (first l)))
			(cons (first l) (remove pred (rest l))))
		(#t (remove pred (rest l))))))

(define flatten (lambda (x)
	(cond
		((nil? x) '())
		((not (pair? x)) (list x))
		(else (append (flatten (car x))
			(flatten (cdr x)))))))

(define for-each (lambda (f l)
	(if (nil? (rest l))
		(f (first l))
		(begin
			(f (first l))
			(for-each f (rest l))))))

(define sort (lambda (l)
	(if (nil? (cdr l))
		l
		(let ((pv (car l)) (nl (cdr l)) (less (list)) (great (list)))
			(begin
				(for-each (lambda (x)
					(if (<= x pv)
						(set! less (append less (list x)))
						(set! great (append great (list x))))) nl)
				(append (sort less) (append (list pv) (sort great))))))))

(define max (lambda (l) (last (sort l))))
(define min (lambda (l) (first (sort l))))
(define number? num?)

(defun zero? (x) (if (= x 0) #t #f))
(defun positive? (x) (if (> x 0) #t #f))
(defun negative? (x) (if (< x 0) #t #f))
(defun odd? (x) (if (= (% x 2) 1) #t #f))
(defun even? (x) (if (= (% x 2) 0) #t #f))

(defun abs (x) (if (< x 0) (* -1 x) x))

(defun floor (x) (- x (% x 1)))
(defun ceil (x) (+ (- x (% x 1)) 1))

(defun round (x)
   (cond
      ((>= (% x 1) 0.5) (ceil x))
      ((< (% x 1) 0.5) (floor x))))

)
