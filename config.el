(setq doom-font (font-spec :size 18 :family "Iosevka"))
(setq doom-theme 'doom-outrun-electric)

(setq display-line-numbers-type t)

(pixel-scroll-precision-mode 1)

(setq pulse-delay 0.05)
(setq pulse-iterations 15)

(set-frame-parameter nil 'alpha-background 95)

(setq default-frame-alist
      '((width . 0.9)
        (height . 0.25)))

(setq org-directory "~/org/")

(setq org-fontify-whole-heading-line t
    org-fontify-done-headline t
    org-fontify-quote-and-verse-blocks t)

(custom-set-faces!
'(org-level-1 :inherit outline-1 :height 1.2 :weight bold)
'(org-level-2 :inherit outline-2 :height 1.1 :weight bold)
'(org-level-3 :inherit outline-3 :height 1.05 :weight semi-bold)
'(org-level-4 :inherit outline-4 :height 1.01 :weight semi-bold)
'(org-document-title :height 1.4 :weight bold))

(custom-set-faces!
'(org-block-begin-line :background "#1c1f24" :extend t)
'(org-block :background "#23272e" :extend t)
'(org-block-end-line :background "#1c1f24" :extend t))

(setq org-hide-emphasis-markers t
    org-pretty-entities t)

(setq org-startup-with-inline-images t
    org-image-actual-width '(500))

(setq org-link-descriptive t)

(setq org-modern-table-horizontal 1)
(setq org-modern-table-horizontal t)

(after! compile
  ;; NixOS Flake Konfiguration
  (defvar my/nixos-flake-path "/home/david/nixos-config"
    "Path to your NixOS flake directory")

  (defvar my/nixos-flake-host "desktop"
    "NixOS flake host configuration name")

  ;; Hauptfunktion für NixOS rebuild - MIT interaktivem sudo!
  (defun my/nixos-rebuild (&optional arg)
    "Rebuild NixOS with flake configuration in vterm (interactive sudo).
With prefix arg (C-u), prompt for different options."
    (interactive "P")
    (let* ((action (if arg
                       (completing-read "Action: "
                                      '("switch" "boot" "test" "build" "dry-build"))
                     "switch"))
           (flake-ref (format "%s#%s" my/nixos-flake-path my/nixos-flake-host))
           (cmd (format "sudo nixos-rebuild %s --flake %s" action flake-ref))
           (default-directory my/nixos-flake-path)
           (buffer-name "*nixos-rebuild*"))
      ;; Nutze vterm für interaktive sudo-Eingabe
      (if (get-buffer buffer-name)
          (switch-to-buffer-other-window buffer-name)
        (let ((vterm-buffer (get-buffer-create buffer-name)))
          (with-current-buffer vterm-buffer
            (vterm-mode)
            (setq-local default-directory my/nixos-flake-path))
          (display-buffer vterm-buffer)))
      (with-current-buffer buffer-name
        (vterm-send-string cmd)
        (vterm-send-return))))

  ;; Schneller test build (ohne sudo, mit compile-mode)
  (defun my/nixos-build ()
    "Build NixOS configuration without switching (no sudo needed)"
    (interactive)
    (let ((flake-ref (format "%s#%s" my/nixos-flake-path my/nixos-flake-host))
          (default-directory my/nixos-flake-path))
      (compile (format "nixos-rebuild build --flake %s" flake-ref))))

  ;; Flake update
  (defun my/nixos-flake-update ()
    "Update flake.lock"
    (interactive)
    (let ((default-directory my/nixos-flake-path))
      (compile "nix flake update")))

  ;; Flake check (schnelle Syntax-Prüfung)
  (defun my/nixos-flake-check ()
    "Check flake for errors"
    (interactive)
    (let ((default-directory my/nixos-flake-path))
      (compile "nix flake check")))

  ;; Auto-detect und setze compile command für NixOS files
  (defun my/set-nixos-compile-command ()
    "Set compile command for NixOS configuration files"
    (when (and buffer-file-name
               (string-match-p (regexp-quote my/nixos-flake-path) buffer-file-name))
      (setq-local compile-command
                  (format "sudo nixos-rebuild switch --flake %s#%s"
                          my/nixos-flake-path
                          my/nixos-flake-host))))

  (add-hook 'nix-mode-hook #'my/set-nixos-compile-command)

  ;; Keybindings - SPC d für "deploy" / NixOS
  (map! :leader
        (:prefix ("d" . "deploy/NixOS")
         :desc "Rebuild switch" "r" #'my/nixos-rebuild
         :desc "Build only" "b" #'my/nixos-build
         :desc "Flake update" "u" #'my/nixos-flake-update
         :desc "Flake check" "c" #'my/nixos-flake-check))

  ;; Spezifische Keybindings in nix-mode
  (map! :map nix-mode-map
        :localleader
        :desc "Rebuild NixOS" "r" #'my/nixos-rebuild
        :desc "Build only" "b" #'my/nixos-build
        :desc "Flake check" "c" #'my/nixos-flake-check
        :desc "Flake update" "u" #'my/nixos-flake-update))

(use-package! daemons
  :commands (daemons daemons-status)
  :config
  (setq daemons-always-sudo t))
