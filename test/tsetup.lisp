;; -*- package: clpython.test -*-
;;
;; This software is Copyright (c) Franz Inc. and Willem Broekema.
;; Franz Inc. and Willem Broekema grant you the rights to
;; distribute and use this software as governed by the terms
;; of the Lisp Lesser GNU Public License
;; (http://opensource.franz.com/preamble.html),
;; known as the LLGPL.

;;;; CLPython test harness setup

(defpackage :clpython.test
  (:use :common-lisp :clpython :util.test)
  (:import-from :clpython #:in-syntax)
  (:export #:run))

(in-package :clpython.test)

(defmacro test-true (val &rest options)
  "Only tests first value returned"
  `(test t (not (null ,val)) ,@options))

(defmacro test-false (val &rest options)
  "Only tests first value returned"
  `(test t (not ,val) ,@options))

(defmacro test-equal (&rest args)
  `(test ,@args :test 'equal))

(defvar *test-active* nil)

(defmacro with-subtest (options &body body)
  ;; Enable nesting WITH-TESTS, with total results only being printed once
  ;; at the end.
  `(flet ((run-body () ,@body))
     (if *test-active*
	 (progn (format t "~%[subtest: ~A]" ,(getf options :name))
		(run-body))
       (let ((*test-active* t))
	 (with-tests ,options (run-body))))))

(defun seq-equal (x y &key (test 'eq) ignore)
  "Are X and Y equal sequences (apart from items in IGNORE)"
  (let* ((i2 (coerce ignore 'list))
	 (x2 (set-difference (coerce x 'list) i2 :test test))
	 (y2 (set-difference (coerce y 'list) i2 :test test)))
    (and (null (set-difference x2 y2 :test test))
	 (null (set-difference y2 x2 :test test)))))

(defun seq-member (item seq)
  (not (null (position item seq))))

(defun test-comp-testfunc ()
  "Test the test functions"
  (with-subtest (:name "CLPython-Testfunc")
    (test-false (seq-equal '(a) ()))
    (test-true  (seq-equal '(a) () :ignore #(a)))
    (test-false (seq-equal '(a) '(b)))
    (test-false (seq-equal '(a b) '(b)))
    (test-false (seq-equal #(a b) #(b)))
    (test-true  (seq-equal #(a b) #(b) :ignore '(a)))
    (test-true  (seq-member 'a #(a b)))
    (test-true  (seq-member 'a '(a b)))
    (test-false (seq-member 'a #(b)))
    (test-false (seq-member 'a '(b)))))

(defun run ()
  (with-subtest (:name "CLPython")
    (test-comp-testfunc)
    (run-parser-test)
    (run-compiler-test)
    (run-code-walker-test)
    (run-pretty-printer-test)
    (run-lang-test)))