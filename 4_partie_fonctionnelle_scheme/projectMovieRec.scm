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
; Renvoie l'union de deux listes (On suppose que les deux listes sont des ensembles)
; list1 : une liste
; list2 : une liste
; -> une liste
(define (union list1 list2)
  (cond
    ((null? list1) ; list1 est vide
     list2)
    ((member (car list1) list2) ; Saute les doublons
     (union (cdr list1) list2))
    (else
     (cons (car list1) (union (cdr list1) list2)))))

; Renvoie l'intersection de deux listes (On suppose que les deux listes sont des ensembles)
; list1 : une liste
; list2 : une liste
; -> une liste
(define (intersection list1 list2)
  (cond
    ((null? list1) ; list1 est vide
     '())
    ((member (car list1) list2)
     (cons (car list1) (intersection (cdr list1) list2)))
    (else
     (intersection (cdr list1) list2))))

; Calcule la similarité entre deux personnes à partir d'une liste d'utilisateurs
; user1-id
; user2-id
; users : liste d'utilisateurs
; -> nombre réel
(define (similarity user1-id user2-id users)
  (let*
      ((user1 (assoc user1-id users))
       (user2 (assoc user2-id users))
       (liked1 (cadr user1))
       (liked2 (cadr user2))
       (disliked1 (caddr user1))
       (disliked2 (caddr user2))

       (liked-both (intersection liked1 liked2))
       (disliked-both (intersection disliked1 disliked2))
       (watched-both (union (union liked1 disliked1)
                            (union liked2 disliked2))))
    (exact->inexact (/ (+ (length liked-both) (length disliked-both)) (length watched-both)))))

; Exemple
(similarity 1 31 '((1  (260 235 231 216 163 157 151 110 101 50 47 6 3 1) (223 70)) (31 (367 362 356 349 333 260 235 231) (316 296 223)))    )


; Ajoute un nouveau film à la liste courante d'utilisateurs.
; Si le rating est pour un nouveau utilisateur, cet utilisateur est créé et ajouté à la liste.
; rating
; users : liste d'utilisateurs
; -> liste
(define (add-rating rating users)
  (let*
      ((user-id (car rating))
       (movie (cadr rating))
       (liked? (caddr rating))
       (user (assoc user-id users))
       (other-users (filter (lambda (u) (not (equal? (car u) user-id))) users)))
    ; Si l'utilisateur existe
    (if user
        ; Met à jour l'utilisateur
        (let update ((remaining users) ; Les utilisateurs après user
                     (before '())) ; Les utilisateurs avant user
          (cond ((null? remaining) users)
                ; Trouvé l'utilisateur
                ((equal? (caar remaining) user-id)
                 ; append(before, updated, remaining)
                 (append
                  (reverse before)
                  (list (list user-id
                              (if liked?
                                  (cons movie (cadr user))
                                  (cadr user))
                              (if (not liked?)
                                  (cons movie (caddr user))
                                  (caddr user))))
                  (cdr remaining)))
                (else
                 ; Continue à chercher l'utilisateur
                 (update (cdr remaining) (cons (car remaining) before)))))
        ; Créer un nouvel utilisateur
        (append users (list (list user-id
                                  (if liked? (list movie) '())
                                  (if (not liked?) (list movie) '())))))))

; Exemple pour la fonction add-rating
(equal? (add-rating '(31 316 #f) (add-rating '(31 333 #t) '())) '((31 (333) (316))))
(equal? (add-rating '(31 362 #t) (add-rating '(31 316 #f) (add-rating '(31 333 #t) '()))) '((31 (362 333) (316))))


; Ajoute toutes les évaluations dans une liste à la liste courante des utilisateurs
; ratings : liste de ratings
; users : liste d'utilisateurs
(define (add-ratings ratings users)
  ; Si vide ne change pas
  (if (null? ratings)
      users
      (add-ratings
       (cdr ratings)
       (add-rating (car ratings) users))))

; Exemple pour la fonction add-ratings
(equal? (add-ratings '((3 44 #f) (3 55 #f) (3 66 #t) (7 44 #f) (3 11 #t) (7 88 #t)) '()) '((3 (11 66) (55 44)) (7 (88) (44))))
(equal? (add-ratings Ratings '()) '((1 (260 235 231 216 163 157 151 110 101 50 47 6 3 1) (223 70)) (31 (367 362 356 349 333 260 235 231) (316 296 223))))


; Retourne l'utilisateur et sa liste de films aimé et non aimé
; user-id
; users : liste d'utilisateurs
(define (get-user user-id users)
  (cond
    ; Liste vide
    ((null? users) '()) ;
    ; Trouvé
    ((equal? (caar users) user-id) (car users))
    ; Continue à chercher
    (else (get-user user-id (cdr users)))))

; Exemple pour la fonction get-user
(equal? (get-user 31 (add-ratings Ratings '())) '(31 (367 362 356 349 333 260 235 231) (316 296 223)))


; Retourne la similarité entre deux utilisateurs
(define (get-similarity user1-id user2-id)
  (similarity user1-id user2-id (add-ratings Ratings '())))

; finalement
(get-similarity 1 31)