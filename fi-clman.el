;; Copyright (c) 1987-1993 Franz Inc, Berkeley, Ca.
;;
;; Permission is granted to any individual or institution to use, copy,
;; modify, and distribute this software, provided that this complete
;; copyright and permission notice is maintained, intact, in all copies and
;; supporting documentation.
;;
;; Franz Incorporated provides this software "as is" without
;; express or implied warranty.

;; $Id: fi-clman.el,v 2.15 1996/10/03 07:21:05 layer Exp $

(defvar fi::clman-prog)
(setq fi::clman-prog
  (let ((s (if (on-ms-windows) "clman.exe" "clman")))
    (format "%s%s" (file-name-directory load-file-name) s)))

(defvar fi::clman-data)
(setq fi::clman-data
  (format "%sclman.data" (file-name-directory load-file-name)))

(defvar fi::manual-dir)
(setq fi::manual-dir (format "%smanual/" (file-name-directory load-file-name)))

(defvar fi::clman-big-oblist)
(unless (boundp 'fi::clman-big-oblist)
  (condition-case nil (load (concat fi::manual-dir "OBLIST")) (error nil)))

(defvar fi:clman-mode-map nil
  "*Major mode key definitions for viewing a clman page.")

(defvar fi:clman-displaying-buffer "*clman*"
  "Name of the buffer in which to display CLMAN pages.")

(defvar fi::clman-window-configuration nil)

(defun fi:clman (symbol)
  "Look up SYMBOL in the online CL manual, with completion.  The optional
argument SYMBOL is prompted for in the minibuffer, if not supplied.   To get
completion for a symbol in a package other than the :lisp
package, use the nickname of that package, followed by a colon (e.g. cw: or
math:).  The buffer that is displayed will be in CLMAN mode."
  (interactive
   (let* ((symbol-at-point (fi::get-symbol-at-point t))
	  (res (completing-read (format "CLMAN for Symbol (default %s): "
					symbol-at-point)
				(or fi::clman-big-oblist
				    (error "OBLIST not loaded"))
				nil
				nil
				nil)))
     (list (if (string= "" res)
	       symbol-at-point
	     res))))
  (setq fi::clman-window-configuration (current-window-configuration))
  (cond
   ((and fi::clman-data fi::clman-prog)
    (let (exit-status)
      (with-output-to-temp-buffer fi:clman-displaying-buffer
	(buffer-flush-undo standard-output)
	(save-excursion
	  (set-buffer standard-output)
	  (setq exit-status
	    ;; spr10564: put DOWNCASE around SYMBOL in next form to allow
	    ;; uppercase symbols to do the right thing. -dm 4/12/94
	    (call-process fi::clman-prog nil t nil fi::clman-data 
			  (downcase symbol)))
	  (when (on-ms-windows)
	    (save-excursion
	      (goto-char (point-min))
	      (replace-string (char-to-string 13) "")))
	  (when (< (buffer-size) 80)
	    (goto-char (point-min))
	    (end-of-line)
	    (error (buffer-substring 1 (point))))
	  (fi:clman-mode)))
      (when (and (numberp exit-status) (> exit-status 1))
	(message "%d additional clman pages at end of buffer"
		 (- exit-status 1)))))
   (t
    (let ((files (cdr (assoc symbol (or fi::clman-big-oblist
					(error "OBLIST not loaded"))))))
      (if files
	  (progn
	    (fi::clman-display-file fi:clman-displaying-buffer files)
	    (length files))
	(error "couldn't find entry for %s" symbol))))))

(defun fi:clman-apropos ()
  "Prompts for a string on which an apropos search is done.  Displays a
buffer which lists all documented symbols which match the string.  The
buffer will be in CLMAN mode."
  (interactive)
  (setq fi::clman-window-configuration (current-window-configuration))
  (let* ((string (read-string "clman apropos: "))
	 (buf (get-buffer-create "*clman apropos*")))
    (if (not (eq buf (current-buffer)))
      (switch-to-buffer buf))
    (erase-buffer)
    (dolist (obj (or fi::clman-big-oblist
		     (error "OBLIST not loaded")))
      (if  (and (string-match ".+:" (car obj))
		(string-match string (car obj)))
	  (insert (car obj) "\n")))
    (fi:clman-mode)
    (goto-char (point-min))))

(defun fi:clman-mode ()
  "Major mode for viewing Allegro manual pages.  text-mode-syntax-table and
text-mode-abbrev-table are `used' in this mode.
\\{fi:clman-mode-map}"
  (interactive)
  (set-syntax-table text-mode-syntax-table)
  (use-local-map fi:clman-mode-map)
  (setq local-abbrev-table text-mode-abbrev-table)
  (setq major-mode 'fi:clman-mode)
  (setq mode-name "CLMAN")
  (run-hooks 'fi:clman-mode-hook 'text-mode-hook))

(defun fi:clman-search-forward-see-alsos ()
  "Move text cursor directly to the beginnig of the SEE ALSO section of a
clman buffer, from anywhere in the buffer."
  (interactive)
  (if (search-forward "SEE ALSO" nil t)
      (beginning-of-line)
    (if (search-backward "SEE ALSO" nil t)
	(beginning-of-line))))

(defun fi:clman-next-entry ()
  "Find the DESCRIPTION section."
  (interactive)
  (if (search-forward "DESCRIPTION" nil t)
      (progn (beginning-of-line)(forward-line 1))
    (progn
      (goto-char (point-min))
      (search-forward "DESCRIPTION" nil t)
      (beginning-of-line)(forward-line 1) )))

(defun fi:clman-flush-doc ()
  "Flush the current clman buffer."
  (interactive)
  (kill-buffer (current-buffer))
  (set-window-configuration fi::clman-window-configuration))

(defun fi::clman-display-file (buf names)
  (with-output-to-temp-buffer buf
    (buffer-flush-undo standard-output)
    (save-excursion
      (set-buffer buf)
      (let ((first t))
	(dolist (name names)
	  (when (not first)
	    (princ
	     "===============================================================================\n"))
	  (princ (fi::file-contents (concat fi::manual-dir name)))
	  (setq first nil)))
      (fi:clman-mode)))
  (let ((additional (- (length names) 1)))
    (when (> additional 1)
      (message "%d additional clman pages at end of buffer"
	       additional))))

(defun fi::file-contents (file)
  (let ((buffer (find-file-noselect file)))
    (save-excursion
      (set-buffer buffer)
      (prog1 (buffer-string)
	(kill-buffer buffer)))))

(if fi:clman-mode-map
    nil
  (setq fi:clman-mode-map (make-keymap))
  (define-key fi:clman-mode-map "\C-C\C-C" 'fi:clman-flush-doc)
  (define-key fi:clman-mode-map "a" 'fi:clman-apropos)
  (define-key fi:clman-mode-map "m" 'fi:clman)
  (define-key fi:clman-mode-map "s" 'fi:clman-search-forward-see-alsos)
  (define-key fi:clman-mode-map " " 'scroll-up)
  (define-key fi:clman-mode-map "n" 'fi:clman-next-entry))
