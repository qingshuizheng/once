;;; once-use-package-examples.el --- Examples  -*- lexical-binding: t; -*-

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
;; Nothing runs when this file is loaded.  It is a reference: the group of
;; examples below is quoted, so it is data rather than code.  A `comment'
;; wrapper would be the usual way to mark examples, but it is not defined in
;; every Emacs, and it does not keep the byte compiler from checking the forms
;; inside it either.  Within the group everything is written the way it would
;; be in an init file, so to use an example, copy it out and drop the leading
;; quote.
;;
;; The manual (README.org, or the info manual) explains the details; this
;; file is the list of what can be written.  Everything here is the
;; use-package integration in `once-use-package.el': the same `:once',
;; `:once-x-require' and `:once-require-incrementally' keywords as
;; once-setup, the repeated `:once' arglists, the bare-list gotcha, and
;; `once-use-package-keyword-aliases'.  The rest of `once' has its own
;; `once-examples.el' beside this file.

;;; Code:

;; * use-package
;;
;; once-use-package provides the same three keywords, with
;; `once-use-package-keyword-aliases' for renaming them.  It has to be
;; loaded before the keywords can be used; loading it registers the
;; keywords (it calls `once-use-package-setup' itself).

'(
  (require 'once-use-package)
  ;; the package's own mode is inferred when an arglist has no function
  (use-package magit-todos
    :once (list :hooks 'magit-status-hook))
  (use-package magit-todos
    :once ((list :packages 'magit) #'magit-todos-mode))
  ;; shorthand works here too when `once-shorthand' is on
  (use-package magit-todos
    :once ("magit" #'magit-todos-mode))
  ;; :once may repeat, one arglist per condition
  (use-package foo
    :once
    ('bar-hook #'foo-mode)
    ('baz-hook #'foo2-mode))
  ;; a bare list is an arglist, not a condition: wrap the call to make the
  ;; whole thing one
  (use-package editorconfig
    :once (some-function-that-generates-a-condition-list))   ; wrong
  (use-package editorconfig
    :once ((some-function-that-generates-a-condition-list))) ; right
  ;; the same keyword can require the package as well
  (use-package magit
    :once-x-require (list :hooks 'magit-status-hook))
  (use-package forge
    :once-x-require ((list :packages 'magit) 'forge))
  ;; with the once-use-package-keyword-aliases aliases, "magit" is enough
  (use-package forge
    :require-once "magit")
  (use-package magit
    :once-require-incrementally)
  ;; with the aliases, once-require-incrementally is :require-incrementally
  (use-package recentf
    :require-incrementally easymenu tree-widget timer recentf))

;; * With the predefined conditions
;;
;; A condition variable can be used wherever a condition list can, so the
;; conditions from once-conditions.el go in just like the `(list ...)'
;; ones above.  `(require 'once-conditions)' has to come first: the
;; condition names do not exist until it has been loaded.
;;
;; In these positions a condition name is the condition VARIABLE: the list
;; it holds is what `once-x-call' receives at run time.  The macro of the
;; same name is the standalone `(once-input BODY)' form, and its expansion
;; passes that same variable to `once'.

'(
  (require 'once-conditions))

;; ** :once
;;
;; With a function in the arglist, that function is the one :once calls.

'(
  (use-package which-key
    :once (once-input #'which-key-mode))
  (use-package editorconfig
    :once (once-buffer #'editorconfig-mode))
  (use-package clipetty
    :once (once-tty #'global-clipetty-mode)))

;; With the function left out the mode is inferred instead, so this still
;; calls #'which-key-mode.  A bare atom is a complete condition.

'(
  (use-package which-key
    :once once-input))

;; nil or t stands for the inferred mode when another function is named
;; beside it: foo-mode is called first, then foo-2-mode.

'(
  (use-package foo
    :once (once-input t #'foo-2-mode)))

;; The conditions added after the first set go in the same way.  A bare
;; atom is a complete condition, so the mode of the package is inferred.

'(
  (use-package which-key
    :once once-minibuffer)
  (use-package super-save
    :once once-save)
  (use-package ws-butler
    :once once-edit)
  (use-package diredfl
    :once once-directory)
  (use-package anzu
    :once once-search)
  (use-package eglot
    :once once-prog)
  (use-package modus-themes
    :once once-theme)
  (use-package foo
    :once once-second-frame)
  (use-package foo
    :once once-client-frame)
  (use-package mouse-avoidance
    :once once-mouse)
  (use-package tramp
    :once once-remote-file)
  (use-package so-long
    :once once-large-file)
  (use-package pyim
    :once once-ime)
  (use-package expand-region
    :once once-mark)
  (use-package paredit
    :once once-elisp)
  (use-package projectile
    :once once-project)
  (use-package foo
    :once once-debugger)
  (use-package browse-kill-ring
    :once once-kill))

;; A function can be named beside the condition, as above.

'(
  (use-package which-key
    :once (once-minibuffer #'which-key-mode))
  (use-package foo
    :once (once-save #'my-save-setup))
  (use-package foo
    :once (once-remote-file #'my-remote-file-setup))
  (use-package foo
    :once (once-large-file #'so-long-mode)))

;; ** :once-x-require
;;
;; The condition is the first argument here too.  once-use-package infers
;; the package when it is left out, so `:once-x-require once-input'
;; would require forge just the same.  `:require-once', the alias above,
;; is the same keyword.

'(
  (use-package forge
    :once-x-require (once-input 'forge))
  (use-package forge
    :require-once (once-input 'forge)))

;; ** Which conditions can already hold
;;
;; `once-init', `once-gui' and `once-tty' may already be true when the
;; form is evaluated, so they can fire immediately.  Every other condition
;; only fires from its trigger: `once-input', `once-file', `once-writable',
;; `once-buffer', `once-minibuffer', `once-save', `once-edit',
;; `once-directory', `once-search', `once-prog', `once-elisp',
;; `once-theme', `once-second-frame', `once-client-frame', `once-mouse',
;; `once-ime', `once-mark', `once-project', `once-debugger', `once-kill',
;; `once-remote-file', `once-large-file', and the evil and meow
;; conditions.

;; once-conditions-examples.el beside this file has the conditions one by
;; one.

(provide 'once-use-package-examples)
;;; once-use-package-examples.el ends here
