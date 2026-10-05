;;; once-incrementally-examples.el --- Examples  -*- lexical-binding: t; -*-

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
;; file is the list of what can be written.  Everything here belongs to
;; `once-incrementally': the settings that control it, `once-incrementally'
;; itself, and the `once-call-incrementally' and
;; `once-require-incrementally' macros.  The rest of `once' has its own
;; `once-examples.el' beside this file.

;;; Code:

;; * Incremental loading
;;
;; Code deferred this way runs after startup, in chunks, during idle time.
;; `once-enable-incremental-loading' has to be called for anything to run.
;; `once-idle-timer' (default 2.0) is how long to wait after startup or
;; after user input; 0 runs everything immediately and nil never runs it.
;; `once-incremental-run-interval' (default 0.75) is the time between runs.
;; Nothing is messaged while code is loaded and run unless
;; `once-incremental-messages' is set, and a failure is messaged unless
;; `once-incremental-error-messages' is nil.

'(
  (once-enable-incremental-loading)
  (setq once-idle-timer 2.0
        once-incremental-run-interval 0.75
        once-incremental-messages t
        once-incremental-error-messages nil))

;; `once-incrementally' takes :features or :functions to say what the
;; following entries are, plus numbers to change the depth of the entries
;; after them.  Entries are not quoted (this is a function).

'(
  (once-incrementally :features 'evil 'magit)
  (once-incrementally :functions #'my-setup #'my-other-setup)
  (once-incrementally :features 'evil
                      10 'magit
                      -90 'important-feature))

;; `once-require-incrementally' and `once-call-incrementally' are the macros
;; for the two cases; their entries are not quoted either.  A depth changes
;; the depth of the entries after it, and adjacent forms of
;; `once-call-incrementally' are grouped into one lambda.

'(
  (once-require-incrementally evil magit)
  (once-require-incrementally 10 evil -90 magit)
  (once-call-incrementally #'my-setup 'my-other-setup
                           (lambda () (message "hi")))
  (once-call-incrementally
   10
   #'my-setup
   20
   (message "a body")
   (message "another body")
   'my-last-function))

(provide 'once-incrementally-examples)
;;; once-incrementally-examples.el ends here
