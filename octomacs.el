;;; octomacs.el --- Octopress interface for Emacs
;;
;; Copyright (C) 2012 Jacob Helwig <jacob@technosorcery.net>
;;
;; Author: Jacob Helwig <jacob@technosorcery.net>
;; Homepage: http://technosorcery.net
;; Version: 0.0.1
;; URL: https://github.com/jhelwig/octomacs
;;
;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.
;;
;;; Commentary:
;;
;; octomacs.el provides an interface for interacting with Octopress
;; (http://octopress.org/).
;;
;; Add the following to your .emacs:
;;
;;     (add-to-list 'load-path "/path/to/octomacs")
;;     (require 'octomacs)
;;
;; Configuring Octomacs will make interaction a little nicer.
;; Specifically, setting `octomacs-workdir-alist'.
;;
;;     M-x customize-group RET octomacs RET
;;
;; If rvm.el is installed, Octomacs will attempt to use it whenever it
;; needs to run a command in the Octopress directory.
;;
;; If ido.el is installed, Octomacs will use it for prompting of which
;; Octopress project to use.
;;
;; Calling the interactive function `octomacs-new-post' will prompt
;; for which project to use (configurable from
;; `octomacs-workdir-alist', or can be manually specified as a path to
;; an Octopress instance), and for the title of the post to create.
;;

;;; Code:

(defgroup octomacs nil "Octopress interface for Emacs."
  :group 'tools)

(defcustom octomacs-workdir-alist nil
  "*The locations of Octopress working directories."
  :group 'octomacs
  :type '(repeat (cons (string :tag "Instance name")
                       (file   :tag "Location"))))

;;; Commands ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar octomacs-workdir-history nil
  "Project names & directories recently used with `octomacs'.")

(defun octomacs-read-project ()
  "Prompt for a project name (as defined in `octomacs-workdir-alist') or a directory name.
Returns the directory as defined in `octomacs-workdir-alist' or
the specified directory name.  Passes the directory through
`expand-file-name', and `directory-file-name'."
  (let (project-or-dir)
    (setq project-or-dir (if (featurep 'ido)
                             (ido-completing-read
                              "Choose Octopress project: "
                              (delete-dups (append
                                            (mapcar 'car octomacs-workdir-alist)
                                            octomacs-workdir-history))
                              nil
                              nil
                              nil
                              'octomacs-workdir-history
                              (car octomacs-workdir-history)
                              nil)
                           (completing-read
                            (format
                             "Choose Octopress project (default %s): "
                             (car octomacs-workdir-history))
                            (delete-dups (append
                                          (mapcar 'car octomacs-workdir-alist)
                                          octomacs-workdir-history))
                            nil
                            nil
                            nil
                            (cons 'octomacs-workdir-history 1)
                            (car octomacs-workdir-history)
                            nil)
                           ))
    (directory-file-name (expand-file-name (if (assoc project-or-dir octomacs-workdir-alist)
                                               (cdr (assoc project-or-dir octomacs-workdir-alist))
                                             project-or-dir)))))

(defun octomacs-read-post-name ()
  "Prompt for the title to use for a new post."
  (read-string "New post title: "))

(defun octomacs-new-post-interactive ()
  "Return the (interactive) arguments for `octomacs-new-post'."
  (let* ((project (octomacs-read-project))
         (post-name (octomacs-read-post-name)))
    (list post-name project)))

(defun octomacs-rake (directory task &optional &rest arguments)
  "Run rake task TASK with specified ARGUMENTS in DIRECTORY"
  (if (featurep 'rvm)
      (octomacs-rake-with-rvm directory task arguments)
    (octomacs-rake-without-rvm directory task arguments)))

(defun octomacs-shell-escape-string (string)
  "Escape single quotes in STRING."
  (replace-regexp-in-string "'" "'\\\\''" string))

(defun octomacs-format-rake-task-with-args (task &optional arguments)
  "Build a shell suitable string of the rake TASK name with the specified ARGUMENTS."
  (let ((arguments-string (if arguments
                              (format "[%s]" (mapconcat 'octomacs-shell-escape-string arguments ", "))
                            "")))
    (format "'%s%s'" task arguments-string)))

(defun octomacs-rake-with-rvm (directory task &optional arguments)
  "Run rake task TASK with specified ARGUMENTS in DIRECTORY using rvm"
  (let* ((default-directory (file-name-as-directory (expand-file-name directory)))
         ;; HACK: The rvm--* functions below will be searching for rvm config
         ;; files based on `buffer-file-name`, but we want them to search in the
         ;; Octopress directory, not the one where this file (octomacs.el) is
         ;; located. So shadow buffer-file-name for a bit.
         (buffer-file-name (expand-file-name directory))
         (rvmrc-info (or (rvm--load-info-rvmrc) (rvm--load-info-ruby-version) (rvm--load-info-gemfile)))
         (rvm-command (if rvmrc-info
                          (concat "rvm " (mapconcat 'identity rvmrc-info "@") " do ")
                        "")))
    (shell-command-to-string (format "%srake %s" rvm-command (octomacs-format-rake-task-with-args task arguments)))))

(defun octomacs-rake-without-rvm (directory task &optional arguments)
  "Run rake task TASK with specified ARGUMENTS in DIRECTORY"
  (let ((default-directory (file-name-as-directory (expand-file-name directory))))
    (shell-command-to-string (format "rake %s" (octomacs-format-rake-task-with-args task arguments)))))

;;; Public interface ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun octomacs-new-post (post-name directory)
  "Create a post called POST-NAME in the Octopress work tree in DIRECTORY"
  (interactive (octomacs-new-post-interactive))
  (let* ((octopress-directory (file-name-as-directory (expand-file-name directory)))
         (rake-output (octomacs-rake octopress-directory "new_post" post-name))
         (rake-output-match-pos (string-match "Creating new post: " rake-output))
         (file-name (if rake-output-match-pos
                        (concat octopress-directory (replace-regexp-in-string "\n" "" (substring rake-output (match-end 0))))
                      nil)))
    (if file-name
        (find-file file-name)
      (message (concat "Unable to create post: " rake-output)))))

(defun octomacs-project-interactive ()
  "Return the (interactive) arguments for `octomacs-shell'."
  (let* ((project (octomacs-read-project)))
    (list project)))

(defun octomacs-generate (directory)
  "Run rake generate in the Octopress work tree in DIRECTORY"
  (interactive (octomacs-project-interactive))
  (let* ((octopress-directory (file-name-as-directory (expand-file-name directory)))
         (rake-output (octomacs-rake octopress-directory "generate"))
         (rake-output-match-pos (string-match "Successfully generated site" rake-output)))
    ;; TODO: When run from inside Emacs, rake generate fails with this error:
    ;;
    ;; Configuration from /Users/wbert/scm/sandinmyjoints/williamjohnbert.com/_config.yml
    ;; Building site: source -> public
    ;; /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/gems/jekyll-0.11.2/lib/jekyll/convertible.rb:29:in `read_yaml': invali
    ;; d byte sequence in US-ASCII (ArgumentError)
    ;;         from /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/gems/jekyll-0.11.2/lib/jekyll/post.rb:39:in `initialize'
    ;;         from /Users/wbert/scm/sandinmyjoints/williamjohnbert.com/plugins/preview_unpublished.rb:23:in `new'
    ;;         from /Users/wbert/scm/sandinmyjoints/williamjohnbert.com/plugins/preview_unpublished.rb:23:in `block in read_po
    ;; sts'
    ;;         from /Users/wbert/scm/sandinmyjoints/williamjohnbert.com/plugins/preview_unpublished.rb:21:in `each'
    ;;         from /Users/wbert/scm/sandinmyjoints/williamjohnbert.com/plugins/preview_unpublished.rb:21:in `read_posts'
    ;;         from /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/gems/jekyll-0.11.2/lib/jekyll/site.rb:128:in `read_direct
    ;; ories'
    ;;         from /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/gems/jekyll-0.11.2/lib/jekyll/site.rb:98:in `read'
    ;;         from /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/gems/jekyll-0.11.2/lib/jekyll/site.rb:38:in `process'
    ;;         from /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/gems/jekyll-0.11.2/bin/jekyll:250:in `<top (required)>'
    ;;         from /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/bin/jekyll:19:in `load'
    ;;         from /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/bin/jekyll:19:in `<main>'
    ;;         from /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/bin/ruby_noexec_wrapper:14:in `eval'
    ;;         from /Users/wbert/.rvm/gems/ruby-1.9.3-p194@octopress/bin/ruby_noexec_wrapper:14:in `<main>'

    (if rake-output-match-pos
                        (message "Successfully generated site.")
      (message (concat "Error generating site:" rake-output)))))

(defun octomacs-shell (project)
  "Run a shell in the Octopress directory. TODO: Start rvm automatically."
  (interactive (octomacs-project-interactive))
  (let* ((default-directory project))
    (ansi-term (or explicit-shell-file-name
					       (getenv "ESHELL")
					       (getenv "SHELL")
					       "/bin/sh")
               (concat "*" "octopress-term" "*"))))

(provide 'octomacs)

;;; octomacs.el ends here
