;;; package --- init.el

;;; Commentary:

;;; Code:

;; Functions
(defun lap/disable-all-themes ()
  "Disable all enabled themes."
  (interactive)
  (mapc #'disable-theme custom-enabled-themes))

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
  (add-hook 'flymake-diagnostic-functions 'flymake-collection-pylint nil t)
  (add-hook 'flymake-diagnostic-functions 'flymake-collection-flake8 nil t)
  (flymake-mode))

(defun lap/switch-to-theme (theme)
  "Switch to THEME.  Disable all other active themes."
  (interactive
   (list
    (intern (completing-read
             "Switch to theme: "
             (mapcar 'symbol-name (custom-available-themes))))))
  (lap/disable-all-themes)
  (load-theme theme t))

(defun lap/show-trailing-whitespace ()
  "Enable showing trailing whitespace."
  (setq show-trailing-whitespace t))

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

;; use-package
(straight-use-package 'use-package)
(require 'use-package)

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
  (size-indication-mode t)

  :init
  ;; GUI
  (unless (and (eq system-type 'darwin) (display-graphic-p))
    ;; Menu bar is not intrusive on MacOS
    (menu-bar-mode -1))
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (setq
   tab-bar-new-button nil
   tab-bar-close-button nil)
  (when (eq system-type 'darwin)
    (add-to-list 'default-frame-alist '(font . "SF Mono 12")))
  (when (display-graphic-p)
    ;; The fixed-pitch face extends default face implicitly but sets
    ;; family to Monospace. Make it use default's family instead. There
    ;; are other faces like this which might need to be set as well,
    ;; e.g. variable-pitch sets family to Sans Serif.
    (set-face-attribute 'fixed-pitch nil :family (face-attribute 'default :family)))
  (unless (display-graphic-p)
    ;; Get a solid vertical border with unicode light vertical line
    (set-display-table-slot standard-display-table 'vertical-border ?│))

  ;; Load paths
  (add-to-list 'load-path "~/lib/emacs/")
  (add-to-list 'custom-theme-load-path "~/lib/emacs")

  :hook
  ((ediff-prepare-buffer . outline-show-all)
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
(use-package all-the-icons
  :straight t
  :if (display-graphic-p))

;; auto-revert
(use-package autorevert
  :straight (:type built-in)
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
  :config (global-corfu-mode))

;; corfu-terminal
(use-package corfu-terminal
  :straight t
  :if (not (display-graphic-p))
  :config (corfu-terminal-mode +1))

;; diminish
(use-package diminish
  :straight t)

;; dired
(use-package dired
  :straight (:type built-in)
  :preface
  (defvar
    lap/list-of-dired-switches
    (if (eq system-type 'darwin)
        '(("-Ahl" . "almost all")
          ("-hl" . "no dotfiles"))
      '(("--almost-all --dired --human-readable -l" . "almost all")
        ("--dired --human-readable -l" . "no dotfiles")))
    "List of Dired ls switches and names for the mode line.")
  :custom
  (dired-listing-switches (caar lap/list-of-dired-switches))
  :hook
  (dired-mode . hl-line-mode)
  :bind (:map dired-mode-map
              ("C-c s" . lap/cycle-dired-switches))
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
  :straight t)

;; eglot
(use-package eglot
  :straight t
  :init
  ;; Keep eglot from removing other flymake backends.
  ;;
  ;; Pyright doesn't do linting with flake8 and pylint. So I want them
  ;; to still run with flymake. Eglot takes over managing the buffer
  ;; though, so it removes the flymake backends I'm using for flake8
  ;; and pylint.  It also removes flymake from eldoc. This workaround
  ;; just tells eglot to leave flymake backends alone. It doesn't keep
  ;; eglot from messing with eldoc though, which prevents flymake
  ;; messages from displaying in the minibuffer. So we need to
  ;; manually add the eglot backend for flymake and also re-add
  ;; flymake to eldoc. Maybe there's a better way?
  ;;
  (setq eglot-stay-out-of '(flymake))
  (defun lap/fix-eglot-flymake ()
    ;; Manually add the flymake backend for eglot
    (add-hook 'flymake-diagnostic-functions 'eglot-flymake-backend nil t)
    ;; Undo eglot removal of flymake from eldoc
    (add-hook 'eldoc-documentation-functions 'flymake-eldoc-function nil t))
  :hook
  ;; Manually add the flymake eglot backend
  (eglot-managed-mode . lap/fix-eglot-flymake))

;; embark
(use-package embark
  :straight t
  :bind
  (("C-c e a"  .  'embark-act)
   ("C-c e d"  .  'embark-dwim)
   ("C-c e B"  .  'embark-bindings)))

;; embark-consult
(use-package embark-consult
  :straight t
  :after (embark consult))

;; flymake
(use-package flymake
  :straight t  (:type built-in)
  :custom
  (flymake-no-changes-timeout 2)
  :config
  (setq elisp-flymake-byte-compile-load-path load-path)
  :hook
  (emacs-lisp-mode . flymake-mode)
  (python-mode . lap/setup-flymake-python)
  :bind
  (:map flymake-mode-map
        ("M-n" . 'flymake-goto-next-error)
        ("M-p" . 'flymake-goto-prev-error)))

;; flymake-collection
(use-package flymake-collection
  :straight t)

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
  :straight t)

;; magit
(use-package magit
  :straight t)

;; marginalia
(use-package marginalia
  :straight t
  :config (marginalia-mode))

;; modus-themes
(use-package modus-themes
  :straight t
  :config (modus-themes-load-themes))

;; nord-theme
;;
;; Use my fork to fix he trailing whitespace background. See:
;; https://github.com/arcticicestudio/nord-emacs/issues/79.
;;
(straight-use-package '(nord-theme
  :host github
  :repo "landrewparker/nord-emacs"
  :branch "develop"))
(load-theme 'nord t)

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
                              (python . t)))
  (org-startup-indented t)
  :hook
  (org-mode . visual-line-mode))

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
  :straight t)

;; tramp
(use-package tramp
  :straight (:type built-in)
  :config
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

;; tree-sitter
(use-package tree-sitter
  :straight t  ;; Fixme: Use built-in version when ready
  :hook (tree-sitter-after-on . tree-sitter-hl-mode)
  :init (global-tree-sitter-mode))

(use-package tree-sitter-langs
  :straight t
  :after tree-sitter)

;; verilog-mode
(use-package verilog-mode
  :straight t
  :custom
  (verilog-auto-newline nil))

;; vertico
(use-package vertico
  :straight t
  :config (vertico-mode))

;; vscode-dark-plus-theme
(use-package vscode-dark-plus-theme
  :straight t)

;; wgrep
(use-package wgrep
  :straight t)

;; which-key
(use-package which-key
  :straight t
  :diminish
  :config (which-key-mode))

;; yaml-mode
(use-package yaml-mode
  :straight t)

;;; init.el ends here
