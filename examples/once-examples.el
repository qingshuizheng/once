;;; once-examples.el --- Examples of all once usage  -*- lexical-binding: t; -*-

;; Copyright (c) 2026, Qingshui Zheng

;; Author: Qingshui Zheng <qingshuizheng@outlook.com>
;; Maintainer: Qingshui Zheng <qingshuizheng@outlook.com>
;; URL: https://github.com/qingshuizheng/once
;; Created: October 06, 2026
;; Keywords: convenience dotemacs startup config
;; Package-Requires: ((emacs "26.1") (once "0.1.0"))
;; Version: 0.1.0

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
;; Nothing runs when this file is loaded.  It is a reference: each group of
;; examples below is quoted, so it is data rather than code.  A `comment'
;; wrapper would be the usual way to mark examples, but it is not defined in
;; every Emacs, and it does not keep the byte compiler from checking the forms
;; inside it either.  Within a group everything is written the way it would be
;; in an init file, so to use an example, copy it out and drop the leading
;; quote.
;;
;; The manual (README.org, or the info manual) explains the details; this
;; file is the list of what can be written.  Sections:
;;
;; - "Loading once a file has loaded": `once-eval-after-load',
;;   `once-with-eval-after-load' and their aliases
;; - "The condition of `once-x-call'": every trigger keyword
;; - "`once' and `once-x-require'": the macro and the require helper
;; - "`once-shorthand'": the brief condition syntax
;;
;; The pre-defined conditions and their macros (`once-gui', `once-tty',
;; `once-init', `once-input', `once-buffer', `once-file', `once-writable',
;; `once-evil-insert-and-writable') live in `once-conditions', the directory
;; of that name beside this file; the manual documents them.  Incremental
;; loading has its own `once-incrementally-examples.el', and the setup.el and
;; use-package keywords theirs.
;;
;; `once' and `once-x-call' take a condition and a body.  The body is either
;; a list of functions (each taking no arguments) or a body of forms:
;;
;;   (once CONDITION #'some-mode 'some-other-function)
;;   (once CONDITION (some-form) (another-form))
;;
;; The condition is a list.  Its keywords say what may trigger the body:
;;
;;   (once-x-call (list :hooks 'some-hook
;;                      :before 'some-function
;;                      :packages 'some-feature
;;                      :files "some-file"
;;                      :variables 'some-variable
;;                      :check (lambda () ...)
;;                      :initial-check (lambda () ...))
;;     #'some-mode)
;;
;; At least one of :hooks, :packages/:files, :variables/:vars or an advice
;; keyword is required.  Any of the given triggers may run the body, and
;; the body runs once: the hooks and the advice are removed again after it
;; runs.  There are no and/or rules between the triggers.

;;; Code:

;; * Loading once a file has loaded
;;
;; Like `eval-after-load', except that the form runs immediately instead of
;; being added to `after-load-alist' when the file has already been loaded,
;; and that it is removed from `after-load-alist' after it runs.

'(
  (once-eval-after-load 'magit (magit-mode 1))
  (once-eval-after-load "magit" (magit-mode 1))
  (once-after-load 'magit (magit-mode 1))) ; alias

'(
  (once-with-eval-after-load 'magit
                             (setq magit-save-repository-buffers 'dontask)
                             (magit-mode 1))
  (once-with 'magit (magit-mode 1))) ; alias

;; * The condition of `once-x-call'

;; ** :hooks
;;
;; A hook symbol, or a list of a hook and a local check, or a plist with
;; :hook, :depth, :local and :check (see "Local checks" below).

'(
  ;; run once the first time `magit-status-hook' runs
  (once-x-call (list :hooks 'magit-status-hook) #'magit-todos-mode)
  ;; several hooks; the first one to run wins
  (once-x-call (list :hooks 'magit-status-hook 'magit-refresh-hook)
               #'my-refresh-setup)
  ;; only when the hook runs with a specific condition
  (once-x-call (list :hooks (list 'after-load-functions
                                  (lambda (_file) (boundp 'some-symbol))))
               #'my-setup))

;; ** Advice
;;
;; Any `advice-add' WHERE keyword (:before, :after, :around, :override,
;; :before-while, :after-until, :filter-args, :filter-return, ...).

'(
  (once-x-call (list :before 'magit-status) #'my-before-status)
  (once-x-call (list :after 'magit-status) #'my-after-status)
  (once-x-call (list :around 'magit-status) #'my-around-status)
  (once-x-call (list :override 'magit-status) #'my-status)
  (once-x-call (list :filter-args 'magit-status) #'my-args)
  (once-x-call (list :filter-return 'magit-status) #'my-value)
  ;; several functions to advise, and several triggers at once
  (once-x-call (list :before 'magit-status 'magit-refresh)
               #'my-setup))

;; ** :packages and :files
;;
;; A feature or a file/regexp, i.e. a valid argument to `eval-after-load'.
;; Unlike other triggers, one of these that has already loaded runs the body
;; immediately when there is no check.

'(
  (once-x-call (list :packages 'evil) #'my-evil-setup)
  (once-x-call (list :files "magit") #'my-magit-setup)
  ;; either of them loading is enough
  (once-x-call (list :packages 'evil 'magit) #'my-setup)
  ;; a local check gets no arguments here
  (once-x-call (list :packages (list 'evil (lambda () (boundp 'evil-mode))))
               #'my-evil-setup))

;; ** :variables and :vars
;;
;; A variable that triggers the body the first time it is set (through
;; `add-variable-watcher').

'(
  (once-x-call (list :variables 'my-var) #'my-var-setup)
  (once-x-call (list :vars 'my-var) #'my-var-setup) ; alias
  ;; a local check is passed (symbol newval operation where)
  (once-x-call (list :variables (list 'my-var (lambda (_sym newval &rest _)
                                                (eq newval 'ready))))
               #'my-var-setup))

;; ** :check and :initial-check
;;
;; :check decides at once-call time whether to run now, and is consulted
;; again whenever a trigger fires.  :initial-check is meant for the initial
;; decision only.

'(
  ;; run now if the check passes, otherwise the first time the hook runs
  ;; with the check passing
  (once-x-call (list :hooks 'magit-status-hook
                     :check (lambda () (featurep 'evil)))
               #'my-setup)
  ;; a general check with a package trigger
  (once-x-call (list :check #'display-graphic-p
                     :hooks 'server-after-make-frame-hook)
               #'my-font-setup)
  ;; decide once Emacs has started, and not before
  (once-x-call (list :hooks 'after-init-hook
                     :initial-check (lambda () after-init-time))
               #'my-setup))

;; NOTE: the manual says that when both keywords are given, the initial
;; decision uses :initial-check and the triggers use :check, and the
;; implementation agrees.  With only one of the two, it is used for both
;; decisions.  The manual's way of forcing a deferred run, `:check' together
;; with `:initial-check (lambda () nil)', therefore works as documented.

;; ** Local checks
;;
;; A check can be attached to one trigger instead of the whole condition.
;; A local check for a hook or for advice is passed the arguments of the
;; hook or of the advised function.

'(
  ;; a hook with a local check
  (once-x-call (list :hooks (list 'magit-status-hook
                                  (lambda (&rest _) (featurep 'evil))))
               #'my-setup)
  ;; the same hook with the plist syntax; :hook is required there
  (once-x-call (list :hooks (list :hook 'magit-status-hook
                                  :depth 10
                                  :local t
                                  :check #'my-check))
               #'my-setup)
  ;; a negative depth runs earlier, and there does not have to be a check
  (once-x-call (list :hooks (list :hook 'emacs-lisp-mode-hook :depth -90))
               #'my-elisp-setup)
  (once-x-call (list :hooks (list :hook 'post-command-hook :local t))
               #'my-post-command-setup)
  ;; advice with a local check
  (once-x-call (list :after
                     (list 'magit-status
                           (lambda (&rest _) (featurep 'evil))))
               #'my-setup))

;; * `once' and `once-x-require'
;;
;; `once' is `once-x-call' with a body instead of a function list.  When the
;; first item of the body could be a function, the whole body is a list of
;; functions; otherwise it is a body of forms.

'(
  (once (list :hooks 'magit-status-hook) (magit-todos-mode 1))
  (once (list :hooks 'magit-status-hook) #'magit-todos-mode 'my-other-function)
  (once (list :before 'magit-status) (my-setup) (my-other-setup))
  (once (list :packages 'evil) (setq evil-want-integration t)))

;; A condition can live in a variable, which is how more complex conditions
;; are usually kept.

'(
  (defvar my-condition
    (list :hooks 'evil-insert-state-entry-hook
          :check (lambda () (not buffer-read-only))))
  (once my-condition (my-setup))
  (once-x-call my-condition #'my-setup))

;; `once-x-require' requires features once a condition is met.  It defines a
;; `once-require-FEATURE' function for them and calls `once-x-call' with it.

'(
  (once-x-require (list :hooks 'magit-status-hook) 'magit-todos)
  (once-x-require (list :hooks 'magit-status-hook) 'magit-todos 'evil))

;; * `once-shorthand'
;;
;; With `once-shorthand' non-nil, the condition does not have to be a list.
;; Symbols ending in "-hook" or "-functions" are hooks, other symbols are
;; functions to advise :before, and strings are files.  Keywords have to
;; come last.  A single symbol or string is also accepted.

'(
  (setq once-shorthand t)
  (once 'magit-status-hook (magit-todos-mode 1))  ; :hooks
  (once 'magit-status (my-setup))                 ; :before
  (once "magit" (my-setup))                       ; :files
  (once #'magit-status (my-setup))                ; :before (named function)
  (once 'magit-status-hook :check (lambda () (featurep 'evil))
        (my-setup))
  ;; shorthand items come before the keywords, so the check comes last
  (once (list #'foo 'bar-mode-hook "some-file") (my-setup)))

(provide 'once-examples)
;;; once-examples.el ends here
