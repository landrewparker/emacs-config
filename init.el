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

(require 'shell)
(defun lap/shell-mode-setup ()
  "Tell comint that zsh will echo."
  (if (string-equal shell--start-prog "zsh")
      (setq-local comint-process-echoes t)))

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
  (ispell-program-name "aspell")
  (native-comp-async-report-warnings-errors 'silent)
  (require-final-newline 'query)
  (size-indication-mode t)

  :init
  ;; GUI
  (unless (and (eq system-type 'darwin) (display-graphic-p))
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

  ;; Load paths
  (add-to-list 'load-path "~/lib/emacs/")
  (add-to-list 'custom-theme-load-path "~/lib/emacs")

  :hook
  ((ediff-prepare-buffer . show-all)
   (prog-mode . hl-line-mode)
   (prog-mode . lap/show-trailing-whitespace)
   (shell-mode . lap/shell-mode-setup)
   (text-mode . hl-line-mode)
   (text-mode . lap/show-trailing-whitespace))

  :bind
  (("C-c c" . compile)
   ("C-c p" . lap/previous-window)
   ("C-c r" . revert-buffer))

  :config
  ;; Minor modes
  (savehist-mode)
  (save-place-mode))

;; ace-window
(use-package ace-window
  :straight t
  :bind ("M-o" . ace-window)
  :init
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (setq aw-background nil))

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
  :init (global-corfu-mode))

;; corfu-terminal
(use-package corfu-terminal
  :straight t
  :if (not (display-graphic-p))
  :config (corfu-terminal-mode +1))

;; diminish
(straight-use-package 'diminish)

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
(use-package doom-modeline
  :straight t
  :config (doom-modeline-mode))

;; ef-themes
(straight-use-package 'ef-themes)

;; embark
(use-package embark
  :straight t
  :bind
  ("C-c e a"  .  'embark-act)
  ("C-c e d"  .  'embark-dwim)
  ("C-c e B"  .  'embark-bindings))

;; embark-consult
(use-package embark-consult
  :straight t
  :ensure t
  :after (embark consult))

;; flycheck
(use-package flycheck
  :straight t
  :init
  (setq flycheck-emacs-lisp-load-path 'inherit)
  (setq flycheck-disabled-checkers '(python-pylint python-mypy))
  :hook
  (lsp-after-initialize
   . (lambda () (flycheck-add-next-checker 'lsp 'python-flake8)))
  :config
  (global-flycheck-mode))

;; json-mode
(straight-use-package 'json-mode)

;; lsp-mode
(use-package lsp-mode
  :straight t
  :commands lsp

  :custom
  (lsp-completion-provider :none)  ; Use corfu

  :init
  (defun lap/setup-lsp-mode-completion ()
    "Use orderless completion with corfu."
    (setf (alist-get
           'styles
           (alist-get 'lsp-capf completion-category-defaults))
          '(orderless)))

  (setq lsp-keymap-prefix "C-c l")
  (setq lsp-enable-snippet nil)

  :hook
  ((verilog-mode . lsp)
   (lsp-mode . lsp-enable-which-key-integration)
   (lsp-completion-mode . lap/setup-lsp-mode-completion))

  :config
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection '("svls"))
    :major-modes '(verilog-mode)
    :priority -1))
  (add-to-list 'lsp-language-id-configuration '(verilog-mode . "verilog")))
  ;; TODO: Is the necessary?
  ;; (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]desres-python\\'"))

;; lsp-pyright
(use-package lsp-pyright
  :straight t
  :hook
  (python-mode . (lambda ()
                   (require 'lsp-pyright)
                   (lsp))))

;; lsp-ui
(use-package lsp-ui
  :straight t
  :commands lsp-ui-mode)

;; magit
(use-package magit
  :straight t)

;; marginalia
(use-package marginalia
  :straight t
  :init (marginalia-mode))

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

;; server
(use-package server
  :straight (:type built-in)
  :config
  (unless (server-running-p)
    (server-start)))

;; transpose-frame
(straight-use-package 'transpose-frame)

;; verilog-mode
(use-package verilog-mode
  :straight t
  :custom
  (verilog-auto-newline nil))

;; tcl
(use-package tcl
  :straight (:type built-in)
  :mode
    (("\\.do\\'" . tcl-mode)
     ("\\.f\\'" . tcl-mode)))

;; tramp
(use-package tramp
  :straight (:type built-in)
  :config
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

;; tree-sitter
(use-package tree-sitter
  :straight t
  :init (global-tree-sitter-mode)
  :hook (tree-sitter-after-on . tree-sitter-hl-mode))

(use-package tree-sitter-langs
  :straight t
  :after tree-sitter)

;; vertico
(use-package vertico
  :straight t
  :init (vertico-mode))

;; vscode-dark-plus-theme
(straight-use-package 'vscode-dark-plus-theme)

;; vterm
(straight-use-package 'vterm)

;; wgrep
(straight-use-package 'wgrep)

;; which-key
(use-package which-key
  :straight t
  :diminish
  :init (which-key-mode))

;; yaml-mode
(straight-use-package 'yaml-mode)

;;; init.el ends here
