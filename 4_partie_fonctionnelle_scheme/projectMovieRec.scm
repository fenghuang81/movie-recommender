#lang scheme

; lecture de csv
(define (read-f filename)
  (call-with-input-file filename
    (lambda (input-port)
      (let loop ((line (read-line input-port)))
        (cond
          ((eof-object? line) '())
          (#t (begin (cons (string-split line ",") (loop (read-line input-port))))))))))

; conversion du csv en liked/notLiked
(define (convert-rating L)
  (list (string->number (car L)) (string->number (cadr L)) (< 3.5 (string->number (caddr L)))))

; Permet de définir la liste Ratings
(define Ratings (map convert-rating (read-f "test.csv")))

; Fonctions auxiliaire
(define (union list1 list2)
  (cond
    ((null? list1) ; list1 est vide
     list2)
    ((member (car list1) list2) ; Saute les doublons
     (union (cdr list1) list2))
    (else
     (cons (car list1) (union (cdr list1) list2)))))

(define (intersection list1 list2)
  (cond
    ((null? list1) ; list1 est vide
     '())
    ((member (car list1) list2)
     (cons (car list1) (intersection (cdr list1) list2)))
    (else
     (intersection (cdr list1) list2))))

(define (similarity user1-id user2-id users)
  (let*
      ((user1 (assoc user1-id users))
       (user2 (assoc user2-id users))
       (liked1 (cadr user1))
       (liked2 (cadr user2))
       (disliked1 (caddr user1))
       (disliked2 (caddr user2))

       (liked-both (intersection liked1 liked2 ))
       (disliked-both (intersection liked1 liked2))
       (watched-both (union (union liked1 disliked1)
                            (union liked2 disliked2))))
    (exact->inexact (/ (+ (length liked-both) (length disliked-both)) (length watched-both)))))

(similarity 1 31 '((1  (260 235 231 216 163 157 151 110 101 50 47 6 3 1) (223 70)) (31 (367 362 356 349 333 260 235 231) (316 296 223)))    )

; Exemple pour la fonction add-rating
; > (add-rating '(31 316 #f) (add-rating '(31 333 #t) '()))
; ((31 (333) (316)))
; > (add-rating '(31 362 #t) (add-rating '(31 316 #f) (add-rating '(31 333 #t) '())))
; ((31 (362 333) (316)))

; Exemple pour la fonction add-ratings

; > (add-ratings '((3 44 #f) (3 55 #f) (3 66 #t) (7 44 #f) (3 11 #t) (7 88 #t)) '())
; ((3 (11 66) (55 44)) (7 (88) (44)))

; > (add-ratings Ratings '())
; ((1 (260 235 231 216 163 157 151 110 101 50 47 6 3 1) (223 70))
;  (31 (367 362 356 349 333 260 235 231) (316 296 223)))

; Exemple pour la fonction add-user

; > (get-user 31 (add-ratings Ratings '()))
; (31 (367 362 356 349 333 260 235 231) (316 296 223))

; finalement
; (get-similarity 1 31)