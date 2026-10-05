;;; once-conditions.el --- Predefined conditions for once.el -*- lexical-binding: t; -*-

;; Copyright (c) 2026, Qingshui Zheng

;; Author: Qingshui Zheng <qingshuizheng@outlook.com>
;; Maintainer: Qingshui Zheng <qingshuizheng@outlook.com>
;; URL: https://github.com/qingshuizheng/once
;; Created: 2026-10-05
;; Keywords: lisp
;; Version: 0.1.0
;; Package-Requires: ((emacs "30.1") (once "0.1.0"))

;; This file is not part of GNU Emacs.
;; License: GPLv3
;; Written with DSH (DeepSeek Harness)

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
;; This is the once-conditions.el that the once README has always
;; referenced but that has never been published upstream: a fresh clone of
;; the repository and its entire history contain no such file.  It is a
;; reconstruction, and it lives here now, next to the rest of the package.
;;
;; once-conditions.el provides predefined `once' conditions for the
;; situations that come up over and over again in an init file, e.g. "run
;; this once the first graphical frame exists" or "run this once the user
;; opens the first file".  They are the `once' equivalents of Doom's
;; `doom-first-*-hook' hooks and on.el's `on-first-*-hook' hooks, except
;; that no new hooks are created.
;;
;; Every condition is provided as both a variable and a macro of the same
;; name (Elisp keeps the value cell and the function cell separate):
;;
;;   ;; as a variable - a condition for any place that accepts one
;;   (use-package winner
;;     :once once-buffer)
;;
;;   ;; as a macro - run BODY once the condition is met
;;   (once-buffer
;;     (winner-mode))
;;
;; With setup.el, the condition is simply the first keyword argument:
;;
;;   (setup (:package winner)
;;     (:once once-buffer))
;;
;; The conditions only ever run their code from a trigger, never while
;; the init file is still being read.  `once' installs a condition's
;; triggers as soon as it is handed one, which is during startup, while
;; on.el only installs its triggers at the very end of startup.  To make
;; up for that, the interaction based conditions
;; (`once-input', `once-buffer', `once-file', `once-writable', and
;; `once-evil-insert-and-writable') use a triggering check that only
;; succeeds after startup has completely finished.  `once-gui',
;; `once-tty', and `once-init' instead describe a state that may already
;; hold, so they can run immediately as documented.
;;
;; The conditions replace the hand written equivalents that predate this
;; file.  They use the same triggers on purpose:
;;
;;   once-init    -> general-after-init
;;   once-gui     -> general-after-gui
;;   once-tty     -> general-after-tty
;;   once-input   -> (add-hook 'pre-command-hook ...)
;;   once-buffer  -> on-first-buffer-hook, i.e. the old
;;                   `on-switch-buffer-hook' (window-buffer-change-functions
;;                   plus server-visit-hook) plus after-find-file advice
;;   once-file    -> on-first-file-hook (after-find-file advice plus
;;                   dired-initial-position-hook)
;;   once-writable-> like once-file but gated on buffer-read-only
;;   once-evil-insert-and-writable
;;                -> evil-insert-state-entry-hook gated on buffer-read-only
;;
;; `once-meow-insert-and-writable' is an addition rather than a
;; reconstruction; it is the same idea for meow's `meow-insert-enter-hook'.
;;
;; For more information see the README in the online repository.

;;; Code:
(require 'cl-lib)

(require 'once)

;; * Settings
(defcustom once-evil-insert-states '(insert emacs)
  "Evil states treated as \"insert\" states.
This is only consulted by `once-evil-insert-and-writable', which builds
its state entry hooks from this value when it is defined.  Set this
before loading once-conditions.el for a change to take effect."
  :type '(repeat symbol)
  :group 'once)

;; * Helpers
(defvar once-startup-finished-p (and after-init-time t)
  "Whether the Emacs startup sequence has completely finished.
This is set from `window-setup-hook', which runs after `init.el',
`after-init-hook', and `emacs-startup-hook'.")

(defun once-conditions--mark-startup-finished ()
  "Record that the Emacs startup sequence has finished."
  (setq once-startup-finished-p t))

;; run last so that this is not set until startup really is over
(add-hook 'window-setup-hook #'once-conditions--mark-startup-finished 99)
;; in case this file is loaded after startup has already finished
(when after-init-time
  (setq once-startup-finished-p t))

(defun once-conditions--startup-finished-p (&rest _)
  "Return non-nil once the startup sequence has finished.
Arguments are ignored so this can be used as a local check for a hook
or for advice."
  once-startup-finished-p)

(defun once-conditions--initialized-p ()
  "Return non-nil once Emacs initialization has finished."
  after-init-time)

(defun once-conditions--writable-p (&rest _)
  "Return non-nil in a writable buffer after startup has finished.
Arguments are ignored so this can be used as a local check for a hook
or for advice."
  (and once-startup-finished-p
       (not buffer-read-only)))

(defun once-conditions--graphic-frame-p ()
  "Return non-nil if code for a graphical frame should run now.
This makes the same distinction that `general-after-gui' makes.  While
Emacs is still starting up, a daemon always has to defer, because the
frames it may already have are not the frames the user will use.
Afterwards any live frame counts, because a frame created with
`make-frame' is not necessarily the selected one yet when
`after-make-frame-functions' runs."
  (if after-init-time
      (cl-some #'display-graphic-p (frame-list))
    (and (not (daemonp))
         (display-graphic-p))))

(defun once-conditions--terminal-frame-p ()
  "Return non-nil if code for a terminal frame should run now.
See `once-conditions--graphic-frame-p' for why this differs before and
after initialization."
  (if after-init-time
      (cl-some (lambda (frame) (not (display-graphic-p frame)))
               (frame-list))
    (and (not (daemonp))
         (not (display-graphic-p)))))

(defun once-conditions--evil-insert-writable-p (&rest _)
  "Return non-nil in a writable buffer once startup has finished.
Arguments are ignored so this can be used as the local check of an
evil state entry hook.  The state itself does not have to be checked,
because the hook it is used on is already state specific."
  (and once-startup-finished-p
       (not buffer-read-only)))

(defun once-conditions--evil-insert-hooks ()
  "Return evil state entry hooks for `once-evil-insert-states'.
The hooks are built when this file is loaded, so
`once-evil-insert-states' has to be set before that happens.

Evil creates each hook variable with `defvar', so adding to a hook
before evil is loaded is safe."
  (mapcar (lambda (state)
            (list (intern (format "evil-%s-state-entry-hook" state))
                  #'once-conditions--evil-insert-writable-p))
          once-evil-insert-states))

;; * Conditions
(defvar once-init
  (list :check #'once-conditions--initialized-p
        :hooks 'after-init-hook)
  "Condition for running code after Emacs initialization.
This is the same as
\(list :check (lambda () `after-init-time') :hooks \\='after-init-hook).
If initialization has already finished, the code runs immediately.

Most of the time a more specific condition such as `once-buffer' is a
better choice.")

(defmacro once-init (&rest body)
  "Run BODY once Emacs initialization has finished.
See the variable `once-init' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-init ,@body))

(defvar once-gui
  (list :check #'once-conditions--graphic-frame-p
        :hooks 'server-after-make-frame-hook
        'after-make-frame-functions)
  "Condition for running code once a graphical frame exists.
The code runs when the first graphical frame is created, or
immediately if the session already has one.  In a terminal only
session this never triggers.

This is the `once' replacement for the `general-after-gui' macro and
for Doom's `doom-init-ui-hook' work.  `server-after-make-frame-hook' is
the primary trigger because it runs after the new frame has been
selected, which is not true of `after-make-frame-functions'.

This is useful for packages that are only needed, or only work, in
graphical frames.")

(defmacro once-gui (&rest body)
  "Run BODY once a graphical frame exists.
See the variable `once-gui' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-gui ,@body))

(defvar once-tty
  (list :check #'once-conditions--terminal-frame-p
        :hooks 'server-after-make-frame-hook
        'after-make-frame-functions)
  "Condition for running code once a terminal frame exists.
The code runs when the first terminal frame is created, or
immediately if the session already has one.  In a graphical only
session this never triggers.

This is the `once' replacement for the `general-after-tty' macro.  It
is useful for packages that should only load in a terminal, e.g. when
starting a client frame with \"emacsclient -t\":
\(once-tty (global-clipetty-mode))")

(defmacro once-tty (&rest body)
  "Run BODY once a terminal frame exists.
See the variable `once-tty' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-tty ,@body))

(defvar once-second-frame
  (list :hooks (list 'after-make-frame-functions
                     (lambda (&rest _)
                       (> (length (frame-list)) 1))))
  "Condition for running code once a second frame exists.
The trigger is `after-make-frame-functions', with a local check that
counts `frame-list' instead of looking at the frame it is passed, since
that frame may not be selected yet.  A daemon that is given a client
frame later on triggers this as well.")

(defmacro once-second-frame (&rest body)
  "Run BODY once a second frame exists.
See the variable `once-second-frame' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-second-frame ,@body))

(defvar once-client-frame
  (list :hooks 'server-after-make-frame-hook)
  "Condition for running code once the server creates a client frame.
The trigger is `server-after-make-frame-hook', which runs after a frame
made for an emacsclient connection has been selected.  In a daemon
session this is the frame that has to be set up, not the one the daemon
starts with.")

(defmacro once-client-frame (&rest body)
  "Run BODY once the server creates a client frame.
See the variable `once-client-frame' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-client-frame ,@body))

(defvar once-theme
  (list :hooks 'enable-theme-functions)
  "Condition for running code once a theme is enabled.
This is the equivalent of Doom's `doom-load-theme-hook'.
The trigger is `enable-theme-functions', which `load-theme' and
`enable-theme' run with the theme as argument.")

(defmacro once-theme (&rest body)
  "Run BODY once a theme is enabled.
See the variable `once-theme' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-theme ,@body))

(defvar once-input
  (list :hooks (list 'pre-command-hook
                     #'once-conditions--startup-finished-p))
  "Condition for running code before the first user input.
This is the equivalent of Doom's `doom-first-input-hook'.")

(defmacro once-input (&rest body)
  "Run BODY before the first user input.
See the variable `once-input' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-input ,@body))

;; The local check of `once-mouse' runs from `pre-command-hook', so it sees
;; the event the command loop is about to dispatch in `last-command-event'.

(defvar once-mouse
  (list :hooks (list 'pre-command-hook
                     (lambda (&rest _) (mouse-event-p last-command-event))))
  "Condition for running code once the user performs a mouse event.
The trigger is `pre-command-hook' with a local check that
`last-command-event' is a mouse event, so it fires on the first mouse
click or wheel event rather than on the first key press.")

(defmacro once-mouse (&rest body)
  "Run BODY once the user performs a mouse event.
See the variable `once-mouse' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-mouse ,@body))

(defvar once-ime
  (list :hooks 'input-method-activate-hook)
  "Condition for running code once an input method is activated.
The trigger is `input-method-activate-hook', which runs just after an
input method is turned on in a buffer.  It fires for any input method,
not for one in particular.")

(defmacro once-ime (&rest body)
  "Run BODY once an input method is activated.
See the variable `once-ime' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-ime ,@body))

(defvar once-minibuffer
  (list :hooks 'minibuffer-setup-hook)
  "Condition for running code once a minibuffer is entered.
The trigger is `minibuffer-setup-hook', which runs when a minibuffer is
set up, e.g. for `M-x' or for a command that reads a file name.")

(defmacro once-minibuffer (&rest body)
  "Run BODY once a minibuffer is entered.
See the variable `once-minibuffer' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-minibuffer ,@body))

(defvar once-search
  (list :hooks 'isearch-mode-hook)
  "Condition for running code once an incremental search starts.
The trigger is `isearch-mode-hook'.")

(defmacro once-search (&rest body)
  "Run BODY once an incremental search starts.
See the variable `once-search' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-search ,@body))

(defvar once-prog
  (list :hooks 'prog-mode-hook)
  "Condition for running code once a programming mode is entered.
The trigger is `prog-mode-hook', which every programming mode derived
from `prog-mode' runs.")

(defmacro once-prog (&rest body)
  "Run BODY once a programming mode is entered.
See the variable `once-prog' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-prog ,@body))

(defvar once-elisp
  (list :hooks 'emacs-lisp-mode-hook)
  "Condition for running code once an Emacs Lisp buffer is set up.
The trigger is `emacs-lisp-mode-hook', which runs when `emacs-lisp-mode'
is set up and, through `run-mode-hooks', for modes derived from it such
as `lisp-interaction-mode'.")

(defmacro once-elisp (&rest body)
  "Run BODY once an Emacs Lisp buffer is set up.
See the variable `once-elisp' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-elisp ,@body))

(defvar once-buffer
  (list :before (list #'after-find-file
                      #'once-conditions--startup-finished-p)
        :hooks (list 'window-buffer-change-functions
                     #'once-conditions--startup-finished-p)
        (list 'server-visit-hook
              #'once-conditions--startup-finished-p))
  "Condition for running code once the current buffer changes.
This is the equivalent of Doom's `doom-first-buffer-hook' or
on.el's `on-first-buffer-hook'.

The trigger hooks always fire during redisplay, so this cannot be
distinguished from the initial redisplay; that is the same behavior as
`on-first-buffer-hook'.")

(defmacro once-buffer (&rest body)
  "Run BODY once the current buffer changes.
See the variable `once-buffer' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-buffer ,@body))

(defvar once-file
  (list :before (list #'after-find-file
                      #'once-conditions--startup-finished-p)
        :hooks (list 'dired-initial-position-hook
                     #'once-conditions--startup-finished-p))
  "Condition for running code once a file is opened.
This is the equivalent of Doom's `doom-first-file-hook' or
on.el's `on-first-file-hook'.

A file given on the command line is opened before startup finishes and
so does not count, just like with `on-first-file-hook'.")

(defmacro once-file (&rest body)
  "Run BODY once a file is opened.
See the variable `once-file' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-file ,@body))

(defvar once-directory
  (list :before #'dired)
  "Condition for running code once a directory is visited with Dired.
The trigger is `dired', advised `:before', so it fires on the first Dired
call whether or not it was interactive.")

(defmacro once-directory (&rest body)
  "Run BODY once a directory is visited with Dired.
See the variable `once-directory' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-directory ,@body))

(defvar once-debugger
  (list :before #'debug)
  "Condition for running code once the debugger is entered.
The trigger is `debug', advised `:before', so it fires the first time
the debugger is entered, whether from `toggle-debug-on-error' or from a
direct call to `debug'.")

(defmacro once-debugger (&rest body)
  "Run BODY once the debugger is entered.
See the variable `once-debugger' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-debugger ,@body))

(defvar once-kill
  (list :before #'kill-new)
  "Condition for running code once something is added to the kill ring.
The trigger is `kill-new', advised `:before', so it fires the first time
a string is pushed onto the kill ring, whether from a kill command or
from a direct call to `kill-new'.")

(defmacro once-kill (&rest body)
  "Run BODY once something is added to the kill ring.
See the variable `once-kill' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-kill ,@body))

;; The next two conditions are gated on their trigger's arguments or on the
;; state the trigger runs in, which is what a local check is for: it is
;; passed the arguments of the hook or of the advised function it belongs to.

(defvar once-large-file
  (list :hooks (list 'find-file-hook
                     (lambda (&rest _)
                       (> (buffer-size)
                          (or large-file-warning-threshold 1000000)))))
  "Condition for running code once a large file is opened.
The trigger is `find-file-hook', with a local check that the current
buffer is bigger than `large-file-warning-threshold' (or than one
million characters when that is nil).")

(defmacro once-large-file (&rest body)
  "Run BODY once a large file is opened.
See the variable `once-large-file' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-large-file ,@body))

;; The local check of `once-project' runs from `find-file-hook' with the
;; buffer current, which is what lets it ask `project-current'.

(defvar once-project
  (list :hooks (list 'find-file-hook
                     (lambda (&rest _) (project-current))))
  "Condition for running code once a file inside a project is opened.
The trigger is `find-file-hook', with a local check that
`project-current' finds a project for the file's buffer.  That check
runs with the buffer current, which is what lets `project-current' look
the project up from the buffer's `default-directory'.

A file visited outside any project does not trigger this.")

(defmacro once-project (&rest body)
  "Run BODY once a file inside a project is opened.
See the variable `once-project' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-project ,@body))

(defvar once-remote-file
  (list :before (list #'find-file
                      (lambda (file &rest _) (file-remote-p file))))
  "Condition for running code once a remote file is opened.
The trigger is `find-file', advised `:before', with a local check that
`file-remote-p' is true for the file it was called with.")

(defmacro once-remote-file (&rest body)
  "Run BODY once a remote file is opened.
See the variable `once-remote-file' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-remote-file ,@body))

(defvar once-save
  (list :hooks 'after-save-hook)
  "Condition for running code once a buffer is saved.
The trigger is `after-save-hook'.")

(defmacro once-save (&rest body)
  "Run BODY once a buffer is saved.
See the variable `once-save' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-save ,@body))

(defvar once-edit
  (list :hooks 'first-change-hook)
  "Condition for running code once the current buffer is modified.
The trigger is `first-change-hook', which runs the first time the buffer
text changes while the buffer is unmodified.")

(defmacro once-edit (&rest body)
  "Run BODY once the current buffer is modified.
See the variable `once-edit' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-edit ,@body))

(defvar once-mark
  (list :hooks 'activate-mark-hook)
  "Condition for running code once a region becomes active.
The trigger is `activate-mark-hook', which runs when the mark is
activated, e.g. after a region is selected with the mouse or after a
command that sets the mark.")

(defmacro once-mark (&rest body)
  "Run BODY once a region becomes active.
See the variable `once-mark' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-mark ,@body))

(defvar once-writable
  (list :before (list #'after-find-file #'once-conditions--writable-p)
        :hooks (list 'dired-initial-position-hook
                     #'once-conditions--writable-p))
  "Condition like `once-file' but only in a writable buffer.")

(defmacro once-writable (&rest body)
  "Run BODY once a writable buffer is visited.
See the variable `once-writable' for the underlying condition."
  (declare (indent 0) (debug (body)))
  `(once once-writable ,@body))

(defvar once-evil-insert-and-writable
  (cons :hooks (once-conditions--evil-insert-hooks))
  "Condition like `once-writable' but triggered by entering evil insert.
Which evil states are considered insert states can be changed with
`once-evil-insert-states', but it has to be set before this file is
loaded.  Nothing happens if evil is not loaded.

The code runs from the `evil-<state>-state-entry-hook' of each insert
state, gated on `buffer-read-only':
\(once-evil-insert-and-writable (evil-insert-state))")

(defmacro once-evil-insert-and-writable (&rest body)
  "Run BODY once a writable buffer is put into an evil insert state.
See the variable `once-evil-insert-and-writable' for the underlying
condition."
  (declare (indent 0) (debug (body)))
  `(once once-evil-insert-and-writable ,@body))

(defvar once-meow-insert-and-writable
  (list :hooks (list 'meow-insert-enter-hook
                     #'once-conditions--writable-p))
  "Condition like `once-writable' but triggered by entering meow insert.
This is the meow equivalent of `once-evil-insert-and-writable'.  It is
an addition and is not part of the set documented in the README.

The code runs from `meow-insert-enter-hook', gated on
`buffer-read-only'.  `meow-insert-enter-hook' is created with `defvar',
so this can be set up before meow is loaded.  Nothing happens if meow
is not loaded.
\(once-meow-insert-and-writable (meow-insert-mode))")

(defmacro once-meow-insert-and-writable (&rest body)
  "Run BODY once a writable buffer is put into meow insert state.
See the variable `once-meow-insert-and-writable' for the underlying
condition."
  (declare (indent 0) (debug (body)))
  `(once once-meow-insert-and-writable ,@body))

(provide 'once-conditions)
;;; once-conditions.el ends here
