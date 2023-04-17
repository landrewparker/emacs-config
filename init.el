;;; package --- init.el

;;; Commentary:

;;; Code:

;; FIXME: Required for emacs-29 which renamed
;;   native-comp-deferred-compilation-deny-list
;; to
;;   native-comp-jit-compilation-deny-list
;; in emacs#95692f6. Remove when emacs-29 is released.
(setq straight-repository-branch "develop")

;; Bootstrap straight.el
;; (See https://github.com/radian-software/straight.el#getting-started)
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
(require 'straight)

;; benchmark-init
(straight-use-package 'benchmark-init)
(require 'benchmark-init)
(add-hook 'after-init-hook 'benchmark-init/deactivate)

;; use-package
(straight-use-package 'use-package)

;; emacs
(use-package emacs
  :custom
  (column-number-mode t)
  (compilation-scroll-output 'first-error)
  (confirm-kill-emacs 'y-or-n-p)
  (ediff-window-setup-function 'ediff-setup-windows-plain)
  (help-window-select t)
  (indent-tabs-mode nil)
  (inhibit-startup-screen t)
  (native-comp-async-report-warnings-errors 'silent)
  (require-final-newline 'query)
  (sh-alias-alist '((garden-exec . bash)))
  (size-indication-mode t)

  :init
  ;; Variables
  (defvar lap/ediff-last-window-configuration nil
    "The last window configuration before ediff started.")

  ;; Functions
  (defun lap/ediff-save-window-configuration ()
    "Save the last window configuration before starting ediff."
    (setq lap/ediff-last-window-configuration (current-window-configuration)))

  (defun lap/ediff-restore-window-configuration ()
    "Restore the last window configuration before starting ediff."
    (set-window-configuration lap/ediff-last-window-configuration))

  (defun lap/frame-background-mode-light ()
    "Tell Emacs the background is a light color."
    (interactive)
    (let ((frame-background-mode 'light)) (frame-set-background-mode nil)))

  (defun lap/log-handler ()
    "Settings for log files."
    (goto-char (point-max))
    (read-only-mode t))

  (defun lap/previous-window ()
    "Switch to previous window."
    (interactive)
    (other-window -1))

  (defun lap/setup-flymake-python ()
    "Setup flymake for Python mode."
    (interactive)
    (add-hook 'flymake-diagnostic-functions 'flymake-collection-pylint nil t)
    (add-hook 'flymake-diagnostic-functions 'flymake-collection-flake8 nil t)
    (flymake-mode))

  (defun lap/show-trailing-whitespace ()
    "Enable showing trailing whitespace."
    (setq show-trailing-whitespace t))

  ;; GUI
  (unless (and (eq system-type 'darwin) (display-graphic-p))
    ;; Menu bar is not intrusive on MacOS
    (menu-bar-mode -1))
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (setq
   tab-bar-new-button nil
   tab-bar-close-button nil)
  (when (display-graphic-p)
    ;; The fixed-pitch face extends default face implicitly but sets
    ;; family to Monospace. Make it use default's family instead. There
    ;; are other faces like this which might need to be set as well,
    ;; e.g. variable-pitch sets family to Sans Serif.
    (set-face-attribute 'fixed-pitch nil :family (face-attribute 'default :family)))
  (unless (display-graphic-p)
    ;; Get a solid vertical border with unicode light vertical line
    (set-display-table-slot standard-display-table 'vertical-border ?│)
    ;; Remove hyphens from the end of mode line
    (setq mode-line-end-spaces nil))

  ;; garden-exec header matching
  (let ((garden-exec-regex
         "#!/usr/bin/garden-exec.*\n#{.*\n\\(# garden .*\n\\)*# \\(exec \\)?")
        (garden-mode-alist '(("python" . python-mode)
                             ("bash" . shell-script-mode))))
    (dolist (mode garden-mode-alist)
      (add-to-list 'magic-fallback-mode-alist
                   (cons (concat garden-exec-regex (car mode)) (cdr mode)))))

  ;; Load paths
  (add-to-list 'load-path "~/lib/emacs/")
  (add-to-list 'custom-theme-load-path "~/lib/emacs")

  :hook
  ((ediff-before-setup . lap/ediff-save-window-configuration)
   (ediff-prepare-buffer . outline-show-all)
   (ediff-quit . lap/ediff-restore-window-configuration)
   ((prog-mode text-mode) . hl-line-mode)
   ((prog-mode text-mode) . lap/show-trailing-whitespace))

  :bind
  (("C-c ;" . comment-line)  ; C-; is note available in terminals
   ("C-c c" . compile)
   ("C-c p" . lap/previous-window)
   ("C-c r" . revert-buffer)))

;; ace-window
(use-package ace-window
  :straight t
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (aw-background nil)
  :bind ("M-o" . ace-window))

;; all-the-icons
;; (use-package all-the-icons
;;   :straight t
;;   :if (display-graphic-p))

;; auto-revert
(use-package autorevert
  :straight (:type built-in)
  :diminish auto-revert-mode
  :mode
  ("\\.log\\'" . auto-revert-tail-mode)
  :hook
  (auto-revert-tail-mode . lap/log-handler))

;; consult
(use-package consult
  :straight t
  :bind
  (("C-x b" . consult-buffer)
   ("M-g g" . consult-goto-line)
   ("M-s f" . consult-find)
   ("M-s g" . consult-grep)
   ("M-s G" . consult-git-grep)
   ("M-s l" . consult-line)
   ("M-s r" . consult-ripgrep)))

;; corfu
(use-package corfu
  :straight t
  :custom (corfu-auto t)
  :init (global-corfu-mode))

;; corfu-terminal
(use-package corfu-terminal
  :straight t
  :if (not (display-graphic-p))
  :init (corfu-terminal-mode +1))

;; diminish
(use-package diminish
  :straight t
  :defer t)

;; dired
(use-package dired
  :straight (:type built-in)
  :preface
  (defvar lap/list-of-dired-switches
    (if (eq system-type 'darwin)
        '(("-Ahl" . "almost all")
          ("-hl" . "no dotfiles"))
      '(("--almost-all --dired --human-readable -l" . "almost all")
        ("--dired --human-readable -l" . "no dotfiles")))
    "List of Dired ls switches and names for the mode line.")

  (defun lap/dired-ediff-files ()
    "Ediff marked files, or ask for a file"
    (interactive)
    (let ((files (dired-get-marked-files)))
      (if (<= (length files) 2)
          (let ((file1 (car files))
                (file2 (if (cdr files)
                           (cadr files)
                         (read-file-name
                          "file: "
                          (dired-dwim-target-directory)))))
            (if (file-newer-than-file-p file1 file2)
                (ediff-files file2 file1)
              (ediff-files file1 file2)))
        (error "No more than 2 files should be marked"))))

  :custom
  (dired-listing-switches (caar lap/list-of-dired-switches))
  :hook
  (dired-mode . hl-line-mode)
  :bind (:map dired-mode-map
              ("C-c s" . lap/cycle-dired-switches)
              ("C-c =" . lap/dired-ediff-files))
  :config
  (defun lap/cycle-dired-switches ()
    "Cycle through `lap/list-of-dired-switches'."
    (interactive)
    (setq lap/list-of-dired-switches
          (append (cdr lap/list-of-dired-switches)
                  (list (car lap/list-of-dired-switches))))
    (dired-sort-other (caar lap/list-of-dired-switches))
    (setq mode-name (concat "Dired " (cdar lap/list-of-dired-switches)))
    (force-mode-line-update)))

;; doom modeline
;; (use-package doom-modeline
;;   :straight t
;;   :config (doom-modeline-mode))

;; ef-themes
(use-package ef-themes
  :straight t
  :defer t)

;; eglot
(use-package eglot
  :straight t  (:type built-in)
  :defer t
  :config
  (add-to-list 'eglot-server-programs
               '(verilog-mode . ("svls"))))

;; eldoc
(use-package eldoc
  :straight t (:type built-in)
  :diminish)

;; embark
(use-package embark
  :straight t
  :bind
  (("C-c e a" . embark-act)
   ("C-c e d" . embark-dwim)
   ("C-c e B" . embark-bindings)))

;; embark-consult
(use-package embark-consult
  :straight t
  :after (embark consult))

;; flymake
(use-package flymake
  :straight t  ; FIXME: Use built-in version when ready
  :custom
  (flymake-no-changes-timeout 2)
  (python-flymake-command nil)
  :config
  (setq elisp-flymake-byte-compile-load-path load-path)
  :hook
  (emacs-lisp-mode . flymake-mode)
  (python-mode . lap/setup-flymake-python)
  :bind
  (:map flymake-mode-map
        ("M-n" . flymake-goto-next-error)
        ("M-p" . flymake-goto-prev-error)))

;; flymake-collection
(use-package flymake-collection
  :straight t
  :defer t)

;; ispell (aspell)
(use-package ispell
  :straight t (:type built-in)
  :custom
  (ispell-program-name "aspell")
  (ispell-extra-args
   (append
    '("--sug-mode=ultra")
    ;; New versions of aspell support --camel-case
    (when (string-match-p
           "--.*camel-case"
           (shell-command-to-string "aspell --help"))
      '("--camel-case")))))

;; json-mode
(use-package json-mode
  :straight t
  :defer t)

;; magit
(use-package magit
  :straight t
  :bind ("C-c g" . magit-file-dispatch))

;; marginalia
(use-package marginalia
  :straight t
  :config (marginalia-mode))

;; markdown
(use-package markdown-mode
  :straight t
  :defer t)

;; modus-themes
(use-package modus-themes
  :straight t
  :defer)

;; nord-theme
;;
;; Use my fork to fix he trailing whitespace background. See:
;; https://github.com/arcticicestudio/nord-emacs/issues/79.
;;
(straight-use-package '(nord-theme
  :host github
  :repo "landrewparker/nord-emacs"
  :branch "develop"))

;; orderless
(use-package orderless
  :straight t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; org
(use-package org
  :straight (:type built-in)
  :custom
  (org-babel-load-languages '((C . t)
                              (emacs-lisp . t)
                              (python . t)
                              (shell . t)))
  (org-babel-python-command "python3")
  (org-startup-indented t)
  :hook
  (org-mode . visual-line-mode))

;; pdf-tools
(use-package pdf-tools
  :straight t
  :magic ("%PDF" . pdf-view-mode))

;; python
(use-package python
  :straight (:type built-in)
  :defer t
  :custom
  (python-shell-interpreter "ipython3")
  (python-shell-interpreter-args "--simple-prompt"))

;; savehist
(use-package savehist
  :straight (:type built-in)
  :config (savehist-mode))

;; saveplace
(use-package saveplace
  :straight (:type built-in)
  :config (save-place-mode))

;; server
(use-package server
  :straight (:type built-in)
  :config
  (unless (server-running-p)
    (server-start)))

;; shell
(use-package shell
  :straight (:type built-in)
  :init
  (defun lap/shell-mode-setup ()
    "Tell comint that zsh will echo."
    (if (string-equal shell--start-prog "zsh")
        (setq-local comint-process-echoes t)))
  :hook
  (shell-mode . lap/shell-mode-setup))

;; tcl
(use-package tcl
  :straight (:type built-in)
  :mode
    (("\\.do\\'" . tcl-mode)
     ("\\.f\\'" . tcl-mode)))

;; transpose-frame
(use-package transpose-frame
  :straight t
  :defer t)

;; tramp
(use-package tramp
  :straight (:type built-in)
  :defer t
  :config
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

;; tree-sitter
(use-package tree-sitter
  :straight t  ; FIXME: Use built-in version when ready
  :hook (tree-sitter-after-on . tree-sitter-hl-mode)
  :init (global-tree-sitter-mode))

(use-package tree-sitter-langs
  :straight t
  :after tree-sitter)

;; verilog-mode
(use-package verilog-mode
  :straight t
  :defer t
  :custom
  (verilog-auto-newline nil))

;; vertico
(use-package vertico
  :straight t
  :config (vertico-mode))

;; vscode-dark-plus-theme
(use-package vscode-dark-plus-theme
  :straight t
  :defer t)

;; wgrep
(use-package wgrep
  :straight t
  :defer t)

;; which-key
(use-package which-key
  :straight t
  :diminish
  :config (which-key-mode))

;; yaml-mode
(use-package yaml-mode
  :straight t
  :defer t)

;; yasnippet
(use-package yasnippet
  :straight t
  :diminish yas-minor-mode
  :config (yas-global-mode))

;;; init.el ends here
