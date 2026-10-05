;;; once-conditions-examples.el --- Examples  -*- lexical-binding: t; -*-

;; Copyright (c) 2026, Qingshui Zheng

;; Author: Qingshui Zheng <qingshuizheng@outlook.com>
;; Maintainer: Qingshui Zheng <qingshuizheng@outlook.com>
;; URL: https://github.com/qingshuizheng/once
;; Created: October 06, 2026
;; Keywords: convenience dotemacs startup config
;; Package-Requires: ((emacs "30.1") (once "0.1.0") (once-conditions "0.1.0"))
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
;; file is the list of what can be written.  Everything here is
;; `once-conditions': the option `once-evil-insert-states', the variable
;; `once-startup-finished-p', and the predefined conditions.  The rest of
;; `once' has its own `once-examples.el' beside this file.
;;
;; Every condition is provided twice, as a variable holding the condition
;; and as a macro of the same name that runs a body with it:
;;
;;   (once-buffer (winner-mode 1))     ; the macro
;;   (once once-buffer #'winner-mode)  ; the variable, as a condition
;;
;; The variable can be used anywhere a condition list can: as the CONDITION
;; of `once' and `once-x-call', as the condition passed to
;; `once-require-FEATURE', and as the :once keyword of once-setup and
;; once-use-package.  The variable and the list it holds are
;; interchangeable.
;;
;; `once-conditions' is not loaded by `once'; the condition names below do
;; not exist until it has been required.  The internal helpers, the names
;; containing `--', are not part of the public interface and no init file
;; needs to call them.

;;; Code:

;; * Loading once-conditions
;;
;; Requiring the library defines every condition; it has to come before the
;; examples below.  The library is `once-conditions.el' in the directory of
;; that name beside this file.

'(
  (require 'once-conditions)
  ;; a condition variable is a condition: `once' and `once-x-call' take
  ;; either one
  (once once-init (display-time-mode 1))
  (once-x-call once-init #'display-time-mode))

;; The integrations take the same variable.  One or two examples are enough
;; here; every condition below works the same way in all of them, and a
;; condition list would work there too.

'(
  (use-package which-key
    :once once-input)
  (setup which-key
         (:once once-input)))

;; * The conditions
;;
;; Each heading gives the macro, the variable as a condition, and a
;; one-line statement of when the condition first becomes true.  The
;; conditions only ever run from a trigger, never while the init file is
;; still being read.

;; ** `once-init'
;;
;; True once Emacs initialization has finished, i.e. the first time
;; `after-init-hook' runs; if it already has, the body runs immediately.

'(
  (once-init (column-number-mode) (size-indication-mode))
  (once once-init (display-time-mode 1))
  (once-x-call once-init #'display-time-mode))

;; ** `once-gui'
;;
;; True once a graphical frame exists: when the first graphical frame is
;; created, or immediately if the session already has one.  It never
;; triggers in a terminal only session.

'(
  (once-gui (load-theme 'modus-operandi t))
  (once once-gui (set-face-attribute 'default nil :height 130))
  (once-x-call once-gui #'my-font-setup))

;; ** `once-tty'
;;
;; True once a terminal frame exists: when the first terminal frame is
;; created, or immediately if the session already has one.  It never
;; triggers in a graphical only session.

'(
  (once-tty (global-clipetty-mode))
  (once once-tty (xterm-mouse-mode 1))
  (once-x-call once-tty #'my-tty-setup))

;; ** `once-input'
;;
;; True before the first user input, i.e. the first time `pre-command-hook'
;; runs after startup has finished.

'(
  (once-input (which-key-mode))
  (once once-input #'which-key-mode)
  (once-x-call once-input #'which-key-mode))

;; ** `once-buffer'
;;
;; True the first time the current buffer changes after startup has
;; finished, e.g. when a file is opened; it cannot be told apart from the
;; initial redisplay.

'(
  (once-buffer (winner-mode 1))
  (once once-buffer #'winner-mode)
  (once-x-call once-buffer #'winner-mode))

;; ** `once-file'
;;
;; True the first time a file is opened after startup has finished.  A file
;; named on the command line is opened too early to count.

'(
  (once-file (recentf-mode 1))
  (once once-file #'recentf-mode)
  (once-x-call once-file #'recentf-mode))

;; ** `once-writable'
;;
;; Like `once-file', but only in a writable buffer.

'(
  (once-writable (auto-save-mode 1))
  (once once-writable #'auto-save-mode)
  (once-x-call once-writable #'auto-save-mode))

;; ** `once-evil-insert-and-writable'
;;
;; True the first time a writable buffer is put into one of the states in
;; `once-evil-insert-states' after startup has finished.  Nothing happens
;; if evil is not loaded.

'(
  (once-evil-insert-and-writable (evil-insert-state))
  (once once-evil-insert-and-writable #'my-insert-setup)
  (once-x-call once-evil-insert-and-writable #'my-insert-setup))

;; ** `once-meow-insert-and-writable'
;;
;; True the first time `meow-insert-enter-hook' runs in a writable buffer
;; after startup has finished.  Nothing happens if meow is not loaded.

'(
  (once-meow-insert-and-writable (meow-insert-mode))
  (once once-meow-insert-and-writable #'my-meow-setup)
  (once-x-call once-meow-insert-and-writable #'my-meow-setup))

;; ** `once-minibuffer'
;;
;; True the first time `minibuffer-setup-hook' runs, e.g. for `M-x' or for
;; a command that reads a file name.

'(
  (once-minibuffer (which-key-mode))
  (once once-minibuffer #'which-key-mode)
  (once-x-call once-minibuffer #'which-key-mode))

;; ** `once-save'
;;
;; True the first time a buffer is saved, i.e. the first time
;; `after-save-hook' runs.

'(
  (once-save (my-save-setup))
  (once once-save #'my-save-setup)
  (once-x-call once-save #'my-save-setup))

;; ** `once-edit'
;;
;; True the first time the text of the current buffer changes, i.e. the
;; first time `first-change-hook' runs.

'(
  (once-edit (auto-save-mode 1))
  (once once-edit #'auto-save-mode)
  (once-x-call once-edit #'auto-save-mode))

;; ** `once-directory'
;;
;; True the first time a directory is visited with Dired.  The trigger is
;; `:before' advice on the `dired' function rather than a Dired hook, so
;; dired does not have to be loaded for the condition to be set up.

'(
  (once-directory (dired-hide-details-mode 1))
  (once once-directory #'dired-hide-details-mode)
  (once-x-call once-directory #'dired-hide-details-mode))

;; ** `once-search'
;;
;; True the first time an incremental search starts, i.e. the first time
;; `isearch-mode-hook' runs.

'(
  (once-search (my-isearch-setup))
  (once once-search #'my-isearch-setup)
  (once-x-call once-search #'my-isearch-setup))

;; ** `once-prog'
;;
;; True the first time a programming mode is entered, i.e. the first time
;; `prog-mode-hook' runs.  Every mode derived from `prog-mode' runs it.

'(
  (once-prog (eglot-ensure))
  (once once-prog #'eglot-ensure)
  (once-x-call once-prog #'eglot-ensure))

;; ** `once-theme'
;;
;; True the first time a theme is enabled, i.e. the first time
;; `enable-theme-functions' runs.  `load-theme' and `enable-theme' run it
;; with the theme as argument.

'(
  (once-theme (my-theme-setup))
  (once once-theme #'my-theme-setup)
  (once-x-call once-theme #'my-theme-setup))

;; ** `once-second-frame'
;;
;; True once a second frame exists, i.e. the first time
;; `after-make-frame-functions' runs while more than one frame is live.
;; The local check counts `frame-list' rather than looking at the frame it
;; is passed, because that frame may not be selected yet.

'(
  (once-second-frame (my-second-frame-setup))
  (once once-second-frame #'my-second-frame-setup)
  (once-x-call once-second-frame #'my-second-frame-setup))

;; ** `once-client-frame'
;;
;; True once the server creates a client frame, i.e. the first time
;; `server-after-make-frame-hook' runs, which is after a frame made for an
;; emacsclient connection has been selected.

'(
  (once-client-frame (my-client-frame-setup))
  (once once-client-frame #'my-client-frame-setup)
  (once-x-call once-client-frame #'my-client-frame-setup))

;; ** `once-mouse'
;;
;; True the first time the user performs a mouse event, i.e. the first
;; time `pre-command-hook' runs with a mouse event in
;; `last-command-event'.  The local check sees that event, so it fires on
;; the first click or wheel event rather than on the first key press.

'(
  (once-mouse (mouse-avoidance-mode 1))
  (once once-mouse #'mouse-avoidance-mode)
  (once-x-call once-mouse #'mouse-avoidance-mode))

;; ** `once-remote-file'
;;
;; True the first time a remote file is opened.  The local check is
;; `:before' advice on `find-file' and sees the file argument it is called
;; with, so it fires only when `file-remote-p' is true for it.

'(
  (once-remote-file (my-remote-file-setup))
  (once once-remote-file #'my-remote-file-setup)
  (once-x-call once-remote-file #'my-remote-file-setup))

;; ** `once-large-file'
;;
;; True the first time a large file is opened.  The local check runs from
;; `find-file-hook' and looks at the state of the current buffer, so it
;; fires when the buffer is bigger than `large-file-warning-threshold' (or
;; than a million characters when that is nil).

'(
  (once-large-file (so-long-mode))
  (once once-large-file #'so-long-mode)
  (once-x-call once-large-file #'so-long-mode))

;; ** `once-ime'
;;
;; True the first time an input method is activated, i.e. the first time
;; `input-method-activate-hook' runs, just after an input method is turned on
;; in a buffer.  It fires for any input method, not for one in particular.

'(
  (once-ime (my-ime-setup))
  (once once-ime #'my-ime-setup)
  (once-x-call once-ime #'my-ime-setup))

;; ** `once-mark'
;;
;; True the first time a region becomes active, i.e. the first time
;; `activate-mark-hook' runs, e.g. after a command sets the mark or after a
;; region is selected with the mouse.

'(
  (once-mark (my-mark-setup))
  (once once-mark #'my-mark-setup)
  (once-x-call once-mark #'my-mark-setup))

;; ** `once-elisp'
;;
;; True the first time an Emacs Lisp buffer is set up, i.e. the first time
;; `emacs-lisp-mode-hook' runs.  Modes derived from `emacs-lisp-mode', such
;; as `lisp-interaction-mode', run it as well.

'(
  (once-elisp (my-elisp-setup))
  (once once-elisp #'my-elisp-setup)
  (once-x-call once-elisp #'my-elisp-setup))

;; ** `once-project'
;;
;; True the first time a file inside a project is opened.  The local check
;; runs from `find-file-hook' with the buffer current, which is how it can
;; ask `project-current' about the file's buffer; a file visited outside any
;; project does not fire it.

'(
  (once-project (my-project-setup))
  (once once-project #'my-project-setup)
  (once-x-call once-project #'my-project-setup))

;; ** `once-debugger'
;;
;; True the first time the debugger is entered.  The trigger is `:before'
;; advice on the `debug' function rather than a debugger hook, so the
;; debugger does not have to be loaded for the condition to be set up.

'(
  (once-debugger (my-debugger-setup))
  (once once-debugger #'my-debugger-setup)
  (once-x-call once-debugger #'my-debugger-setup))

;; ** `once-kill'
;;
;; True the first time something is added to the kill ring.  The trigger is
;; `:before' advice on the `kill-new' function rather than a kill hook, so
;; nothing has to be loaded for the condition to be set up; it fires for a
;; direct call to `kill-new' just as much as for a kill command.

'(
  (once-kill (my-kill-setup))
  (once once-kill #'my-kill-setup)
  (once-x-call once-kill #'my-kill-setup))

;; * Settings

;; ** `once-evil-insert-states'
;;
;; The evil states treated as insert states.  It is a list of state
;; symbols, `(insert emacs)' by default, and only
;; `once-evil-insert-and-writable' consults it.  That condition builds its
;; state entry hooks when `once-conditions' is loaded, so the option has to
;; be set before the library is required.

'(
  (setq once-evil-insert-states '(insert emacs))
  ;; for example, treat evil replace state as an insert state as well
  (setq once-evil-insert-states '(insert emacs replace)))

;; ** `once-startup-finished-p'
;;
;; Non-nil once the startup sequence has completely finished.  The value
;; comes from `window-setup-hook', which runs after `init.el',
;; `after-init-hook', and `emacs-startup-hook'.  It is what the interaction
;; conditions use to keep from running during startup, and init code can
;; read it to tell startup apart from a later call.  It is a plain variable,
;; not a condition, so pass `once-input' and friends to `once' instead.

'(
  (when once-startup-finished-p
    (my-late-setup)))

(provide 'once-conditions-examples)
;;; once-conditions-examples.el ends here
