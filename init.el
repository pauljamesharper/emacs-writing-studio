;;; init.el --- Emacs Writing Studio init -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Peter Prevos

;; Author: Peter Prevos <peter@prevos.net>
;; Maintainer: Peter Prevos <peter@prevos.net>
;; URL: https://github.com/pprevos/emacs-writing-studio/
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Emacs Writing Studio init file
;; https://lucidmanager.org/tags/emacs
;;
;; This init file is tangled from the Org mode source:
;; documents/ews-book/99-appendix.org
;;
;;; Code:

;; Emacs 29?

(when (< emacs-major-version 29)
  (error "Emacs Writing Studio requires Emacs version 29 or later"))

;; Custom settings in a separate file and load the custom settings

(setq-default custom-file (expand-file-name "custom.el" user-emacs-directory))

(load custom-file :no-error-if-file-is-missing)

(keymap-global-set "C-c w v" 'customize-variable)

;; Create a keymap for find-related commands
(define-prefix-command 'my-find-map)

;; Bind it to a prefix key
(global-set-key (kbd "C-c f") my-find-map)

;; Define just the configuration file binding
(define-key my-find-map (kbd "c") 
  (lambda () (interactive) (find-file "~/.config/emacs/init.el")))

;; Add which-key support for these bindings
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "C-c f" "Find"
    "C-c f c" "Edit emacs config"))

;; Set package archives

(use-package package
  :config
  (add-to-list 'package-archives
               '("melpa" . "https://melpa.org/packages/")
               '("gnu" . "https://elpa.gnu.org/packages/"))
  (package-initialize))

;; Package Management

(use-package use-package
  :custom
  (use-package-always-ensure t)
  (package-native-compile t)
  (warning-minimum-level :emergency))

;; Load EWS functions

(load-file (concat (file-name-as-directory user-emacs-directory) "ews.el"))

;; Check for missing external software
;;
;; - soffice (LibreOffice): View and create office documents
;; - zip: Unpack ePub documents
;; - pdftotext (poppler-utils): Convert PDF to text
;; - ddjvu (DjVuLibre): View DjVu files
;; - curl: Reading RSS feeds
;; - convert (ImageMagick) or gm (GraphicsMagick): Convert image files  ;; - latex (TexLive, MacTex or MikTeX): Preview LaTex and export Org to PDF
;; - hunspell: Spellcheck. Also requires a hunspell dictionary
;; - grep: Search inside files
;; - gs (GhostScript) or mutool (MuPDF): View PDF files
;; - mpg321, ogg123 (vorbis-tools), mplayer, mpv, vlc: Media players
;; - git: Version control

(ews-missing-executables
 '("soffice"
   "zip"
   "pdftotext"
   "ddjvu"
   "curl"
   ("convert" "gm")
   "latex"
   "hunspell"
   "grep"
   ("gs" "mutool")
   ("mpg321" "ogg123" "mplayer" "mpv" "vlc")
   "git"))

;;; God Mode begins
;; First, ensure god-mode is installed
(use-package god-mode
  :ensure t
  :custom
  (god-exempt-major-modes nil)
  (god-exempt-predicates nil)
  :config
  ;; Enable god-mode using escape
  (global-set-key (kbd "<escape>") #'god-local-mode)
  
  ;; Change cursor color when god-mode is active
  (defun my-god-mode-update-cursor-type ()
    (setq cursor-type (if (or god-local-mode buffer-read-only) 'box 'bar)))
  
  (defun my-god-mode-update-cursor-color ()
    (set-cursor-color (if god-local-mode "#FFD700" "#ffffff")))  ; Gold color in god-mode
  
  (add-hook 'god-mode-enabled-hook #'my-god-mode-update-cursor-type)
  (add-hook 'god-mode-disabled-hook #'my-god-mode-update-cursor-type)
  (add-hook 'god-mode-enabled-hook #'my-god-mode-update-cursor-color)
  (add-hook 'god-mode-disabled-hook #'my-god-mode-update-cursor-color)

;; Exclude Bongo and Dired modes from God Mode
(add-to-list 'god-exempt-major-modes 'dired-mode)
(add-to-list 'god-exempt-major-modes 'bongo-mode)
(add-to-list 'god-exempt-major-modes 'bongo-library-mode)
(add-to-list 'god-exempt-major-modes 'bongo-playlist-mode)

  ;; Integration with which-key
  (defun my-god-mode-which-key-update ()
    (which-key-add-key-based-replacements
      "g" "god-mode"
      "i" "insert-mode"))
  
  (add-hook 'god-mode-enabled-hook #'my-god-mode-which-key-update)

  ;; Additional key bindings for god-mode
  (define-key god-local-mode-map (kbd ".") #'repeat)
  (define-key god-local-mode-map (kbd "i") #'god-local-mode)
  
  ;; Better handling of C-c sequences in god-mode
  (defun my-god-mode-lookup-command-advice (lookup-fn key)
    "Translate any C-c sequence to its god-mode equivalent."
    (let ((command (funcall lookup-fn key)))
      (if (and (symbolp command)
               (string-prefix-p "C-c" (key-description key)))
          (let* ((key-seq (key-description key))
                 (translated-seq (replace-regexp-in-string "C-c" "c" key-seq t))
                 (translated-key (kbd translated-seq)))
            (or (lookup-key god-local-mode-map translated-key)
                command))
        command)))
  
  (advice-add 'god-mode-lookup-command :around #'my-god-mode-lookup-command-advice)

  ;; Enable god-mode for all buffers
  (god-mode-all))
;;; End God Mode

;; Zooming In/Out
;; You can use the bindings CTRL plus =/- for zooming in/out.  You can also use CTRL plus the mouse wheel for zooming in/out.
(global-set-key (kbd "C-=") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)
(global-set-key (kbd "<C-wheel-up>") 'text-scale-increase)
(global-set-key (kbd "<C-wheel-down>") 'text-scale-decrease)
;; Add this to your God Mode configuration section in init.el

;; Make zoom commands work in God Mode
(defun my-god-mode-zoom-in ()
  "Zoom in when in god-mode."
  (interactive)
  (text-scale-increase 1))

(defun my-god-mode-zoom-out ()
  "Zoom out when in god-mode."
  (interactive)
  (text-scale-decrease 1))

;; Bind zoom commands in god-mode-map
(with-eval-after-load 'god-mode
  (define-key god-local-mode-map (kbd "=") 'my-god-mode-zoom-in)
  (define-key god-local-mode-map (kbd "-") 'my-god-mode-zoom-out))

;;; LOOK AND FEEL

(use-package emacs
  :custom
  (menu-bar-mode nil)         ;; Disable the menu bar
  (scroll-bar-mode nil)       ;; Disable the scroll bar
  (tool-bar-mode nil)         ;; Disable the tool bar
  (inhibit-startup-screen t)  ;; Disable welcome screen

  (delete-selection-mode t)   ;; Select text and delete it by typing.
  (electric-indent-mode nil)  ;; Turn off the weird indenting that Emacs does by default.
  (electric-pair-mode t)      ;; Turns on automatic parens pairing

  (blink-cursor-mode nil)     ;; Don't blink cursor
  (global-auto-revert-mode t) ;; Automatically reload file and show changes if the file has changed

  (dired-kill-when-opening-new-dired-buffer t) ;; Dired don't create new buffer
  ;;(recentf-mode t) ;; Enable recent file mode

  ;;(global-visual-line-mode t)           ;; Enable truncated lines
  ;;(display-line-numbers-type 'relative) ;; Relative line numbers
  (global-display-line-numbers-mode t)  ;; Display line numbers

  (mouse-wheel-progressive-speed nil) ;; Disable progressive speed when scrolling
  (scroll-conservatively 10) ;; Smooth scrolling
  ;;(scroll-margin 8)

  (tab-width 4)

  (make-backup-files nil) ;; Stop creating ~ backup files
  (auto-save-default nil) ;; Stop creating # auto save files
  :hook
  (prog-mode . (lambda () (hs-minor-mode t))) ;; Enable folding hide/show globally
  )

;; Short answers only please

(setq-default use-short-answers t)

;; Spacious padding

;; (use-package spacious-padding
;;   :custom
;;   (line-spacing 3)
;;   (spacious-padding-mode 1))

;; Nerd Icons
;; This is an icon set that can be used with dashboard, dired, ibuffer and other Emacs programs.
(use-package nerd-icons
  :ensure t)

(use-package nerd-icons-dired
  :ensure t
  :hook (dired-mode . nerd-icons-dired-mode))

;; Modus and EF Themes
(use-package modus-themes
  :init
  ;; Load modus-vivendi-tinted immediately before other configurations
  (load-theme 'modus-vivendi-tinted t)
  :custom
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-mixed-fonts t)
  (modus-themes-to-toggle '(modus-operandi-tinted modus-vivendi-tinted))
  :bind
  (("C-c w t t" . modus-themes-toggle)
   ("C-c w t m" . modus-themes-select)
   ("C-c w t s" . consult-theme)))

(use-package ef-themes)

;; Mixed-pich mode

(use-package mixed-pitch
  :hook
  (org-mode . mixed-pitch-mode))

;; Window management
;; Split windows sensibly

(setq split-width-threshold 120
      split-height-threshold nil)

;; Keep window sizes balanced

(use-package balanced-windows
  :config
  (balanced-windows-mode))

;; MINIBUFFER COMPLETION

;; Enable vertico

(use-package vertico
  :init
  (vertico-mode)
  :custom
  (vertico-sort-function 'vertico-sort-history-alpha))

;; Persist history over Emacs restarts.

(use-package savehist
  :init
  (savehist-mode))

;; Search for partial matches in any order

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles partial-completion)))))

;; Enable richer annotations using the Marginalia package

(use-package marginalia
  :init
  (marginalia-mode))

;; Improve keyboard shortcut discoverability
(use-package which-key
  :ensure nil ; built into Emacs 30
  :hook (after-init . which-key-mode)
  :config
  (setq which-key-separator "  ")
  (setq which-key-prefix-prefix "... ")
  (setq which-key-max-display-columns 3)
  (setq which-key-idle-delay 1.5)
  (setq which-key-idle-secondary-delay 0.25)
  (setq which-key-add-column-padding 1)
  (setq which-key-max-description-length 40)
  
  ;; Try these alternative settings
  (setq which-key-popup-type 'minibuffer)  ;; Use minibuffer instead of side-window
  (setq which-key-min-display-lines 6)     ;; Ensure enough lines are displayed
  
  ;; Add nested menu descriptions for Writing Studio commands
  (which-key-add-key-based-replacements
    "C-c w" "Writing"
    
    ;; Second level menus
    "C-c w b" "Bibliography"
    "C-c w d" "Denote"
    "C-c w m" "Media"
    "C-c w s" "Spelling/Style"
    "C-c w t" "Toggle"
    "C-c w x" "Explore"
    
    ;; Third level menus (examples)
    "C-c w b c" "Create note"
    "C-c w b n" "Open note"
    "C-c w b o" "Open reference"
    
    "C-c w x c" "Count notes"
    "C-c w x r" "Random note"
    
    "C-c w s d" "Dictionary"
    "C-c w s t" "Titlecase")
  
  ;; God-Mode support
  (with-eval-after-load 'god-mode
    (which-key-enable-god-mode-support)
    
    ;; God-Mode versions of the keybindings
    (which-key-add-key-based-replacements
      "c w" "Writing"
      
      "c w b" "Bibliography"
      "c w d" "Denote"
      "c w m" "Media"
      "c w s" "Spelling/Style"
      "c w t" "Toggle"
      "c w x" "Explore")))
;; Improved help buffers

(use-package helpful
  :bind
  (("C-h f" . helpful-function)
   ("C-h x" . helpful-command)
   ("C-h k" . helpful-key)
   ("C-h v" . helpful-variable)))

;;; Text mode settings

(use-package text-mode
  :ensure
  nil
  :hook
  (text-mode . visual-line-mode)
  :init
  (delete-selection-mode t)
  :custom
  (sentence-end-double-space nil)
  (scroll-error-top-bottom t)
  (save-interprogram-paste-before-kill t))

;; Check spelling with flyspell and hunspell

(use-package flyspell
  :custom
  (ispell-program-name "hunspell")
  (ispell-dictionary ews-hunspell-dictionaries)
  (flyspell-mark-duplications-flag nil) ;; Writegood mode does this
  (org-fold-core-style 'overlays) ;; Fix Org mode bug
  :config
  (ispell-set-spellchecker-params)
  (ispell-hunspell-add-multi-dic ews-hunspell-dictionaries)
  :hook
  (text-mode . flyspell-mode)
  :bind
  (("C-c w s s" . ispell)
   ("C-;"       . flyspell-auto-correct-previous-word)))

;;; Ricing Org mode

(use-package org
  :custom
  (org-startup-indented t)
  (org-hide-emphasis-markers t)
  (org-startup-with-inline-images t)
  (org-image-actual-width '(450))
  (org-fold-catch-invisible-edits 'error)
  (org-pretty-entities t)
  (org-use-sub-superscripts "{}")
  (org-id-link-to-org-use-id t)
  (org-fold-catch-invisible-edits 'show))

;; Show hidden emphasis markers

(use-package org-appear
  :hook
  (org-mode . org-appear-mode))

;; LaTeX previews

(use-package org-fragtog
  :after org
  :hook
  (org-mode . org-fragtog-mode)
  :custom
  (org-startup-with-latex-preview nil)
  (org-format-latex-options
   (plist-put org-format-latex-options :scale 2)
   (plist-put org-format-latex-options :foreground 'auto)
   (plist-put org-format-latex-options :background 'auto)))

;; Org modern: Most features are disabled for beginning users

(use-package org-modern
  :hook
  (org-mode . org-modern-mode)
  :custom
  (org-modern-table nil)
  (org-modern-keyword nil)
  (org-modern-timestamp nil)
  (org-modern-priority nil)
  (org-modern-checkbox nil)
  (org-modern-tag nil)
  (org-modern-block-name nil)
  (org-modern-keyword nil)
  (org-modern-footnote nil)
  (org-modern-internal-target nil)
  (org-modern-radio-target nil)
  (org-modern-statistics nil)
  (org-modern-progress nil))

;; INSPIRATION

;; Doc-View

(use-package doc-view
  :custom
  (doc-view-resolution 300)
  (large-file-warning-threshold (* 50 (expt 2 20))))

;; Read ePub files

(use-package nov
  :init
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode)))

;; Reading LibreOffice files

;; Fixing a bug in Org Mode pre-9.7
;; Org mode clobbers associations with office documents

(use-package ox-odt
  :ensure nil
  :config
  (add-to-list 'auto-mode-alist
               '("\\.\\(?:OD[CFIGPST]\\|od[cfigpst]\\)\\'"
                 . doc-view-mode-maybe)))

;; Managing Bibliographies

(use-package bibtex
  :custom
  (bibtex-user-optional-fields
   '(("keywords" "Keywords to describe the entry" "")
     ("file"     "Relative or absolute path to attachments" "" )))
  (bibtex-align-at-equal-sign t)
  :config
  (ews-bibtex-register)
  :bind
  (("C-c w b r" . ews-bibtex-register)))

;; Biblio package for adding BibTeX records

(use-package biblio
  :bind
  (("C-c w b b" . ews-bibtex-biblio-lookup)))

;; Citar to access bibliographies

(use-package citar
  :defer t
  :custom
  (citar-bibliography ews-bibtex-files)
  :bind
  (("C-c w b o" . citar-open)))

;; Read RSS feeds with Elfeed

(use-package elfeed
  :custom
  (elfeed-db-directory
   (expand-file-name "elfeed" user-emacs-directory))
  (elfeed-show-entry-switch 'display-buffer)
  :bind
  ("C-c w e" . elfeed))

;; Configure Elfeed with org mode

(use-package elfeed-org
  :config
  (elfeed-org)
  :custom
  (rmh-elfeed-org-files
   (list (concat (file-name-as-directory (getenv "HOME")) "elfeed.org"))))

;; Easy insertion of weblinks

(use-package org-web-tools
  :bind
  (("C-c w w" . org-web-tools-insert-link-for-url)))

;; Bongo Configuration using use-package with C-c w m prefix
;; Replace your existing Bongo configuration with this
(use-package bongo
  :ensure t
  :config
  (setq bongo-default-directory "~/Music")
  (setq bongo-prefer-library-buffers nil)
  (setq bongo-insert-whole-directory-trees t)
  (setq bongo-logo nil)
  (setq bongo-display-track-icons nil)
  (setq bongo-display-track-lengths nil)
  (setq bongo-display-header-icons nil)
  (setq bongo-display-playback-mode-indicator t)
  (setq bongo-display-inline-playback-progress t)
  (setq bongo-join-inserted-tracks nil)
  (setq bongo-field-separator (propertize " · " 'face 'shadow))
  (setq bongo-mark-played-tracks t)
  (setq bongo-header-line-mode nil)
  (setq bongo-mode-line-indicator-mode nil)
  (setq bongo-enabled-backends '(vlc mpv))
  (setq bongo-vlc-program-name "cvlc")

;; MPV-specific settings for Bongo
(setq bongo-enabled-backends '(mpv))  ;; Use only MPV
(setq bongo-default-backend 'mpv)    ;; Default to MPV
(setq bongo-mpv-program-name "/usr/bin/mpv")  ;; Explicit path to MPV

;; If that doesn't work, try just VLC
;; (setq bongo-enabled-backends '(vlc))

;;; Bongo playlist buffer
  (defvar prot/bongo-playlist-delimiter
    "\n******************************\n\n"
    "Delimiter for inserted items in `bongo' playlist buffers.")

  (defun prot/bongo-playlist-section ()
    (bongo-insert-comment-text
     prot/bongo-playlist-delimiter))

  (defun prot/bongo-paylist-section-next ()
    "Move to next `bongo' playlist custom section delimiter."
    (interactive)
    (let ((section "^\\*+$"))
      (if (save-excursion (re-search-forward section nil t))
          (progn
            (goto-char (point-at-eol))
            (re-search-forward section nil t))
        (goto-char (point-max)))))

  (defun prot/bongo-paylist-section-previous ()
    "Move to previous `bongo' playlist custom section delimiter."
    (interactive)
    (let ((section "^\\*+$"))
      (if (save-excursion (re-search-backward section nil t))
          (progn
            (goto-char (point-at-bol))
            (re-search-backward section nil t))
        (goto-char (point-min)))))

  (defun prot/bongo-playlist-mark-section ()
    "Mark `bongo' playlist section, delimited by custom markers.
The marker is `prot/bongo-playlist-delimiter'."
    (interactive)
    (let ((section "^\\*+$"))
      (search-forward-regexp section nil t)
      (push-mark nil t)
      (forward-line -1)
      ;; REVIEW any predicate to replace this `save-excursion'?
      (if (save-excursion (re-search-backward section nil t))
          (progn
            (search-backward-regexp section nil t)
            (forward-line 1))
        (goto-char (point-min)))
      (activate-mark)))

  (defun prot/bongo-playlist-kill-section ()
    "Kill `bongo' playlist-section at point.
This operates on a custom delimited section of the buffer.  See
`prot/bongo-playlist-kill-section'."
    (interactive)
    (prot/bongo-playlist-mark-section)
    (bongo-kill))

  (defun prot/bongo-playlist-play-random ()
    "Play random `bongo' track and determine further conditions."
    (interactive)
    (unless (bongo-playlist-buffer)
      (bongo-playlist-buffer))
    (when (or (bongo-playlist-buffer-p)
              (bongo-library-buffer-p))
      (unless (bongo-playing-p)
        (with-current-buffer (bongo-playlist-buffer)
          (bongo-play-random)
          (bongo-random-playback-mode 1)
          (bongo-recenter)))))

  (defun prot/bongo-playlist-random-toggle ()
    "Toggle `bongo-random-playback-mode' in playlist buffers."
    (interactive)
    (if (eq bongo-next-action 'bongo-play-random-or-stop)
        (bongo-progressive-playback-mode)
      (bongo-random-playback-mode)))

  (defun prot/bongo-playlist-reset ()
    "Stop playback and reset `bongo' playlist marks.
To reset the playlist is to undo the marks produced by non-nil
`bongo-mark-played-tracks'."
    (interactive)
    (when (bongo-playlist-buffer-p)
      (bongo-stop)
      (bongo-reset-playlist)))

  (defun prot/bongo-playlist-terminate ()
    "Stop playback and clear the entire `bongo' playlist buffer.
Contrary to the standard `bongo-erase-buffer', this also removes
the currently-playing track."
    (interactive)
    (when (bongo-playlist-buffer-p)
      (bongo-stop)
      (bongo-erase-buffer)))

  (defun prot/bongo-playlist-insert-playlist-file ()
    "Insert contents of playlist file to a `bongo' playlist.
Upon insertion, playback starts immediately, in accordance with
`prot/bongo-play-random'.

The available options at the completion prompt point to files
that hold filesystem paths of media items.  Think of them as
'directories of directories' that mix manually selected media
items.

Also see `prot/bongo-dired-make-playlist-file'."
    (interactive)
    (let* ((path "~/Music/playlists/")
           (dotless directory-files-no-dot-files-regexp)
           (playlists (mapcar
                       'abbreviate-file-name
                       (directory-files path nil dotless)))
           (choice (completing-read "Insert playlist: " playlists nil t)))
      (if (bongo-playlist-buffer-p)
          (progn
            (save-excursion
              (goto-char (point-max))
              (bongo-insert-playlist-contents
               (format "%s%s" path choice))
              (prot/bongo-playlist-section))
            (prot/bongo-playlist-play-random))
        (user-error "Not in a `bongo' playlist buffer"))))

;;; Bongo + Dired (bongo library buffer)
  (defmacro prot/bongo-dired-library (name doc val)
    "Create `bongo' library function NAME with DOC and VAL."
    `(defun ,name ()
       ,doc
       (when (string-match-p "\\`~/Music/" default-directory)
         (bongo-dired-library-mode ,val))))

  (prot/bongo-dired-library
   prot/bongo-dired-library-enable
   "Set `bongo-dired-library-mode' when accessing ~/Music.

Add this to `dired-mode-hook'.  Upon activation, the directory
and all its sub-directories become a valid library buffer for
Bongo, from where we can, among others, add tracks to playlists.
The added benefit is that Dired will continue to behave as
normal, making this a superior alternative to a purpose-specific
library buffer.

Note, though, that this will interfere with `wdired-mode'.  See
`prot/bongo-dired-library-disable'."
   1)

  ;; NOTE `prot/bongo-dired-library-enable' does not get reactivated
  ;; upon exiting `wdired-mode'.
  (prot/bongo-dired-library
   prot/bongo-dired-library-disable
   "Unset `bongo-dired-library-mode' when accessing ~/Music.
This should be added `wdired-mode-hook'.  For more, refer to
`prot/bongo-dired-library-enable'."
   -1)

  (defun prot/bongo-dired-insert-files ()
    "Add files in a `dired' buffer to the `bongo' playlist."
    (let ((media (dired-get-marked-files)))
      (with-current-buffer (bongo-playlist-buffer)
        (goto-char (point-max))
        (mapc 'bongo-insert-file media)
        (prot/bongo-playlist-section))
      (with-current-buffer (bongo-library-buffer)
        (dired-next-line 1))))

  (defun prot/bongo-dired-insert ()
    "Add `dired' item at point or marks to `bongo' playlist.

The playlist is created, if necessary, while some other tweaks
are introduced.  See `prot/bongo-dired-insert-files' as well as
`prot/bongo-playlist-play-random'.

Meant to work while inside a `dired' buffer that doubles as a
library buffer (see `prot/bongo-dired-library')."
    (interactive)
    (when (bongo-library-buffer-p)
      (unless (bongo-playlist-buffer-p)
        (bongo-playlist-buffer))
      (prot/bongo-dired-insert-files)
      (prot/bongo-playlist-play-random)))

  (defun prot/bongo-dired-make-playlist-file ()
    "Add `dired' marked items to playlist file using completion.

These files are meant to reference filesystem paths.  They ease
the task of playing media from closely related directory trees,
without having to interfere with the user's directory
structure (e.g. a playlist file 'rock' can include the paths of
~/Music/Scorpions and ~/Music/Queen).

This works by appending the absolute filesystem path of each item
to the selected playlist file.  If no marks are available, the
item at point will be used instead.

Selecting a non-existent file at the prompt will create a new
entry whose name matches user input.  Depending on the completion
framework, such as with `icomplete-mode', this may require a
forced exit (e.g. \\[exit-minibuffer] to parse the input without
further questions).

Also see `prot/bongo-playlist-insert-playlist-file'."
    (interactive)
    (let* ((dotless directory-files-no-dot-files-regexp)
           (pldir "~/Music/playlists")
           (playlists (mapcar
                       'abbreviate-file-name
                       (directory-files pldir nil dotless)))
           (plname (completing-read "Select playlist: " playlists nil nil))
           (plfile (format "%s/%s" pldir plname))
           (media-paths
            (if (derived-mode-p 'dired-mode)
                ;; The issue is that we need to have a newline at the
                ;; end of the file, so that when we append again we
                ;; start on an empty line.
                (concat
                 (mapconcat #'identity
                            (dired-get-marked-files)
                            "\n")
                 "\n")
              (user-error "Not in a `dired' buffer"))))
      ;; The following `when' just checks for an empty string.
      (when (string-empty-p plname)
        (user-error "No playlist file has been specified"))
      (unless (file-directory-p pldir)
        (make-directory pldir))
      (unless (and (file-exists-p plfile)
                   (file-readable-p plfile)
                   (not (file-directory-p plfile)))
        (make-empty-file plfile))
      (append-to-file media-paths nil plfile)
      (with-current-buffer (find-file-noselect plfile)
        (delete-duplicate-lines (point-min) (point-max))
        (sort-lines nil (point-min) (point-max))
        (save-buffer)
        (kill-buffer))))

  :hook ((dired-mode-hook . prot/bongo-dired-library-enable)
         (wdired-mode-hook . prot/bongo-dired-library-disable))
  
  :bind (
         ;; Global bindings with C-c w m prefix
         ("C-c w m b" . bongo)                   ; Open Bongo buffer (main)
         ("C-c w m l" . bongo-library)           ; Open library
         ("C-c w m p" . bongo-pause/resume)      ; Play/pause toggle
         ("C-c w m n" . bongo-next)              ; Next track
         ("C-c w m v" . bongo-previous)          ; Previous track (like "previous")
         ("C-c w m s" . bongo-stop)              ; Stop playback
         ("C-c w m f" . bongo-seek-forward-10)   ; Forward 10 seconds
         ("C-c w m b" . bongo-seek-backward-10)  ; Backward 10 seconds
         ("C-c w m o" . bongo-show)              ; Show current track (open/output)
         ("C-c w m r" . prot/bongo-playlist-random-toggle) ; Random toggle
         
         :map bongo-playlist-mode-map
         ("n" . bongo-next-object)
         ("p" . bongo-previous-object)
         ("M-n" . prot/bongo-paylist-section-next)
         ("M-p" . prot/bongo-paylist-section-previous)
         ("M-h" . prot/bongo-playlist-mark-section)
         ("M-d" . prot/bongo-playlist-kill-section)
         ("g" . prot/bongo-playlist-reset)
         ("D" . prot/bongo-playlist-terminate)
         ("r" . prot/bongo-playlist-random-toggle)
         ("R" . bongo-rename-line)
         ("j" . bongo-dired-line)       ; Jump to dir of file at point
         ("J" . dired-jump)             ; Jump to library buffer
         ("i" . prot/bongo-playlist-insert-playlist-file)
         ("I" . bongo-insert-special)
         
         :map bongo-dired-library-mode-map
         ("<C-return>" . prot/bongo-dired-insert)
         ("C-c w m a" . prot/bongo-dired-insert)      ; Add to playlist
         ("C-c w m +" . prot/bongo-dired-make-playlist-file)))

;; Register with which-key
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "C-c w m" "Media"
    "C-c w m b" "Bongo buffer"
    "C-c w m l" "Library"
    "C-c w m p" "Play/Pause"
    "C-c w m n" "Next track"
    "C-c w m v" "Previous track"
    "C-c w m s" "Stop playback"
    "C-c w m f" "Forward 10s"
    "C-c w m b" "Backward 10s"
    "C-c w m o" "Show track"
    "C-c w m r" "Random toggle"
    "C-c w m a" "Add to playlist"
    "C-c w m +" "Make playlist file"))

;; God Mode support
(with-eval-after-load 'god-mode
  (which-key-add-key-based-replacements
    "c w m" "Media"
    "c w m b" "Bongo buffer"
    "c w m l" "Library"
    "c w m p" "Play/Pause"
    "c w m n" "Next track"
    "c w m v" "Previous track"
    "c w m s" "Stop playback"
    "c w m f" "Forward 10s"
    "c w m b" "Backward 10s"
    "c w m o" "Show track"
    "c w m r" "Random toggle"
    "c w m a" "Add to playlist"
    "c w m +" "Make playlist file"))


(use-package openwith
  :config
  (openwith-mode t)
  :custom
  (openwith-associations nil))

;; Fleeting notes

(use-package org
  :bind
  (("C-c c" . org-capture)
   ("C-c l" . org-store-link))
  :custom
  (org-goto-interface 'outline-path-completion)
  (org-capture-templates
   '(("f" "Fleeting note"
      item
      (file+headline org-default-notes-file "Notes")
      "- %?")
     ("p" "Permanent note" plain
      (file denote-last-path)
      #'denote-org-capture
      :no-save t
      :immediate-finish nil
      :kill-buffer t
      :jump-to-captured t)
     ("t" "New task" entry
      (file+headline org-default-notes-file "Tasks")
      "* TODO %i%?"))))

;; Denote

(use-package denote
  :defer t
  :custom
  (denote-sort-keywords t)
  (denote-link-description-function #'ews-denote-link-description-title-case)
  :hook
  (dired-mode . denote-dired-mode)
  :custom-face
  (denote-faces-link ((t (:slant italic))))
  :init
  (require 'denote-org-extras)
  :bind
  (("C-c w d b" . denote-find-backlink)
   ("C-c w d d" . denote-date)
   ("C-c w d l" . denote-find-link)
   ("C-c w d h" . denote-org-extras-link-to-heading)
   ("C-c w d i" . denote-link-or-create)
   ("C-c w d k" . denote-rename-file-keywords)
   ("C-c w d n" . denote)
   ("C-c w d r" . denote-rename-file)
   ("C-c w d R" . denote-rename-file-using-front-matter)))

;; Consult convenience functions

(use-package consult
  :bind
  (("C-c w h" . consult-org-heading)
   ("C-c w g" . consult-grep)))

;; Consult-Notes for easy access to notes

(use-package consult-notes
  :bind
  (("C-c w d f" . consult-notes)
   ("C-c w d g" . consult-notes-search-in-all-notes))
  :init
  (consult-notes-denote-mode))

;; Citar-Denote to manage literature notes

(use-package citar-denote
  :custom
  (citar-open-always-create-notes t)
  :init
  (citar-denote-mode)
  :bind
  (("C-c w b c" . citar-create-note)
   ("C-c w b n" . citar-denote-open-note)
   ("C-c w b x" . citar-denote-nocite)
   :map org-mode-map
   ("C-c w b k" . citar-denote-add-citekey)
   ("C-c w b K" . citar-denote-remove-citekey)
   ("C-c w b d" . citar-denote-dwim)
   ("C-c w b e" . citar-denote-open-reference-entry)))

;; Explore and manage your Denote collection

(use-package denote-explore
  :bind
  (;; Statistics
   ("C-c w x c" . denote-explore-count-notes)
   ("C-c w x C" . denote-explore-count-keywords)
   ("C-c w x b" . denote-explore-barchart-keywords)
   ("C-c w x e" . denote-explore-barchart-filetypes)
   ;; Random walks
   ("C-c w x r" . denote-explore-random-note)
   ("C-c w x l" . denote-explore-random-link)
   ("C-c w x k" . denote-explore-random-keyword)
   ("C-c w x x" . denote-explore-random-regex)
   ;; Denote Janitor
   ("C-c w x d" . denote-explore-identify-duplicate-notes)
   ("C-c w x z" . denote-explore-zero-keywords)
   ("C-c w x s" . denote-explore-single-keywords)
   ("C-c w x o" . denote-explore-sort-keywords)
   ("C-c w x w" . denote-explore-rename-keyword)
   ;; Visualise denote
   ("C-c w x n" . denote-explore-network)
   ("C-c w x v" . denote-explore-network-regenerate)
   ("C-c w x D" . denote-explore-degree-barchart)))

;; Set some Org mode shortcuts

(use-package org
  :bind
  (:map org-mode-map
        ("C-c w n" . ews-org-insert-notes-drawer)
        ("C-c w p" . ews-org-insert-screenshot)
        ("C-c w c" . ews-org-count-words)))

;; Distraction-free writing

(use-package olivetti
  :demand t
  :bind
  (("C-c w o" . ews-olivetti)))

;; Undo Tree

(use-package undo-tree
  :config
  (global-undo-tree-mode)
  :custom
  (undo-tree-auto-save-history nil)
  :bind
  (("C-c w u" . undo-tree-visualise)))

;; Export citations with Org Mode

(require 'oc-natbib)
(require 'oc-csl)

(setq org-cite-global-bibliography ews-bibtex-files
      org-cite-insert-processor 'citar
      org-cite-follow-processor 'citar
      org-cite-activate-processor 'citar)

;; Lookup words in the online dictionary

(use-package dictionary
  :custom
  (dictionary-server "dict.org")
  :bind
  (("C-c w s d" . dictionary-lookup-definition)))

(use-package powerthesaurus
  :bind
  (("C-c w s p" . powerthesaurus-transient)))

;; Writegood-Mode for weasel words, passive writing and repeated word detection

(use-package writegood-mode
  :bind
  (("C-c w s r" . writegood-reading-ease)
   ("C-c w s l" . writegood-grade-level))
  :hook
  (text-mode . writegood-mode))

;; Titlecasing

(use-package titlecase
  :bind
  (("C-c w s t" . titlecase-dwim)
   ("C-c w s c" . ews-org-headings-titlecase)))

;; Abbreviations

(add-hook 'text-mode-hook 'abbrev-mode)

;; Lorem Ipsum generator

(use-package lorem-ipsum
  :custom
  (lorem-ipsum-list-bullet "- ") ;; Org mode bullets
  :init
  (setq lorem-ipsum-sentence-separator
        (if sentence-end-double-space "  " " "))
  :bind
  (("C-c w s i" . lorem-ipsum-insert-paragraphs)))

;; ediff

(use-package ediff
  :ensure nil
  :custom
  (ediff-keep-variants nil)
  (ediff-split-window-function 'split-window-horizontally)
  (ediff-window-setup-function 'ediff-setup-windows-plain))

;; Enable Other text modes

;; Fontain mode for writing scrits

(use-package fountain-mode)

;; Markdown mode

(use-package markdown-mode)

;; PUBLICATION

;; Generic Org Export Settings

(use-package org
  :custom
  (org-export-with-drawers nil)
  (org-export-with-todo-keywords nil)
  (org-export-with-toc nil)
  (org-export-with-smart-quotes t)
  (org-export-date-timestamp-format "%e %B %Y"))

;; epub export

(use-package ox-epub
  :demand t
  :init
  (require 'ox-org))

;; LaTeX PDF Export settings

(use-package ox-latex
  :ensure nil
  :demand t
  :custom
  ;; Multiple LaTeX passes for bibliographies
  (org-latex-pdf-process
   '("pdflatex -interaction nonstopmode -output-directory %o %f"
     "bibtex %b"
     "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
     "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
  ;; Clean temporary files after export
  (org-latex-logfiles-extensions
   (quote ("lof" "lot" "tex~" "aux" "idx" "log" "out"
           "toc" "nav" "snm" "vrb" "dvi" "fdb_latexmk"
           "blg" "brf" "fls" "entoc" "ps" "spl" "bbl"
           "tex" "bcf"))))

;; EWS paperback configuration

(with-eval-after-load 'ox-latex
  (add-to-list
   'org-latex-classes
   '("ews"
     "\\documentclass[11pt, twoside, hidelinks]{memoir}
      \\setstocksize{9.25in}{7.5in}
      \\settrimmedsize{\\stockheight}{\\stockwidth}{*}
      \\setlrmarginsandblock{2cm}{1cm}{*} 
      \\setulmarginsandblock{1.5cm}{2.25cm}{*}
      \\checkandfixthelayout
      \\setcounter{tocdepth}{0}
      \\OnehalfSpacing
      \\usepackage{ebgaramond}
      \\usepackage[htt]{hyphenat}
      \\chapterstyle{bianchi}
      \\setsecheadstyle{\\normalfont \\raggedright \\textbf}
      \\setsubsecheadstyle{\\normalfont \\raggedright \\textbf}
      \\setsubsubsecheadstyle{\\normalfont\\centering}
      \\renewcommand\\texttt[1]{{\\normalfont\\fontfamily{cmvtt}
        \\selectfont #1}}
      \\usepackage[font={small, it}]{caption}
      \\pagestyle{myheadings}
      \\usepackage{ccicons}
      \\usepackage[authoryear]{natbib}
      \\bibliographystyle{apalike}
      \\usepackage{svg}"
     ("\\chapter{%s}" . "\\chapter*{%s}")
     ("\\section{%s}" . "\\section*{%s}")
     ("\\subsection{%s}" . "\\subsection*{%s}")
     ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))))

;;; ADMINISTRATION

;; Bind org agenda command and custom agenda

(use-package org
  :custom
  (org-agenda-custom-commands
   '(("e" "Agenda, next actions and waiting"
      ((agenda "" ((org-agenda-overriding-header "Next three days:")
                   (org-agenda-span 3)
                   (org-agenda-start-on-weekday nil)))
       (todo "NEXT" ((org-agenda-overriding-header "Next Actions:")))
       (todo "WAIT" ((org-agenda-overriding-header "Waiting:")))))))
  :bind
  (("C-c a" . org-agenda)))

;; FILE MANAGEMENT

(use-package dired
  :ensure
  nil
  :commands
  (dired dired-jump)
  :custom
  (dired-listing-switches
   "-goah --group-directories-first --time-style=long-iso")
  (dired-dwim-target t)
  (delete-by-moving-to-trash t)
  :init
  (put 'dired-find-alternate-file 'disabled nil))

;; Hide or display hidden files

(use-package dired
  :ensure nil
  :hook (dired-mode . dired-omit-mode)
  :bind (:map dired-mode-map
              ( "."     . dired-omit-mode))
  :custom (dired-omit-files "^\\.[a-zA-Z0-9]+"))

;; Backup files

(setq-default backup-directory-alist
              `(("." . ,(expand-file-name "backups/" user-emacs-directory)))
              version-control t
              delete-old-versions t
              create-lockfiles nil)

;; Recent files

(use-package recentf
  :config
  (recentf-mode t)
  :custom
  (recentf-max-saved-items 50)
  :bind
  (("C-c w r" . recentf-open)))

;; Bookmarks

(use-package bookmark
  :custom
  (bookmark-save-flag 1)
  :bind
  ("C-x r d" . bookmark-delete))

;; Image viewer

(use-package emacs
  :custom
  (image-dired-external-viewer "gimp")
  :bind
  ((:map image-mode-map
         ("k" . image-kill-buffer)
         ("<right>" . image-next-file)
         ("<left>"  . image-previous-file))
   (:map dired-mode-map
         ("C-<return>" . image-dired-dired-display-external))))

(use-package image-dired
  :bind
  (("C-c w I" . image-dired))
  (:map image-dired-thumbnail-mode-map
        ("C-<right>" . image-dired-display-next)
        ("C-<left>"  . image-dired-display-previous)))

;; ADVANCED UNDOCUMENTED EXPORT SETTINGS FOR EWS

;; Use GraphViz for flow diagrams
;; requires GraphViz software
(org-babel-do-load-languages
 'org-babel-load-languages
 '((dot . t))) ; this line activates GraophViz dot

;; Sudo Edit
;;sudo-edit gives us the ability to open files with sudo privileges or switch over to editing with sudo privileges if we initially opened the file without such privileges.
;; Install and configure sudo-edit package
(use-package sudo-edit
  :ensure t
  :bind
  (("C-c f u" . sudo-edit-find-file)
   ("C-c f U" . sudo-edit)))

;; Add which-key support for these bindings
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "C-c f u" "Sudo find file"
    "C-c f U" "Sudo edit file"))

;; Add god-mode support if needed
(with-eval-after-load 'god-mode
  (which-key-add-key-based-replacements
    "c f u" "Sudo find file"
    "c f U" "Sudo edit file"))

;; Vterm

(use-package vterm
  :ensure t
  :config
(setq shell-file-name "/bin/bash"
      vterm-max-scrollback 5000))


;; Vterm-Toggle

;; vterm-toggle toggles between the vterm buffer and whatever buffer you are editing.
(use-package vterm-toggle
  :after vterm
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (setq vterm-toggle-scope 'project)
  (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _)
                     (let ((buffer (get-buffer buffer-or-name)))
                       (with-current-buffer buffer
                         (or (equal major-mode 'vterm-mode)
                             (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                  (display-buffer-reuse-window display-buffer-at-bottom)
                  ;;(display-buffer-reuse-window display-buffer-in-direction)
                  ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                  ;;(direction . bottom)
                  ;;(dedicated . t) ;dedicated is supported in emacs27
                  (reusable-frames . visible)
                  (window-height . 0.3)))
  :bind
  ("C-c w t v" . vterm-toggle)))

