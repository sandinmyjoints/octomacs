(require 'octomacs)
(require 'ert)
(require 'el-mock)

(ert-deftest octomacs-unit-test-octomacs-shell-escape-string ()
  "Ensure `octomacs-shell-escape-string' properly escapes strings for use in single quoted strings."
  (should (equal "asdf"                        (octomacs-shell-escape-string "asdf")))
  (should (equal "as df"                       (octomacs-shell-escape-string "as df")))
  (should (equal "With an '\\'' in the string" (octomacs-shell-escape-string "With an ' in the string"))))

(ert-deftest octomacs-unit-test-octomacs-format-rake-task-with-args ()
  "Ensure `octomacs-format-rake-task-with-args' properly combines the argument list into the rake task."
  (should (equal "'task'"             (octomacs-format-rake-task-with-args "task")))
  (should (equal "'task'"             (octomacs-format-rake-task-with-args "task" nil)))
  (should (equal "'task'"             (octomacs-format-rake-task-with-args "task" ())))
  (should (equal "'task[arg1]'"       (octomacs-format-rake-task-with-args "task" '("arg1"))))
  (should (equal "'task[arg1, arg2]'" (octomacs-format-rake-task-with-args "task" '("arg1" "arg2")))))

(ert-deftest octomacs-unit-test-octomacs-format-rake-task-with-args-with-single-arg ()
  "Ensure `octomacs-format-rake-task-with-args' works when a single non-list 'args' is provided.
This has not yet been implemented, and is known to fail. When this is fixed, this should be rolled into the general test."
  :expected-result :failed
  (should (equal "'task[arg1]'" (octomacs-format-rake-task-with-args "task" "arg1"))))

(ert-deftest octomacs-unit-test-octomacs-new-post-interactive ()
  "Ensure `octomacs-new-post-interactive' gets required information."
  (with-mock
    (mock (octomacs-read-project) => "/path/to/project/")
    (mock (octomacs-read-post-name) => "New post title")
    (should (equal '("New post title" "/path/to/project/")
                   (octomacs-new-post-interactive)))))

(ert-deftest octomacs-unit-test-octomacs-read-project--with-ido ()
  "Ensure `octomacs-read-project' uses ido appropriately."
  (let ((octomacs-workdir-alist '(("Project name" . "~/project-dir"))))
    (with-mock
      (mock (featurep 'ido) => t)
      (mock (ido-completing-read) => "Project name")
      (not-called completing-read)
      (should (equal (directory-file-name (expand-file-name "~/project-dir"))
                     (octomacs-read-project))))))

(ert-deftest octomacs-unit-test-octomacs-read-project--without-ido ()
  "Ensure `octomacs-read-project' does not use ido when it's not present."
  (let ((octomacs-workdir-alist '(("Project name" . "~/project-dir"))))
    (with-mock
      (mock (featurep 'ido) => nil)
      (mock (completing-read) => "Project name")
      (not-called ido-completing-read)
      (should (equal (directory-file-name (expand-file-name "~/project-dir"))
                     (octomacs-read-project))))))

(ert-deftest octomacs-unit-test-octomacs-rake--with-rvm ()
  "Ensure `octomacs-rake' uses rvm when it's available."
  (with-mock
    (mock (featurep 'rvm) => t)
    (mock (octomacs-rake-with-rvm "/path/to/octopress" "new_post" '("arg1" "arg2" "arg3")))
    (not-called octomacs-rake-without-rvm)
    (octomacs-rake "/path/to/octopress" "new_post" "arg1" "arg2" "arg3")))

(ert-deftest octomacs-unit-test-octomacs-rake--without-rvm ()
  "Ensure `octomacs-rake' does not use rvm when it's not available."
  (with-mock
    (mock (featurep 'rvm) => nil)
    (mock (octomacs-rake-without-rvm "/path/to/octopress" "new_post" '("arg1" "arg2" "arg3")))
    (not-called octomacs-rake-with-rvm)
    (octomacs-rake "/path/to/octopress" "new_post" "arg1" "arg2" "arg3")))

(ert-deftest octomacs-unit-test-octomacs-rake-without-rvm ()
  "Ensure `octomacs-rake-without-rvm' runs the appropriate rake command"
  (with-mock
    (mock (shell-command-to-string "rake 'new_post'") => "command output")
    (should (equal "command output"
                   (octomacs-rake-without-rvm "~/directory" "new_post"))))
  (with-mock
    (mock (shell-command-to-string "rake 'new_post[arg1]'") => "command output")
    (should (equal "command output"
                   (octomacs-rake-without-rvm "~/directory" "new_post" '("arg1"))))))

(ert-deftest octomacs-unit-test-octomacs-rake-with-rvm ()
  "Ensure `octomacs-rake-with-rvm' runs the appropriate rake command"
  (with-mock
    (mock (rvm--rvmrc-locate) => "~/directory")
    (mock (rvm--rvmrc-read-version "~/directory") => '("ruby-version" "gemset-name"))
    (mock (shell-command-to-string "rvm ruby-version@gemset-name do rake 'new_post'") => "command output")
    (should (equal "command output"
                   (octomacs-rake-with-rvm "~/directory" "new_post"))))
  (with-mock
    (mock (rvm--rvmrc-locate) => "~/directory")
    (mock (rvm--rvmrc-read-version "~/directory") => '("ruby-version" "gemset-name"))
    (mock (shell-command-to-string "rvm ruby-version@gemset-name do rake 'new_post[arg1]'") => "command output")
    (should (equal "command output"
                   (octomacs-rake-with-rvm "~/directory" "new_post" '("arg1")))))
  (with-mock
    (mock (rvm--rvmrc-locate) => nil)
    (mock (shell-command-to-string "rake 'new_post'") => "command output")
    (should (equal "command output"
                   (octomacs-rake-with-rvm "~/directory" "new_post"))))
  (with-mock
    (mock (rvm--rvmrc-locate) => nil)
    (mock (shell-command-to-string "rake 'new_post[arg1]'") => "command output")
    (should (equal "command output"
                   (octomacs-rake-with-rvm "~/directory" "new_post" '("arg1"))))))

(ert-deftest octomacs-unit-test-octomacs-new-post--interactively ()
  "Ensure `octomacs-new-post' gets its interactive arguments from `octomacs-new-post-interactive'"
  (with-mock
    (mock (octomacs-new-post-interactive) => '("the post name" "/the/octopress/directory") :times 1)
    (mock (octomacs-rake (file-name-as-directory "/the/octopress/directory") "new_post" "the post name") => "Creating new post: /the/octopress/directory/the_post_name.markdown" :times 1)
    (mock (find-file))
    (call-interactively 'octomacs-new-post)))

(ert-deftest octomacs-unit-test-octomacs-new-post ()
  "Ensure `octomacs-new-post' gets the correct file"
  (with-mock
    (mock (octomacs-rake (file-name-as-directory (expand-file-name "~/dir")) "new_post" "title") => "Creating new post: title.markdown")
    (mock (find-file (concat (file-name-as-directory (expand-file-name "~/dir")) "title.markdown")) :times 1)
    (octomacs-new-post "title" "~/dir"))
  (with-mock
    (mock (octomacs-rake (file-name-as-directory (expand-file-name "~/dir")) "new_post" "title") => "Something went wrong")
    (not-called find-file)
    (octomacs-new-post "title" "~/dir")))
