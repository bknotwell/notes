(progn
   (require 'package)
   (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
   (package-initialize)
   (package-refresh-contents)

   ;; Ensure essential publishing packages are available
   (unless (package-installed-p 'htmlize) (package-install 'htmlize))
   (unless (package-installed-p 'org-roam) (package-install 'org-roam))

   ;; Automatically scan all .org files for third-party packages 
   ;; declared via use-package or package-install and install them
   (defun my/install-packages-from-orgs ()
     (dolist (file (directory-files-recursively "." "\\\\.org$$"))
       (with-temp-buffer
         (insert-file-contents file)
         ;; Search for use-package statements
         (goto-char (point-min))
         (while (re-search-forward "(use-package[[:space:]]+\\\\([a-zA-Z0-9_-]+\\\\)" nil t)
            (let ((pkg (intern (match-string 1))))
                (unless (or (package-installed-p pkg) 
                            (memq pkg package-built-in-packages))
                (message "Installing package from org file: %s" pkg)
                (condition-case err (package-install pkg)
                     (error (message "Failed to install %s: %s" pkg err))))))
                  ;; Search for explicit package-install calls
                (goto-char (point-min))
                (while (re-search-forward "package-install[[:space:]]+['\\\\(]?\\\\([a-zA-Z0-9_-]+\\\\)" nil t)
                  (let ((pkg (intern (match-string 1))))
                    (unless (or (package-installed-p pkg) 
                                (memq pkg package-built-in-packages))
                      (message "Installing package via package-install: %s" pkg)
                      (condition-case err
                          (package-install pkg)
                        (error (message "Failed to install %s: %s" pkg err)))))))))

      (my/install-packages-from-orgs)
      (defun roam-sitemap (title list)
         (progn (with-temp-file "./_sidebar.org"
                  (insert "#+OPTIONS: toc:nil\n")
                  (insert (org-list-to-org list)))
                  (concat      "#+OPTIONS: ^:nil author:nil toc:nil html-postamble:nil\n"
                                   "#+SETUPFILE: ./latexcss.theme\n"
                                   "#+TITLE: " title "\n\n"
                                   "Welcome to an eclectic collection of notes.\n"
                               (org-list-to-org list))))
            (defun roam-publication-wrapper (plist filename pubdir)
               (org-md-publish-to-md plist "./_sidebar.org" pubdir)
               (org-md-publish-to-md plist filename pubdir))

         (setq org-publish-project-alist
         '(("roam"
         :base-directory "."
         :auto-sitemap t
         :sitemap-function roam-sitemap
         :sitemap-title "Roam notes"
         :publishing-function roam-publication-wrapper
         :publishing-directory "./public"
         :section-number nil
         :table-of-contents nil
         :style "<link rel=\"stylesheet\" href=\"../other/mystyle.cs\" type=\"text/css\">")))
         (org-publish "roam"))
