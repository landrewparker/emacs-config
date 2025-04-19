;;; package --- init.el  -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

;; Bootstrap Elpaca
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Declare use-package
(eval-when-compile
  (require 'use-package))
;; (setq use-package-verbose t)
;; (setq use-package-compute-statistics t)

;; Install elpaca use-package support and enable :ensure keyword
(elpaca elpaca-use-package
  (elpaca-use-package-mode))
(elpaca-wait)

;; Make diminish available for use-package :diminish
(use-package diminish
  :ensure (:wait t))

;; emacs
(use-package emacs
  :custom
  (column-number-mode t)
  (compilation-scroll-output 'first-error)
  (confirm-kill-emacs 'y-or-n-p)
  (help-window-select t)
  (help-at-pt-display-when-idle t)
  (indent-tabs-mode nil)
  (inhibit-startup-screen t)
  (isearch-lazy-count t)
  (native-comp-async-report-warnings-errors 'silent)
  (repeat-mode t)
  (require-final-newline 'query)
  (size-indication-mode t)

  :init
  (defun lap/frame-background-mode-light ()
    "Tell Emacs the background is a light color."
    (interactive)
    (let ((frame-background-mode 'light)) (frame-set-background-mode nil)))

  (defun lap/log-handler ()
    "Settings for log files."
    (goto-char (point-max))
    (read-only-mode t)
    (hl-line-mode))

  (defun lap/previous-window ()
    "Switch to previous window."
    (interactive)
    (other-window -1))

  (defun lap/set-terminal-cursor-color-to-theme ()
    "Set the terminal's cursor color to match the theme's cursor color."
    (interactive)
    (let ((cursor-color (face-background 'cursor nil t)))
      (when cursor-color
        (send-string-to-terminal (concat "\033]12;" cursor-color "\007")))))

  (defun lap/show-trailing-whitespace ()
    "Enable showing trailing whitespace."
    (setq show-trailing-whitespace t))

  ;; GUI
  (unless (and (eq system-type 'darwin) (display-graphic-p))
    ;; Menu bar is not intrusive on macOS in GUI mode
    (menu-bar-mode -1)
    ;; I hit this by accident sometimes and on dwm I don't know how to
    ;; recover from suspend-frame. The GUI freezes and sending CONT or
    ;; resizing the window doesn't help. On macOS it just iconifies
    ;; the window, which is what is supposed to happen. You can still
    ;; use C-x C-z.
    (global-unset-key (kbd "C-z")))
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

  ;; Load paths
  (add-to-list 'load-path "~/lib/emacs/")
  (add-to-list 'custom-theme-load-path "~/lib/emacs")

  :hook
  (((prog-mode text-mode) . hl-line-mode)
   ((prog-mode text-mode) . lap/show-trailing-whitespace))

  :bind
  (("C-c ;" . comment-line)  ; C-; is note available in terminals
   ("C-c c" . compile)
   ("C-c p" . lap/previous-window)
   ("C-c r" . revert-buffer)
   ("C-c y" . mouse-yank-primary)))

;; ace-window
(use-package ace-window
  :ensure t
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (aw-scope 'frame)
  :bind
  (("M-o" . ace-window)
   ("C-c 0" . ace-delete-window))
  :config
  (ace-window-display-mode)
  :custom-face
  ;; Restrict themes from using big faces to prevent jumpy buffer text
  (aw-leading-char-face ((t (:height 1.0)))))

;; all-the-icons
(use-package all-the-icons
  :ensure (:depth 1)
  :if (display-graphic-p)
  :after doom-modeline-mode)

;; auto-revert
(use-package autorevert
  :custom
  (auto-revert-use-notify nil)
  :diminish auto-revert-mode
  :mode
  (("\\.log\\'" . auto-revert-tail-mode)
   ("\\.out\\'" . auto-revert-tail-mode)
   ("\\.err\\'" . auto-revert-tail-mode))
  :hook
  (auto-revert-tail-mode . lap/log-handler))

;; avy
(use-package avy
  :ensure t
  :bind ("C-'" . avy-goto-char-timer))

;; transient
;; FIXME: Work-around for casual-*, magit requiring newer transient
(use-package transient
  :ensure t)

;; casual
(use-package casual
  :ensure (:depth 1)
  :bind (:map calc-mode-map ("C-o" . casual-calc-tmenu)))

;; clipetty
(use-package clipetty
  :ensure t
  :diminish
  :init (global-clipetty-mode))

;; consult
(use-package consult
  :ensure t
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
  :ensure t
  :custom (corfu-auto t)
  :init (global-corfu-mode))

;; corfu-terminal
(use-package corfu-terminal
  :ensure t
  :if (not (display-graphic-p))
  :init (corfu-terminal-mode +1))

;; csv-mode
(use-package csv-mode
  :ensure t
  :defer t)

;; dired
(use-package dired
  :preface
  (defvar lap/list-of-dired-switches
    (if (eq system-type 'darwin)
        '(("-Ahl" . "almost all")
          ("-hl" . "no dotfiles"))
      '(("--almost-all --dired --human-readable -l -v" . "almost all")
        ("--dired --human-readable -l -v" . "no dotfiles")))
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

;; dired-x
(use-package dired-x
  :custom
  (dired-x-hands-off-my-keys nil)
  :defer t)

;; eat
(use-package eat
  :ensure t
  :custom
  (eat-term-scrollback-size 2000000)
  :defer t)

;; ediff
(use-package ediff
  :custom
  (ediff-window-setup-function 'ediff-setup-windows-plain)

  :init
  (defvar lap/ediff-last-window-configuration nil
    "The last window configuration before ediff started.")

  (defun lap/ediff-save-window-configuration ()
    "Save the last window configuration before starting ediff."
    (setq lap/ediff-last-window-configuration (current-window-configuration)))

  (defun lap/ediff-restore-window-configuration ()
    "Restore the last window configuration before starting ediff."
    (set-window-configuration lap/ediff-last-window-configuration))

  :hook
  (ediff-before-setup . lap/ediff-save-window-configuration)
  (ediff-quit . lap/ediff-restore-window-configuration))

;; ef-themes
(use-package ef-themes
  :ensure t
  :defer t)

;; eglot
(use-package eglot
  :defer t
  :config
  (add-to-list 'eglot-server-programs
               '(verilog-mode . ("svls"))))

;; eldoc
(use-package eldoc
  :diminish)

;; embark
(use-package embark
  :ensure t
  :bind
  (("C-c e a" . embark-act)
   ("C-c e d" . embark-dwim)
   ("C-c e B" . embark-bindings)))

;; embark-consult
(use-package embark-consult
  :ensure t
  :after (embark consult))

;; flymake
(use-package flymake
  :custom
  (flymake-no-changes-timeout 2)
  (python-flymake-command '("ruff" "--quiet" "--stdin-filename=stdin" "-"))
  :config
  (setq elisp-flymake-byte-compile-load-path load-path)
  :hook
  (emacs-lisp-mode . flymake-mode)
  (python-base-mode . flymake-mode)
  :bind
  (:map flymake-mode-map
        ("M-n" . flymake-goto-next-error)
        ("M-p" . flymake-goto-prev-error)))

;; ispell (aspell)
(use-package ispell
  :defer t
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

;; jinx
(use-package jinx
  :ensure t
  :hook
  ((text-mode prog-mode conf-mode) . jinx-mode)
  :init
  (defun lap/disable-jinx-mode-in-all-buffers ()
    "Disable jinx-mode in all buffers."
    (interactive)
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when jinx-mode
          (jinx-mode -1))))))

;; json-mode
(use-package json-mode
  :ensure t
  :defer t)

;; magit
(use-package magit
  :ensure t
  :bind ("C-c g" . magit-file-dispatch))

;; marginalia
(use-package marginalia
  :ensure t
  :init (marginalia-mode))

;; markdown
(use-package markdown-mode
  :ensure t
  :defer t)

;; modus-themes
(use-package modus-themes
  :ensure (:depth 1)
  :defer t)

;; nord-theme
;;
;; Use my fork to fix trailing white space background. See:
;; https://github.com/arcticicestudio/nord-emacs/issues/79.
;;
(use-package nord-theme
  :ensure (:host github :repo "landrewparker/nord-emacs" :branch "main")
  :defer t)

;; orderless
(use-package orderless
  :ensure t
  :defer t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; org
(use-package org
  :custom
  (org-babel-load-languages '((C . t)
                              (emacs-lisp . t)
                              (python . t)
                              (shell . t)))
  (org-babel-python-command "python3")
  (org-startup-indented t)
  :hook
  (org-mode . visual-line-mode))

;; outline
(use-package outline
  :hook
  (ediff-prepare-buffer . outline-show-all))

;; pdf-tools
(use-package pdf-tools
  :ensure t
  :hook
  (pdf-view-mode . pdf-view-themed-minor-mode)
  :magic
  ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query))

;; python
(use-package python
  :defer t
  :custom
  (python-shell-interpreter "ipython3")
  (python-shell-interpreter-args "--simple-prompt"))

;; savehist
(use-package savehist
  :init (savehist-mode))

;; saveplace
(use-package saveplace
  :init (save-place-mode))

;; server
(use-package server
  :hook
  (after-init . (lambda () (unless (server-running-p) (server-start)))))

;; shell
(use-package shell
  :custom
  (comint-input-ring-size 5000)
  :init
  (defun lap/shell-mode-setup ()
    "Tell comint that tcsh and zsh will echo."
    (if (or (string-equal shell--start-prog "zsh")
            (string-equal shell--start-prog "tcsh"))
        (setq-local comint-process-echoes t)))
  :hook
  (shell-mode . lap/shell-mode-setup))

;; tcl
(use-package tcl
  :mode
    (("\\.do\\'" . tcl-mode)
     ("\\.f\\'" . tcl-mode)))

;; transpose-frame
(use-package transpose-frame
  :ensure t
  :defer t)

;; tramp
(use-package tramp
  :defer t
  :config
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

;; tree-sitter
(use-package treesit
  :defer t
  :init
  (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))

;; verilog-mode
(use-package verilog-mode
  :defer t
  :ensure (:host github
           :repo "veripool/verilog-mode"
           ;; The default make target also compiles e/verilog-mode.elc
           ;; which will not be used, but seems better than the
           ;; potentially fragile "e/verilog-mode.el" target.
           :pre-build (("make"))
           :files ("e/*.el"))
  :custom
  (verilog-auto-newline nil)
  (verilog-indent-level 2)
  (verilog-indent-level-module 2)
  (verilog-indent-level-declaration 2)
  (verilog-indent-level-behavioral 2))

;; vertico
(use-package vertico
  :ensure t
  :init (vertico-mode))

;; vscode-dark-plus-theme
(use-package vscode-dark-plus-theme
  :ensure (:depth 1)
  :defer t)

;; wgrep
(use-package wgrep
  :ensure t
  :defer t)

;; which-key
(use-package which-key
  :ensure t
  :diminish
  :init (which-key-mode))

;; yaml-mode
(use-package yaml-mode
  :ensure t
  :defer t)

;; yasnippet
(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :init (yas-global-mode))

;;; init.el ends here
