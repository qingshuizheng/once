;;; once-setup-examples.el --- setup.el examples  -*- lexical-binding: t; -*-

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
;; file is the list of what can be written.  Everything here is the setup.el
;; integration in `once-setup.el': the recipe that enables the keywords,
;; `:once', `:once-x-require' and `:once-require-incrementally', and the
;; renaming of the last two through `once-setup-keyword-aliases'.  The rest
;; of `once' has its own `once-examples.el' beside this file.

;;; Code:

;; * setup.el
;;
;; once-setup has to be loaded before its keywords can be used, and
;; `once-setup-keyword-aliases' has to be set before loading it.

'(
  (setup (:package once-setup)
         (eval-and-compile
           (setq once-setup-keyword-aliases
                 (list :once-x-require :require-once
                       :once-require-incrementally :require-incrementally)))
         (:require once-setup)))

;; :once is `once'.  When the body is left out, or when an item of the body
;; is nil or t, the mode of the setup feature is used (magit-todos becomes
;; #'magit-todos-mode).  It expands to `(once-x-call CONDITION ...)'.

'(
  (setup magit-todos
         (:once (list :hooks 'magit-status-hook) (magit-todos-mode 1)))
  (setup magit-todos
         (:once (list :hooks 'magit-status-hook)))
  (setup magit-todos
         (:once (list :hooks 'magit-status-hook) nil)))

;; :once-x-require is `once-x-require' with the feature of the setup form
;; used when none is given.  It expands to `(once-x-require CONDITION ...)'.

'(
  (setup magit
         (:once-x-require (list :hooks 'magit-status-hook)))
  (setup magit
         (:once-x-require (list :hooks 'magit-status-hook) 'evil)))

;; :once-require-incrementally is `once-require-incrementally' with the
;; feature of the setup form used when none is given.  It expands to
;; `(once-incrementally :features ...)'.

'(
  (setup magit
         (:once-require-incrementally))
  (setup magit
         (:once-require-incrementally evil magit))
  ;; with the aliases above, the last two are :require-once and
  ;; :require-incrementally
  (setup forge
         (:require-once "magit"))
  (setup recentf
         (:require-incrementally easymenu tree-widget timer recentf)))

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
  (setup (:package once-conditions)
         (:require once-conditions)))

;; ** :once
;;
;; With a function in the body, that function is the one :once calls.

'(
  (setup which-key
         (:once once-input #'which-key-mode))
  (setup editorconfig
         (:once once-buffer #'editorconfig-mode))
  (setup clipetty
         (:once once-tty #'global-clipetty-mode)))

;; With the body left out the mode is inferred instead, so this still
;; calls #'which-key-mode.

'(
  (setup which-key
         (:once once-input)))

;; nil or t stands for the inferred mode when another function is named
;; beside it: foo-mode is called first, then foo-2-mode.

'(
  (setup foo
         (:once once-input t #'foo-2-mode)))

;; The conditions added after the first set go in the same way, with the
;; mode of the setup feature inferred when no function is given.

'(
  (setup which-key
         (:once once-minibuffer))
  (setup super-save
         (:once once-save))
  (setup ws-butler
         (:once once-edit))
  (setup diredfl
         (:once once-directory))
  (setup anzu
         (:once once-search))
  (setup eglot
         (:once once-prog))
  (setup modus-themes
         (:once once-theme))
  (setup foo
         (:once once-second-frame))
  (setup foo
         (:once once-client-frame))
  (setup mouse-avoidance
         (:once once-mouse))
  (setup tramp
         (:once once-remote-file))
  (setup so-long
         (:once once-large-file))
  (setup pyim
         (:once once-ime))
  (setup expand-region
         (:once once-mark))
  (setup paredit
         (:once once-elisp))
  (setup projectile
         (:once once-project))
  (setup foo
         (:once once-debugger))
  (setup browse-kill-ring
         (:once once-kill)))

;; A function can be named beside the condition, as above.

'(
  (setup which-key
         (:once once-minibuffer #'which-key-mode))
  (setup foo
         (:once once-save #'my-save-setup))
  (setup foo
         (:once once-remote-file #'my-remote-file-setup))
  (setup foo
         (:once once-large-file #'so-long-mode)))

;; ** :once-x-require
;;
;; The condition is the first argument here too.  once-setup infers the
;; feature when it is left out, so `(:once-x-require once-input)' would
;; require forge just the same.

'(
  (setup forge
         (:once-x-require once-input 'forge)))

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

(provide 'once-setup-examples)
;;; once-setup-examples.el ends here
