;;; test-once-fixes.el --- Tests for the once fixes -*- lexical-binding: t; -*-

;; Copyright (c) 2026, Qingshui Zheng

;; Author: Qingshui Zheng <qingshuizheng@outlook.com>
;; Maintainer: Qingshui Zheng <qingshuizheng@outlook.com>
;; URL: https://github.com/qingshuizheng/once

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Behaviour tests for the fixes that used to live in the now deleted
;; `once-patches' layer and are folded into the once sources: the
;; `:initial-check'/`:check' split in once.el, plus the cases of the
;; incremental pass that do not depend on an item being interrupted.  The
;; tests exercise `once' directly and the drone root is expected on
;; `load-path'.
;;
;; Note: this file is ERT while the rest of tests/ uses buttercup, so it is
;; run from the drone root with `ert-run-tests-batch-and-exit' after the
;; drone root is put on `load-path'.
;;
;; The check tests are the discriminating ones:
;; `test-once-fixes-later-trigger-uses-check-not-initial-check' fails against
;; the unpatched definition, which is the whole point of the fix.  Every
;; expected value was read off a real `emacs -Q --batch' run.

;;; Code:
(require 'ert)
(require 'cl-lib)

(require 'once)
(require 'once-incrementally)

(defmacro test-once-fixes--with-captured-timers (timers &rest body)
  "Run BODY with `run-at-time' captured into TIMERS.
TIMERS is set to the list of (DELAY FUNCTION) pairs that BODY scheduled,
in scheduling order; no real timer is created."
  (declare (indent 1) (debug (symbolp body)))
  `(setq ,timers
         (let (collected)
           (cl-letf (((symbol-function 'run-at-time)
                      (lambda (delay _repeat function &rest _args)
                        (push (list delay function) collected))))
             ,@body)
           (nreverse collected))))

;;; Fix 1: `:initial-check' must not shadow the later `:check'.
;;
;; The buggy upstream code was `(let ((check (or initial-check check))) ...)',
;; so with both given, the *initial* check was also used on every later
;; trigger.  The idiom
;;
;;   (once (list :check #'ready-p :initial-check (lambda () nil)) ...)
;;
;; therefore never ran.  These tests observe which check reaches
;; `once--call-later', which is exactly what the fix changes.

(ert-deftest test-once-fixes-later-trigger-uses-check-not-initial-check ()
  (let* ((initial-check (lambda () nil))
         (check (lambda () t))
         (function (lambda () nil))
         (captured 'not-called))
    (cl-letf (((symbol-function 'once--call-later)
               (lambda (_function _hooks _advise _packages _variables
                                  &optional check)
                 (setq captured check))))
      (once--call-now-or-later function nil nil nil nil initial-check check))
    (should (eq captured check))
    (should-not (eq captured initial-check))))

(ert-deftest test-once-fixes-single-check-is-used-for-both-phases ()
  (let* ((check (lambda () nil))
         (function (lambda () nil))
         (captured 'not-called))
    (cl-letf (((symbol-function 'once--call-later)
               (lambda (_function _hooks _advise _packages _variables
                                  &optional later)
                 (setq captured later))))
      (once--call-now-or-later function nil nil nil nil nil check))
    (should (eq captured check)))
  (let* ((initial-check (lambda () nil))
         (function (lambda () nil))
         (captured 'not-called))
    (cl-letf (((symbol-function 'once--call-later)
               (lambda (_function _hooks _advise _packages _variables
                                  &optional later)
                 (setq captured later))))
      (once--call-now-or-later function nil nil nil nil initial-check nil))
    (should (eq captured initial-check))))

(ert-deftest test-once-fixes-runs-now-when-the-initial-check-passes ()
  (let ((ran nil))
    (once--call-now-or-later (lambda () (setq ran t)) nil nil nil nil
                             (lambda () t)
                             (lambda () nil))
    (should ran)))

(ert-deftest test-once-fixes-runs-now-only-when-a-listed-package-is-loaded ()
  (let ((ran nil))
    (once--call-now-or-later (lambda () (setq ran t)) nil nil
                             '((cl-lib)) nil nil nil)
    (should ran))
  (let ((ran nil))
    (once--call-now-or-later (lambda () (setq ran t)) nil nil
                             '((test-once-fixes--absent-feature)) nil nil nil)
    (should-not ran)))

;;; The incremental pass must not requeue a finished item, and it must wait
;;; until it has been idle long enough.

(ert-deftest test-once-fixes-incremental-completed-item-is-not-requeued ()
  (let* ((item (list :function (lambda () nil)))
         (once--incremental-code (list item))
         (once-idle-timer 7.0)
         (once-incremental-run-interval 0.5)
         (ran nil)
         timers)
    (test-once-fixes--with-captured-timers timers
      (cl-letf (((symbol-function 'current-idle-time) (lambda () '(0 10)))
                ((symbol-function 'once--run) (lambda (_item) (setq ran t) t)))
        (once--run-incrementally)))
    (should ran)
    (should-not once--incremental-code)
    (should (equal timers
                   (list (list 0.5 #'once--run-incrementally))))))

(ert-deftest test-once-fixes-incremental-waits-when-not-idle-long-enough ()
  (let* ((item (list :function (lambda () nil)))
         (once--incremental-code (list item))
         (once-idle-timer 7.0)
         (once-incremental-run-interval 0.5)
         (ran nil)
         timers)
    (test-once-fixes--with-captured-timers timers
      (cl-letf (((symbol-function 'current-idle-time) (lambda () nil))
                ((symbol-function 'once--run) (lambda (_item) (setq ran t) t)))
        (once--run-incrementally)))
    (should-not ran)
    (should (equal once--incremental-code (list item)))
    (should (equal timers
                   (list (list 7.0 #'once--run-incrementally))))))

(ert-deftest test-once-fixes-incremental-already-loaded-feature-is-not-requeued ()
  ;; The skip loop leaves the popped item bound, so `once--run' is still called
  ;; on it (a no-op for an already loaded `:feature'); what the fix has to
  ;; guarantee is only that it is not put back and that the pass continues at
  ;; the short interval rather than the idle timer.
  (let* ((item (list :feature 'cl-lib))
         (once--incremental-code (list item))
         (once-idle-timer 7.0)
         (once-incremental-run-interval 0.5)
         timers)
    (test-once-fixes--with-captured-timers timers
      (cl-letf (((symbol-function 'current-idle-time) (lambda () '(0 10))))
        (once--run-incrementally)))
    (should-not once--incremental-code)
    (should (equal timers
                   (list (list 0.5 #'once--run-incrementally))))))

(provide 'test-once-fixes)
;;; test-once-fixes.el ends here
