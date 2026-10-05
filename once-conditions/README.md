# once-conditions

Predefined conditions for once.el.

once-conditions.el is the file the once README has always referenced but
that has never been published upstream: a fresh clone of the repository
and its entire history contain no such file.  It is a local
reconstruction.  It provides predefined `once' conditions for the
situations that come up over and over again in an init file, e.g. "run
this once the first graphical frame exists" or "run this once the user
opens the first file".  They are the `once' equivalents of Doom's
`doom-first-*-hook' hooks and on.el's `on-first-*-hook' hooks, except
that no new hooks are created.

Every condition is provided as both a variable and a macro of the same
name (Elisp keeps the value cell and the function cell separate):

  ;; as a variable - a condition for any place that accepts one
  (use-package winner
    :once once-buffer)

  ;; as a macro - run BODY once the condition is met
  (once-buffer
    (winner-mode))

With setup.el, the condition is simply the first keyword argument:

  (setup (:package winner)
    (:once once-buffer))

The conditions only ever run their code from a trigger, never while
the init file is still being read.  `once' installs a condition's
triggers as soon as it is handed one, which is during startup, while
on.el only installs its triggers at the very end of startup.  To make
up for that, the interaction based conditions
(`once-input', `once-buffer', `once-file', `once-writable', and
`once-evil-insert-and-writable') use a triggering check that only
succeeds after startup has completely finished.  `once-gui',
`once-tty', and `once-init' instead describe a state that may already
hold, so they can run immediately as documented.

The conditions replace the hand written equivalents that predate this
file.  They use the same triggers on purpose:

  once-init    -> general-after-init
  once-gui     -> general-after-gui
  once-tty     -> general-after-tty
  once-input   -> (add-hook 'pre-command-hook ...)
  once-buffer  -> on-first-buffer-hook, i.e. the old
                  `on-switch-buffer-hook' (window-buffer-change-functions
                  plus server-visit-hook) plus after-find-file advice
  once-file    -> on-first-file-hook (after-find-file advice plus
                  dired-initial-position-hook)
  once-writable-> like once-file but gated on buffer-read-only
  once-evil-insert-and-writable
               -> evil-insert-state-entry-hook gated on buffer-read-only

`once-meow-insert-and-writable' is an addition rather than a
reconstruction; it is the same idea for meow's `meow-insert-enter-hook'.

## API

| Symbol | Type |
| --- | --- |
| `once-evil-insert-states` | `defcustom` |
| `once-startup-finished-p` | `defvar` |
| `once-conditions--mark-startup-finished` | `defun` |
| `once-conditions--startup-finished-p` | `defun` |
| `once-conditions--initialized-p` | `defun` |
| `once-conditions--writable-p` | `defun` |
| `once-conditions--graphic-frame-p` | `defun` |
| `once-conditions--terminal-frame-p` | `defun` |
| `once-conditions--evil-insert-writable-p` | `defun` |
| `once-conditions--evil-insert-hooks` | `defun` |
| `once-init` | `defvar` |
| `once-init` | `defmacro` |
| `once-gui` | `defvar` |
| `once-gui` | `defmacro` |
| `once-tty` | `defvar` |
| `once-tty` | `defmacro` |
| `once-input` | `defvar` |
| `once-input` | `defmacro` |
| `once-buffer` | `defvar` |
| `once-buffer` | `defmacro` |
| `once-file` | `defvar` |
| `once-file` | `defmacro` |
| `once-writable` | `defvar` |
| `once-writable` | `defmacro` |
| `once-evil-insert-and-writable` | `defvar` |
| `once-evil-insert-and-writable` | `defmacro` |
| `once-meow-insert-and-writable` | `defvar` |
| `once-meow-insert-and-writable` | `defmacro` |

## Tests

The conditions are tested with ERT in `tests/test-once-conditions.el`:

```sh
# run from the drone root
emacs --batch -L . -L once-setup -L once-conditions -L tests \
  -l tests/test-once-conditions.el -f ert-run-tests-batch-and-exit
```

The tests do not skip themselves; they require this library directly, so
the drone root and `once-conditions/` have to be on `load-path'.  The run
should report `0 unexpected` and no skipped tests.
