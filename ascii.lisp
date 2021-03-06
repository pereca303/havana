(setq ascii '(A B C D E F G H I J K L M N O P Q R S #\T U V W X Y Z))

(defun get_ascii(index)
  (cond
    ((> index 26) '())
    ((< index 0) '())
    (t (nth index ascii))))

(defun get_number(ascii)
  (cond
    ((null ascii) '())
    (t (- (char-code (character ascii)) 65))))
