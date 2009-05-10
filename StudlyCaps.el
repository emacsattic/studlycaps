;;; StudlyCaps.el --- StudlyCapify as you type.
;;
;; ~harley/share/emacs/pkg/StudlyCaps/StudlyCaps.el ---
;;
;; $Id: StudlyCaps.el,v 1.11 2005/10/04 03:58:52 harley Exp $
;;

;; Author:    Harley Gorrell <harley@mahalito.net>
;; URL:       http://www.mahalito.net/~harley/elisp/StudlyCaps.el
;; License:   GPL v2

;;; Commentary:
;; * An (ab)use of abbrev-mode.
;; * Written as a Christmas gift for James, who likes StudlyCaps.
;; * When StudlyCaps is activated it adds the current set of
;;   StudlyCapped words in the buffer to the global abbrev
;;   table.
;; * If you use new StudlyCapped words rescan the buffer
;;   or use the function StudlyCaps-add-word-at-point.
;;   (global-set-key [f6] 'StudlyCaps-add-word-at-point)

;; TODO: When reading the db not all the words are in StudlyCaps.

;;
(defvar StudlyCaps-regexp "\\b[A-Z][-_a-z]+[A-Z][-_A-Za-z]*"
  "A regexp to match StudlyCapped names.
Names matching this regexp are added to the global abbrev
list by `StudlyCaps-scan-buffer'.")

(defvar StudlyCaps-db-file "~/.StudlyCaps.db")

(defvar StudlyCaps-db nil
  "A hashtable of StudlyCaps words.")

(defvar StudlyCaps-db-modified nil
  "True if the DB has unsaved changes.")

(defvar StudlyCaps-db-autosave t)

;;; Code

(defun StudlyCaps-db (&optional makenew)
  "A hashtable of translations."
  (if (and StudlyCaps-db (not makenew))
    StudlyCaps-db
    (setq StudlyCaps-db (make-hash-table :test 'equal))))
;; (StudlyCaps-db)

(defun StudlyCaps-db-load (&optional filename)
  (interactive "fLoad StudlyCaps word file:")
  (setq filename (or filename StudlyCaps-db-file))
  (message "Loading StudlyCaps db '%s'..." filename)
  (when (file-readable-p filename)
    (save-window-excursion
      (find-file filename)
      (goto-char (point-min))
      (let ((StudlyCaps-db-modified nil)) ;; dont modify modified
        (StudlyCaps-scan-buffer))
      (kill-buffer nil))))

(defun StudlyCaps-db-save (&optional filename)
  (interactive "FSave StudlyCaps db to:")
  (when (or filename StudlyCaps-db-modified)
    (setq filename (or filename StudlyCaps-db-file))
    (message "Saving StudlyCaps db '%s'..." filename)
    (save-window-excursion 
      (find-file filename)
      (erase-buffer)
      (maphash (lambda (k v) (insert v "\n")) (StudlyCaps-db))
      (save-buffer)
      (kill-buffer nil)
      (setq studlycaps-db-modified nil))))

;; (StudlyCaps-db-load)
;; (StudlyCaps-db-save)

(defun StudlyCaps-db-autosave ()
  "Save the db on emacs exit."
  (let ((dosave StudlyCaps-db-autosave))
    (cond
     ((equal dosave nil)
      nil)
     ((or (equal dosave t) 
          (and (equal dosave 'ask)
               (y-or-n-p "Save StudlyCaps db?")))
      (StudlyCaps-db-save))))
  ;; always ok to exit
  t)

(add-hook 'kill-emacs-query-functions 'StudlyCaps-db-autosave)

;;;###autoload
(defun StudlyCaps-mode (&optional scan load)
  "Turn on StudlyCaps-mode!"
  (interactive)
  (abbrev-mode 1)
  (if scan
    (StudlyCaps-scan-buffer))
  (if load
    (StudlyCaps-db-load)))

(defun StudlyCaps-scan-buffer ()
  "Scan the buffer for StudlyCap like names.
For each StudlyCap name create an abbrev from lowercase to StudlyCaps
in the global-abbrev-table."
  (interactive)
  (let ((case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (while (search-forward-regexp StudlyCaps-regexp (point-max) t)
	(StudlyCaps-define-abbrev (match-string-no-properties 0)) )
      nil)))

(defun StudlyCaps-buffer-scan-p (buf)
  "Return non-nil if the buffer should be scanned."
  (buffer-file-name buf))

;;(defvar StudlyCaps-buffer-regexp "
(defun StudlyCaps-scan-buffers ()
  (interactive)
  (let ((buflist (buffer-list)) buf)
    (while (setq buf (car buflist))
      (setq buflist (cdr buflist))
      (when (StudlyCaps-buffer-scan-p buf)
        (message "Scanning '%s'..." (buffer-name buf))
        (save-excursion
          (set-buffer (car buflist))
          (StudlyCaps-scan-buffer))))))

(defun StudlyCaps-define-abbrev (StudlyCapWord)
  "Define STUDLYCAPWORD as an abbrev."
  (interactive "sEnter a StudlyCap abbrev:")
  (let ((word  (downcase StudlyCapWord)))
    (when (not (equal (gethash word (StudlyCaps-db)) StudlyCapWord))
      (message (format "%s -> %s" word StudlyCapWord))
      (puthash word StudlyCapWord (StudlyCaps-db))
      (define-global-abbrev word StudlyCapWord)
      (setq StudlyCaps-db-modified t))))

(defun StudlyCaps-add-word-at-point ()
  "Add the word at the point to the StudlyCaps abbrevs."
  (interactive)
  (let ((word (current-word t)))
    (if word 
	(StudlyCaps-define-abbrev word))) )

(provide 'StudlyCaps)
;;; StudlyCaps.el ends here
