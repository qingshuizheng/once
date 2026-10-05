;;; test-once-conditions.el --- Tests for once-conditions -*- lexical-binding: t; -*-

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
;; Behaviour tests for the predefined `once' conditions.
;;
;; Note: this file is ERT while the rest of tests/ uses buttercup, so it is
;; run from the drone root with `ert-run-tests-batch-and-exit' after the
;; drone root and once-conditions/ are put on `load-path'.
;;
;; `once-conditions' lives in once-conditions/ inside the drone and needs the
;; drone root on `load-path' for `once' itself.
;;
;; Every expected value below was read off a real `emacs -Q --batch' run
;; before it was written down.

;;; Code:
(require 'ert)
(require 'cl-lib)

(require 'once-conditions)

;; `dired-initial-position-hook' is defined in dired, which the test below
;; loads; declaring it special here is what makes the `let' that binds it a
;; dynamic binding, so `run-hooks' can see it.
(defvar dired-initial-position-hook)

;; `server-after-make-frame-hook' is defined in server.el and
;; `dired-use-ls-dired' in dired, both of which the tests below load.  They
;; are declared here for the same reason as `dired-initial-position-hook'.
(defvar server-after-make-frame-hook)
(defvar dired-use-ls-dired)

(ert-deftest once-conditions-loads ()
  (should (featurep 'once-conditions)))

(ert-deftest once-conditions-defines-its-api ()
  (dolist (var '(once-evil-insert-states
                 once-startup-finished-p
                 once-init
                 once-gui
                 once-tty
                 once-input
                 once-buffer
                 once-file
                 once-writable
                 once-evil-insert-and-writable
                 once-meow-insert-and-writable
                 once-minibuffer
                 once-save
                 once-edit
                 once-directory
                 once-search
                 once-prog
                 once-theme
                 once-second-frame
                 once-client-frame
                 once-mouse
                 once-remote-file
                 once-large-file
                 once-ime
                 once-mark
                 once-elisp
                 once-project
                 once-debugger
                 once-kill))
    (should (boundp var)))
  (dolist (grp '())
    (should (get grp 'custom-group)))
  (dolist (fun '(once-conditions--mark-startup-finished
                 once-conditions--startup-finished-p
                 once-conditions--initialized-p
                 once-conditions--writable-p
                 once-conditions--graphic-frame-p
                 once-conditions--terminal-frame-p
                 once-conditions--evil-insert-writable-p
                 once-conditions--evil-insert-hooks
                 once-init
                 once-gui
                 once-tty
                 once-input
                 once-buffer
                 once-file
                 once-writable
                 once-evil-insert-and-writable
                 once-meow-insert-and-writable
                 once-minibuffer
                 once-save
                 once-edit
                 once-directory
                 once-search
                 once-prog
                 once-theme
                 once-second-frame
                 once-client-frame
                 once-mouse
                 once-remote-file
                 once-large-file
                 once-ime
                 once-mark
                 once-elisp
                 once-project
                 once-debugger
                 once-kill))
    (should (fboundp fun))))

;;; Wiring: a condition is data that `once' consumes, so the data is the
;;; product.  These are the exact plists `once' receives.

(ert-deftest once-conditions-conditions-are-wired-to-their-triggers ()
  (should (equal once-init
                 '(:check once-conditions--initialized-p
                          :hooks after-init-hook)))
  (should (equal once-input
                 '(:hooks (pre-command-hook
                           once-conditions--startup-finished-p))))
  (should (equal once-buffer
                 '(:before (after-find-file
                            once-conditions--startup-finished-p)
                           :hooks (window-buffer-change-functions
                                   once-conditions--startup-finished-p)
                           (server-visit-hook
                            once-conditions--startup-finished-p))))
  (should (equal once-file
                 '(:before (after-find-file
                            once-conditions--startup-finished-p)
                           :hooks (dired-initial-position-hook
                                   once-conditions--startup-finished-p))))
  (should (equal once-writable
                 '(:before (after-find-file once-conditions--writable-p)
                           :hooks (dired-initial-position-hook
                                   once-conditions--writable-p))))
  (should (equal once-gui
                 '(:check once-conditions--graphic-frame-p
                          :hooks server-after-make-frame-hook
                          after-make-frame-functions)))
  (should (equal once-tty
                 '(:check once-conditions--terminal-frame-p
                          :hooks server-after-make-frame-hook
                          after-make-frame-functions)))
  (should (equal once-meow-insert-and-writable
                 '(:hooks (meow-insert-enter-hook
                           once-conditions--writable-p))))
  ;; once-evil-insert-and-writable is built from the custom variable, so only
  ;; its shape is fixed here; the state list has its own test.
  (should (eq (car once-evil-insert-and-writable) :hooks))
  (should (equal (cdr once-evil-insert-and-writable)
                 (once-conditions--evil-insert-hooks)))
  ;; The conditions added after the first set.  A condition whose local
  ;; check is a lambda is checked by shape: the lambda is a closure, so it
  ;; is not `equal' to a fresh literal.
  (should (eq (car once-second-frame) :hooks))
  (should (equal (caadr once-second-frame) 'after-make-frame-functions))
  (should (functionp (cadr (cadr once-second-frame))))
  (should (equal once-client-frame '(:hooks server-after-make-frame-hook)))
  (should (equal once-theme '(:hooks enable-theme-functions)))
  (should (eq (car once-mouse) :hooks))
  (should (equal (caadr once-mouse) 'pre-command-hook))
  (should (functionp (cadr (cadr once-mouse))))
  (should (equal once-minibuffer '(:hooks minibuffer-setup-hook)))
  (should (equal once-search '(:hooks isearch-mode-hook)))
  (should (equal once-prog '(:hooks prog-mode-hook)))
  (should (equal once-directory '(:before dired)))
  (should (eq (car once-large-file) :hooks))
  (should (equal (caadr once-large-file) 'find-file-hook))
  (should (functionp (cadr (cadr once-large-file))))
  (should (eq (car once-remote-file) :before))
  (should (equal (caadr once-remote-file) 'find-file))
  (should (functionp (cadr (cadr once-remote-file))))
  (should (equal once-save '(:hooks after-save-hook)))
  (should (equal once-edit '(:hooks first-change-hook)))
  ;; The conditions added after that.
  (should (equal once-ime '(:hooks input-method-activate-hook)))
  (should (equal once-mark '(:hooks activate-mark-hook)))
  (should (equal once-elisp '(:hooks emacs-lisp-mode-hook)))
  (should (eq (car once-project) :hooks))
  (should (equal (caadr once-project) 'find-file-hook))
  (should (functionp (cadr (cadr once-project))))
  (should (equal once-debugger '(:before debug)))
  (should (equal once-kill '(:before kill-new))))

;;; Every condition exists as both a variable (the plist above) and a macro.

(ert-deftest once-conditions-macros-expand-to-plain-once ()
  (dolist (name '(once-init once-gui once-tty once-input once-buffer
                  once-file once-writable
                  once-evil-insert-and-writable
                  once-meow-insert-and-writable
                  once-minibuffer once-save once-edit once-directory
                  once-search once-prog once-theme once-second-frame
                  once-client-frame once-mouse once-remote-file
                  once-large-file once-ime once-mark once-elisp
                  once-project once-debugger once-kill))
    (should (macrop name))
    (should (equal (macroexpand-1 (list name '(setq probe t)))
                   (list 'once name '(setq probe t))))))

;;; Helpers.

(ert-deftest once-conditions-initialized-p-follows-after-init-time ()
  (should (equal (once-conditions--initialized-p) after-init-time))
  (let ((after-init-time nil))
    (should-not (once-conditions--initialized-p)))
  (let ((after-init-time '(0 0)))
    (should (once-conditions--initialized-p))))

(ert-deftest once-conditions-startup-gate-is-armed-from-window-setup-hook ()
  ;; The marker runs from `window-setup-hook', which is the last of the startup
  ;; hooks; that is what makes the gate trustworthy.
  (should (memq #'once-conditions--mark-startup-finished window-setup-hook))
  (let ((once-startup-finished-p nil))
    (once-conditions--mark-startup-finished)
    (should once-startup-finished-p))
  ;; The gate ignores whatever the trigger passes it.
  (let ((once-startup-finished-p t))
    (should (once-conditions--startup-finished-p))
    (should (once-conditions--startup-finished-p 'hook-arg 'another))))

(ert-deftest once-conditions-writable-p-needs-startup-and-a-writable-buffer ()
  (let ((once-startup-finished-p nil))
    (with-temp-buffer
      (should-not (once-conditions--writable-p))))
  (let ((once-startup-finished-p t))
    (with-temp-buffer
      (should (once-conditions--writable-p))
      (should (once-conditions--writable-p 'hook-arg)))
    (with-temp-buffer
      (setq buffer-read-only t)
      (should-not (once-conditions--writable-p)))))

(ert-deftest once-conditions-evil-insert-gate-matches-the-writable-gate ()
  (let ((once-startup-finished-p t))
    (with-temp-buffer
      (should (once-conditions--evil-insert-writable-p))
      (setq buffer-read-only t)
      (should-not (once-conditions--evil-insert-writable-p))))
  (let ((once-startup-finished-p nil))
    (with-temp-buffer
      (should-not (once-conditions--evil-insert-writable-p)))))

(ert-deftest once-conditions-evil-insert-hooks-follow-the-custom-variable ()
  (should (equal (once-conditions--evil-insert-hooks)
                 '((evil-insert-state-entry-hook
                    once-conditions--evil-insert-writable-p)
                   (evil-emacs-state-entry-hook
                    once-conditions--evil-insert-writable-p))))
  (let ((once-evil-insert-states '(normal)))
    (should (equal (once-conditions--evil-insert-hooks)
                   '((evil-normal-state-entry-hook
                      once-conditions--evil-insert-writable-p))))))

;;; Frame conditions: before initialization a daemon must always defer, and
;;; afterwards any live frame of the right kind counts.

(ert-deftest once-conditions-graphic-frame-p-before-init-never-fires-in-a-daemon ()
  (let ((after-init-time nil))
    (cl-letf (((symbol-function 'daemonp) (lambda () t))
              ((symbol-function 'display-graphic-p) (lambda (&optional _f) t)))
      (should-not (once-conditions--graphic-frame-p)))
    (cl-letf (((symbol-function 'daemonp) (lambda () nil))
              ((symbol-function 'display-graphic-p) (lambda (&optional _f) t)))
      (should (once-conditions--graphic-frame-p)))
    (cl-letf (((symbol-function 'daemonp) (lambda () nil))
              ((symbol-function 'display-graphic-p) (lambda (&optional _f) nil)))
      (should-not (once-conditions--graphic-frame-p)))))

(ert-deftest once-conditions-graphic-frame-p-after-init-any-graphic-frame-counts ()
  (let ((after-init-time '(0 0)))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda (&optional _f) t)))
      (should (once-conditions--graphic-frame-p)))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda (&optional _f) nil)))
      (should-not (once-conditions--graphic-frame-p)))))

(ert-deftest once-conditions-terminal-frame-p-mirrors-the-graphic-one ()
  (let ((after-init-time nil))
    (cl-letf (((symbol-function 'daemonp) (lambda () t))
              ((symbol-function 'display-graphic-p) (lambda (&optional _f) nil)))
      (should-not (once-conditions--terminal-frame-p)))
    (cl-letf (((symbol-function 'daemonp) (lambda () nil))
              ((symbol-function 'display-graphic-p) (lambda (&optional _f) nil)))
      (should (once-conditions--terminal-frame-p))))
  (let ((after-init-time '(0 0)))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda (&optional _f) nil)))
      (should (once-conditions--terminal-frame-p)))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda (&optional _f) t)))
      (should-not (once-conditions--terminal-frame-p)))))

;;; End to end through the real `once' macro.

(ert-deftest once-conditions-once-init-runs-now-when-initialization-finished ()
  (let ((ran nil))
    (let ((after-init-time nil) (after-init-hook nil))
      (once once-init (setq ran t))
      (should-not ran)
      (setq after-init-time '(0 0))
      (run-hooks 'after-init-hook))
    (should ran))
  (let ((ran nil))
    (let ((after-init-time '(0 0)))
      (once once-init (setq ran t)))
    (should ran)))

(ert-deftest once-conditions-once-input-waits-for-the-startup-gate ()
  (let ((ran nil)
        (pre-command-hook nil)
        (once-startup-finished-p nil))
    (once once-input (setq ran t))
    (run-hooks 'pre-command-hook)
    (should-not ran)
    (setq once-startup-finished-p t)
    (run-hooks 'pre-command-hook)
    (should ran)))

(ert-deftest once-conditions-once-writable-waits-for-the-dired-hook ()
  ;; `dired' has to be loaded first so that `dired-initial-position-hook' is a
  ;; real variable, and the hook is bound so that a registration which is
  ;; deliberately never triggered cannot leak into the other tests.
  (require 'dired)
  (let ((ran nil)
        (dired-initial-position-hook nil)
        (once-startup-finished-p t))
    (with-temp-buffer
      (once once-writable (setq ran t))
      (should-not ran)
      (run-hooks 'dired-initial-position-hook))
    (should ran))
  (let ((ran nil)
        (dired-initial-position-hook nil)
        (once-startup-finished-p nil))
    (with-temp-buffer
      (once once-writable (setq ran t))
      (run-hooks 'dired-initial-position-hook))
    (should-not ran))
  (let ((ran nil)
        (dired-initial-position-hook nil)
        (once-startup-finished-p t))
    (with-temp-buffer
      (once once-writable (setq ran t))
      (setq buffer-read-only t)
      (run-hooks 'dired-initial-position-hook))
    (should-not ran)))

;;; The conditions added after the first set.  Each test fires the real
;;; trigger: a hook is run with `run-hooks', `dired' is really called, and
;;; the conditions that carry a local check are also checked with the check
;;; false to show that the body stays put until the check passes.

(ert-deftest once-conditions-once-minibuffer-fires-on-minibuffer-setup-hook ()
  (let ((runs 0)
        (minibuffer-setup-hook nil))
    (once once-minibuffer (cl-incf runs))
    (should (= runs 0))
    (run-hooks 'minibuffer-setup-hook)
    (should (= runs 1))
    (run-hooks 'minibuffer-setup-hook)
    (should (= runs 1))))

(ert-deftest once-conditions-once-save-fires-on-after-save-hook ()
  (let ((runs 0)
        (after-save-hook nil))
    (once once-save (cl-incf runs))
    (should (= runs 0))
    (run-hooks 'after-save-hook)
    (should (= runs 1))
    (run-hooks 'after-save-hook)
    (should (= runs 1))))

(ert-deftest once-conditions-once-edit-fires-on-first-change-hook ()
  (let ((runs 0)
        (first-change-hook nil))
    (once once-edit (cl-incf runs))
    (should (= runs 0))
    (run-hooks 'first-change-hook)
    (should (= runs 1))
    (run-hooks 'first-change-hook)
    (should (= runs 1))))

(ert-deftest once-conditions-once-directory-advises-dired ()
  ;; Dired works in batch mode, so the trigger is fired for real through a
  ;; temporary directory instead of simulating it.  Binding
  ;; `dired-use-ls-dired' keeps Dired from probing `ls' for --dired support.
  (require 'dired)
  (let ((runs 0)
        (dired-use-ls-dired nil)
        (dir (make-temp-file "once-conditions-dired-" t)))
    (unwind-protect
        (progn
          (once once-directory (cl-incf runs))
          (should (advice--p (symbol-function 'dired)))
          (save-window-excursion
            (dired dir)
            (should (= runs 1))
            (dired dir)
            (should (= runs 1))))
      (delete-directory dir t))))

(ert-deftest once-conditions-once-search-fires-on-isearch-mode-hook ()
  (let ((runs 0)
        (isearch-mode-hook nil))
    (once once-search (cl-incf runs))
    (should (= runs 0))
    (run-hooks 'isearch-mode-hook)
    (should (= runs 1))
    (run-hooks 'isearch-mode-hook)
    (should (= runs 1))))

(ert-deftest once-conditions-once-prog-fires-on-prog-mode-hook ()
  (let ((runs 0)
        (prog-mode-hook nil))
    (once once-prog (cl-incf runs))
    (should (= runs 0))
    (run-hooks 'prog-mode-hook)
    (should (= runs 1))
    (run-hooks 'prog-mode-hook)
    (should (= runs 1))))

(ert-deftest once-conditions-once-theme-fires-on-enable-theme-functions ()
  (let ((runs 0)
        (enable-theme-functions nil))
    (once once-theme (cl-incf runs))
    (should (= runs 0))
    (run-hooks 'enable-theme-functions)
    (should (= runs 1))
    (run-hooks 'enable-theme-functions)
    (should (= runs 1))))

(ert-deftest once-conditions-once-second-frame-needs-more-than-one-frame ()
  (let ((runs 0)
        (after-make-frame-functions nil))
    (once once-second-frame (cl-incf runs))
    ;; the local check ignores the frame it is passed and counts live frames
    (cl-letf (((symbol-function 'frame-list) (lambda () (list 'only-frame))))
      (run-hooks 'after-make-frame-functions)
      (should (= runs 0)))
    (cl-letf (((symbol-function 'frame-list)
               (lambda () (list 'frame-1 'frame-2))))
      (run-hooks 'after-make-frame-functions)
      (should (= runs 1))
      (run-hooks 'after-make-frame-functions)
      (should (= runs 1)))))

(ert-deftest once-conditions-once-client-frame-fires-on-the-server-hook ()
  ;; `server-after-make-frame-hook' is defined in server.el, which is not
  ;; loaded in batch mode.
  (require 'server)
  (let ((runs 0)
        (server-after-make-frame-hook nil))
    (once once-client-frame (cl-incf runs))
    (run-hooks 'server-after-make-frame-hook)
    (should (= runs 1))
    (run-hooks 'server-after-make-frame-hook)
    (should (= runs 1))))

(ert-deftest once-conditions-once-mouse-fires-only-for-mouse-events ()
  (let ((runs 0)
        (pre-command-hook nil)
        (last-command-event 'some-key))
    (once once-mouse (cl-incf runs))
    ;; the local check runs from the command loop, where `last-command-event'
    ;; holds the event that is about to be dispatched
    (cl-letf (((symbol-function 'mouse-event-p)
               (lambda (event) (eq event 'mouse-1))))
      (run-hooks 'pre-command-hook)
      (should (= runs 0))
      (let ((last-command-event 'mouse-1))
        (run-hooks 'pre-command-hook)
        (should (= runs 1))
        (run-hooks 'pre-command-hook)
        (should (= runs 1))))))

(ert-deftest once-conditions-once-remote-file-fires-only-for-remote-files ()
  (let ((runs 0))
    (once once-remote-file (cl-incf runs))
    ;; the local check is on `:before' advice, so it is passed the arguments
    ;; of the `find-file' call, namely the file name
    (cl-letf (((symbol-function 'file-remote-p)
               (lambda (file &rest _) (string-prefix-p "/ssh:" file)))
              ((symbol-function 'find-file-noselect)
               (lambda (&rest _) (current-buffer))))
      (find-file "/tmp/local-file")
      (should (= runs 0))
      (find-file "/ssh:host:/etc/hosts")
      (should (= runs 1))
      (find-file "/ssh:host:/etc/hosts")
      (should (= runs 1)))))

(ert-deftest once-conditions-once-large-file-fires-only-for-large-buffers ()
  (with-temp-buffer
    (let ((runs 0)
          (find-file-hook nil)
          (large-file-warning-threshold 1000000))
      (once once-large-file (cl-incf runs))
      ;; `find-file-hook' passes no arguments, so the local check looks at
      ;; the current buffer instead
      (cl-letf (((symbol-function 'buffer-size) (lambda (&optional _) 10)))
        (run-hooks 'find-file-hook)
        (should (= runs 0)))
      (cl-letf (((symbol-function 'buffer-size)
                 (lambda (&optional _) 2000000)))
        (run-hooks 'find-file-hook)
        (should (= runs 1))
        (run-hooks 'find-file-hook)
        (should (= runs 1))))))

;;; The conditions added after that.  Every test fires the real trigger:
;;; a hook is run with `run-hooks', `debug' and `kill-new' are really called,
;;; and the condition that carries a local check is checked both when the
;;; check passes and when it does not.

(ert-deftest once-conditions-once-ime-fires-on-input-method-activate-hook ()
  (let ((runs 0)
        (input-method-activate-hook nil))
    (once once-ime (cl-incf runs))
    (should (= runs 0))
    (run-hooks 'input-method-activate-hook)
    (should (= runs 1))
    (run-hooks 'input-method-activate-hook)
    (should (= runs 1))))

(ert-deftest once-conditions-once-mark-fires-on-activate-mark-hook ()
  (let ((runs 0)
        (activate-mark-hook nil))
    (once once-mark (cl-incf runs))
    (should (= runs 0))
    (run-hooks 'activate-mark-hook)
    (should (= runs 1))
    (run-hooks 'activate-mark-hook)
    (should (= runs 1))))

(ert-deftest once-conditions-once-elisp-fires-on-emacs-lisp-mode-hook ()
  (let ((runs 0)
        (emacs-lisp-mode-hook nil))
    (once once-elisp (cl-incf runs))
    (should (= runs 0))
    (run-hooks 'emacs-lisp-mode-hook)
    (should (= runs 1))
    (run-hooks 'emacs-lisp-mode-hook)
    (should (= runs 1))))

(ert-deftest once-conditions-once-project-fires-only-inside-a-project ()
  ;; The local check runs from `find-file-hook' with the buffer current, so
  ;; `project-current' is stubbed to decide whether a project is there.
  (let ((runs 0)
        (find-file-hook nil))
    (with-temp-buffer
      (once once-project (cl-incf runs))
      (cl-letf (((symbol-function 'project-current)
                 (lambda (&rest _) 'some-project)))
        (run-hooks 'find-file-hook)
        (should (= runs 1))
        (run-hooks 'find-file-hook)
        (should (= runs 1)))))
  (let ((runs 0)
        (find-file-hook nil))
    (with-temp-buffer
      (once once-project (cl-incf runs))
      (cl-letf (((symbol-function 'project-current)
                 (lambda (&rest _) nil)))
        (run-hooks 'find-file-hook)
        (should (= runs 0))
        (run-hooks 'find-file-hook)
        (should (= runs 0))))))

(ert-deftest once-conditions-once-debugger-advises-debug ()
  ;; `debug' is autoloaded, so the real (subr) definition is loaded first;
  ;; otherwise `symbol-function' still shows the autoload and `advice--p'
  ;; cannot see the advice.
  (require 'debug)
  (let ((runs 0))
    (once once-debugger (cl-incf runs))
    (should (advice--p (symbol-function 'debug)))
    ;; Calling `debug' for real would enter the debugger, which in batch
    ;; kills Emacs.  Its docstring says that a non-nil `inhibit-redisplay'
    ;; keeps the debugger from being entered, and the advice still runs
    ;; first, so `debug' is called that way to fire the real trigger.
    (let ((inhibit-redisplay t))
      (debug)
      (should (= runs 1))
      (debug)
      (should (= runs 1)))))

(ert-deftest once-conditions-once-kill-advises-kill-new ()
  (let ((runs 0)
        (kill-ring nil))
    (once once-kill (cl-incf runs))
    (should (advice--p (symbol-function 'kill-new)))
    (kill-new "first kill")
    (should (= runs 1))
    (kill-new "second kill")
    (should (= runs 1))))

(provide 'test-once-conditions)
;;; test-once-conditions.el ends here
