# Octomacs

[Octopress][] support for [Emacs][]

# Installation

Place `octomacs.el` in your Emacs `load-path`, or add it to the load
path, and require `octomacs`.

```common-lisp
(add-to-list 'load-path "/path/to/octomacs")
(require 'octomacs)
```

# Configuring

Octomacs can be used without any configuration, though always
specifying the full path to the Octopress directory can get to be a
pain.

Octomacs can be configured to make using frequently visited Octopress
directories easier by adding them to `octomacs-workdir-alist`
(configuratble via the `octomacs` group).  Directories added to this
alist will be available for completion using the specified instance
name, when asked for an Octopress project.

# Supported features

* `octomacs-new-post` This interactive function will prompt for which
  Octopress project to use, and the title for a post.  It will then
  call the `new_post` rake task to make the new post, and open the
  newly created file.

# Optional features

* `ido` If ido.el is available, then it will be used when prompting
  for an Octopress project.

* `rvm` If rvm.el is available, then it will be used whenever Octomacs
  needs to run a command in the Octopress directory.

# Planned features

* Ability to call `rake generate`.
* Ability to call `rake new_page` with the name of a new page.
* Ability to call `rake deploy` (possibly with arguments).

[Octopress]: http://octopress.org "Octopress site"
[Emacs]: http://www.gnu.org/software/emacs/ "Emacs site"
