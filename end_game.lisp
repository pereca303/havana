#!/usr/bin/clisp

(load "creator.lisp")
(load "move.lisp")
(load "printer.lisp")

; ==============================================================================

(setf corners (cons (list '0 '0) ; upper left
                (cons (list '0 (1- (get_mat_dim matrix))) ; upper right
                    (cons (list (1- (get_mat_dim matrix)) '0) ; middle left
                          (cons (list (1- (get_mat_dim matrix)) (- (* 2 (get_mat_dim matrix)) 2)) ; middle right
                                (cons (list (- (* 2 (get_mat_dim matrix)) 2) (1- (get_mat_dim matrix))) ; lower left
                                      (cons (list (- (* 2 (get_mat_dim matrix)) 2) (- (* 2 (get_mat_dim matrix)) 2)) '())))))));lower right

; ==============================================================================
(defun go_down_left (start end)
  (cond ((equal start end) '())
        (t (cons start (go_down_left (list (+ 1 (car start)) (cadr start)) end)))))

(setf upper_left_wall (go_down_left '(1 0) (list (- (get_mat_dim matrix) 1) 0)))
(setf down_right_wall (go_down_left (list (get_mat_dim matrix) (* 2 (- (get_mat_dim matrix) 1))) (list (* 2 (- (get_mat_dim matrix) 1)) (* 2 (- (get_mat_dim matrix) 1)))))

(defun go_down_right (start end)
  (cond ((equal start end) '())
        (t (cons start (go_down_right (list (+ 1 (car start)) (+ 1 (cadr start))) end)))))

(setf upper_right_wall (go_down_right (list 1 (get_mat_dim matrix)) (list (- (get_mat_dim matrix) 1) (* 2 (- (get_mat_dim matrix) 1)))))
(setf down_left_wall (go_down_right (list (get_mat_dim matrix) 1) (list (* 2 (- (get_mat_dim matrix) 1)) (- (get_mat_dim matrix) 1))))

(defun go_right (start end)
  (cond ((equal start end) '())
        (t (cons start (go_right (list (car start) (+ 1 (cadr start))) end)))))

(setf upper_wall (go_right (list 0 1) (list 0 (- (get_mat_dim matrix) 1))))
(setf down_wall (go_right (list (* 2 (- (get_mat_dim matrix) 1)) (get_mat_dim matrix)) (list (* 2 (- (get_mat_dim matrix) 1)) (* 2 (- (get_mat_dim matrix) 1)))))

; ==============================================================================

(defun row_coordinates(index row)
  (cond
    ((null row) '())
    (t (progn
         (cons (list index (caar row)) (row_coordinates index (cdr row)))))))

(defun side_coordinates (row_index)
  (if (< row_index (* 2 (1- (get_mat_dim matrix))))
    (let* (
            (row (cadr (get_row row_index)))
            (first_index (car (first row)))
            (last_index (car (car (last row))))) ; last returns '(last_element) -> (car (last list)) = last_element
          (append (list (list row_index first_index) (list row_index last_index)) (side_coordinates (1+ row_index))))
    '()))

(setf sides (let (
                  (top (row_coordinates 0 (cadr (get_row 0))))
                  (bottom (row_coordinates (* 2 (1- (get_mat_dim matrix ))) (cadr (get_row (* 2 (1- (get_mat_dim matrix)))))))
                  (left_right (side_coordinates 1)))
              (append top left_right bottom)))

; ==============================================================================

; vraca T ako za prosledjeni simbol postoji bridge
(defun check_bridge (symbol)
    (has_bridge (fields_with_symbol symbol corners)))

;vraca T ukoliko postoji put izmedju bilo koja 2 cornera iz skupa
(defun has_bridge(ls)
  (cond ((null ls) '())
        ((equalp (length ls) 1) '())
        (t (if (null (bridge_traversal (list (car ls)) (cdr ls) '()))
             (has_bridge (cdr ls))
             't))))

;filtirira listu i ostavlja samo elemente prosledjenog simbola
(defun fields_with_symbol (symbol ls)
  (cond
    ((null ls) '())
    (t (if (equalp (cadr (get_element (car (car ls))(cadr (car ls)))) symbol)
          (cons (car ls) (fields_with_symbol symbol (cdr ls)))
         (fields_with_symbol symbol (cdr ls))))))

;filtrira listu i ostavlja samo elemente proslednjenog simbola
(defun fields_without_symbol (symbol ls)
  (cond
    ((null ls) '())
    (t (if (not (equalp (cadr (get_element (car (car ls))(cadr (car ls)))) symbol))
          (cons (car ls) (fields_without_symbol symbol (cdr ls)))
         (fields_without_symbol symbol (cdr ls))))))

;vraca listu suseda prosledjenog polja
(defun get_neighbours(row column)
  (if (or (null row) (null column))
    (princ (list "ne radi za1: " row column)); invalid coordinates
    (append (return_if_valid (1- row) (1- column)) ; upper left
          (append (return_if_valid (1- row) column) ; upper right
                (append (return_if_valid row (1- column)) ; left
                      (append (return_if_valid row (1+ column)) ; right
                            (append (return_if_valid (1+ row) column) ; lower left
                                  (append (return_if_valid (1+ row) (1+ column)) '())))))))) ; lower riht

;proverava da li su koordinate validne i ako jesu, vraca ih
(defun return_if_valid(row column)
  (if (and (and (>= row 0) (<= row (* 2 (1- (get_mat_dim matrix)))))
       (and (>= column (car (get_range row (get_mat_dim matrix)))) (< column (cadr (get_range row (get_mat_dim matrix))))))
    (list (list row column))))

;nalazi susede start-a sa istim znakom
(defun add_neighbours (start visited)
  (new_nodes (fields_with_symbol (cadr (get_element (car start) (cadr start))) (get_neighbours (car start) (cadr start))) visited))

;dodaje susede start-a koji nemaju isti znak
(defun add_not_neighbours (start visited)
  (new_nodes (fields_without_symbol (cadr (get_element (car start) (cadr start))) (get_neighbours (car start) (cadr start))) visited))

;dodaje elemente start-a koji nisu jednaki symbol-u
(defun add_others (start visited symbol)
  (new_nodes (fields_without_symbol symbol (get_neighbours (car start) (cadr start))) visited))

;vraca listu suseda koji vec nisu poseceni
(defun new_nodes (neighbours visited)
  (cond ((null neighbours) '())
        ((member (car neighbours) visited :test 'equalp)
         (new_nodes (cdr neighbours) visited))
        (t (cons (car neighbours) (new_nodes (cdr neighbours) visited)))))

; ==============================================================================

;ako se neki element prve liste, nalazi u drugoj => T else '()
(defun compare_lists(startList endList)
  (cond ((null startList) '())
        (t (if (member (car startList) endList :test 'equalp) (car startList) (compare_lists (cdr startList) endList)))))


;vratice T ako postoji put od start polja do nekog od end polja
(defun bridge_traversal (start end visited)
  (cond
    ((compare_lists start end) 't)
    ((null start) '())
    (t (let* ((visited1 (cons (car start) visited))
              (neighbours (add_neighbours (car start) (append start visited1)))
              (start1 (append (cdr start) neighbours))
              (is_connected (bridge_traversal start1 end visited1)))
            is_connected))))


; ==============================================================================

(defun check_fork(played)
    (if (>= (number_of_walls_hit (get_fork_tree played)) 3) 't '()))

(defun get_fork_tree (played)
    (fork_traversal (list played) '()))

(defun fork_traversal (start visited)
    (cond ((null start) visited)
          (t (let* ((visited1 (cons (car start) visited))
                    (neighbours (add_neighbours (car start) (append start visited1)))
                    (start1 (append (cdr start) neighbours))
                    (tree (fork_traversal start1 visited1)))
                  tree))))


(defun number_of_walls_hit (ls)
    (let ((ul (if (null (compare_lists ls upper_left_wall)) '0 '1))
          (ur (if (null (compare_lists ls upper_right_wall)) '0 '1))
          (u (if (null (compare_lists ls upper_wall)) '0 '1))
          (dl (if (null (compare_lists ls down_left_wall)) '0 '1))
          (dr (if (null (compare_lists ls down_right_wall)) '0 '1))
          (d (if (null (compare_lists ls down_wall)) '0 '1)))
        (+ ul ur u dl dr d)))

; ==============================================================================

(defun check_ring(played)
    (or (check_surroundings (fields_with_symbol (cadr (get_element (car played) (cadr played))) (get_neighbours (car played) (cadr played))) (cadr (get_element (car played) (cadr played))))
        (has_ring (fields_without_symbol (cadr (get_element (car played) (cadr played))) (get_neighbours (car played) (cadr played))) (cadr (get_element (car played) (cadr played))))))


(defun has_ring (ls symbol)
  (cond ((null ls) '())
        (t (or (ring_traversal (list (car ls)) '() symbol) (has_ring (cdr ls) symbol)))))

; prolazi kroz polja koja nisu symbol i vraca true sve dok se ne naidje na list
(defun ring_traversal (start visited symbol)
    (cond ((null start) t)
          ((member (car start) sides :test 'equalp)  '())
          (t (let* ((visited1 (cons (car start) visited))
                    (neighbours (add_others (car start) (append start visited1) symbol))
                    (start1 (append (cdr start) neighbours))
                    (ring (ring_traversal start1 visited1 symbol)))
                  ring))))

(defun check_surroundings(neighbours symbol)
  (cond ((null neighbours) '())
        (t (or (= 6 (symbol_counter (get_neighbours (caar neighbours) (cadar neighbours)) symbol)) (check_surroundings (cdr neighbours) symbol)))))

(defun symbol_counter(ls symbol)
  (cond ((null ls) '0)
        ((equalp symbol (cadr (get_element (caar ls) (cadar ls)))) (+ 1 (symbol_counter (cdr ls) symbol)))
        (t (symbol_counter (cdr ls) symbol))))

; (make_move 'X  '0 (1- (get_mat_dim matrix))) ; 0 5
; (make_move 'O (1- (get_mat_dim matrix)) '0) ; 5 0
; (make_move 'X (1- (get_mat_dim matrix)) (- (* 2 (get_mat_dim matrix)) 2)) ; 5 10
; (make_move 'X (- (* 2 (get_mat_dim matrix)) 2) (1- (get_mat_dim matrix))) ; 10 5
; (make_move 'O (- (* 2 (get_mat_dim matrix)) 2) (- (* 2 (get_mat_dim matrix)) 2)) ; 10 10

; (make_move 'O '0 '0) ; 0 0
; (make_move 'O '1 '1)
; (make_move 'X '2 '2)
; (make_move 'X '3 '3)
; (make_move 'X '4 '4)
;
; (make_move 'O '0 '2)
; (make_move 'O '1 '2)
;
; (make_move 'X '2 '1)
; (make_move 'X '2 '0)
;
; (make_move 'X '3 '3)
; (make_move 'X '4 '3)
;
; (make_move 'O '9 '5)
;
; (make_move 'X '10 '6)


; (make_move 'O '7 '3)
;
;(make_move 'X '5 '4)
;(make_move 'X '6 '3)
;(make_move 'X '6 '4)
;(make_move 'X '6 '5)
;(make_move 'X '6 '6)
;(make_move 'X '7 '2)
;(make_move 'X '7 '5)
;(make_move 'X '7 '6)
;(make_move 'X '7 '7)
;(make_move 'X '7 '8)
;(make_move 'X '5 '5);
;(make_move 'X '7 '9)
;(make_move 'X '8 '10)
;(make_move 'X '8 '5)
;(make_move 'X '6 '7)
;(make_move 'X '5 '7)
;(make_move 'X '5 '8)
;(make_move 'X '5 '9)
;(make_move 'X '6 '10)
;(make_move 'X '7 '10)
;(make_move 'X '5 '6)
;(make_move 'X '4 '3)
;(make_move 'X '3 '3)
;(make_move 'X '3 '4)
;(make_move 'X '3 '5)
;(make_move 'X '3 '6)
;(make_move 'X '4 '7)
;(print_matrix)
;(trace check_surroundings)
;(trace check_surroundings)
;(trace check_ring)
;(princ (check_ring (list '5 '6)))
