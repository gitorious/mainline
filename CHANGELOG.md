# Gitorious Changelog

## master (development version)

### Changes

* DEPRECATION: repositories directory sharding feature will be removed in the
  next major version (`enable_repository_dir_sharding`)

## 3.0.4 (2014-05-28)

### New features

* Sorting of repositories list on a project page (alphabetical)
* Ability to change user's website/blog URL (displayed on profile)

### Changes

* Rails version upgraded to 3.2.18
* Resque version upgraded to 1.25.2
* Code updated to work on Ruby 2.0

### Bugs fixed

* Fixed rendering of README files in asciidoc format
* Fixed display of group avatars on repository's Community page
* Fixed backup:snapshot rake task
* No more warning messages when running tests
* Many Resque jobs don't crash anymore on missing db records (they warn)

## 3.0.3 (2014-05-13)

### Changes

* Rails version upgraded to 3.2.17
* Commenting on commits and merge requests have been greatly improved
* Eclipse Public License has been added to project license selection
* Project license selection is now sorted alphabetically
* `bin/create-user` now accepts arguments
* Login (username) is now also mandatory for users signing up via OpenID
* `is_gitorious_dot_org` setting of `gitorious.yml` now defaults to `false`
* Other internal code cleanups and improvements
* Page title for repository browser now includes project/repository name

### Bugs fixed

* Merge Request diff page now displays correct diff also for older versions
* We don't try to display diffs for binary files anymore ;)
* Fixed display of default team avatars

## 3.0.2 (2014-04-09)

### Changes

* All configuration files (`config/*.yml`) are now processed with ERB
* `bin/unicorn` script always uses `config/unicorn.rb` config file

### Bugs fixed

* Fixed invocation of custom pre/post receive hooks when their paths are not in
  global section of `gitorious.yml`

## 3.0.1 (2014-03-24)

### New features

* Super groups
* Issue tracker (disabled by default)
* Ability to use external SMTP server by creating `config/smtp.yml` (see
  `config/smtp.sample.yml`)
* Users' SSH key management in admin panel
* Ability to sort projects list by either activity or alphabetically

### Changes

* Rails version upgraded to 3.2.16
* Rake tasks startup time was highly improved
* Many improvements to "Inbox" feature
* Scripts in bin/ are now bash scripts that prepare env (backwards compat.)
* Teams are now listed in alphabetical order
* Lots of cleanup and internal refactoring of code

### Bugs fixed

* Fixed XSS vulnerability on all pages showing user provided Markdown content
* Fixed Merge Request creation page - it properly handles diverged branches now
* Fixed Merge Request numbering
* Many bugfixes to LDAP based authorization
* Fixed notification email delivery in some specific cases
* All recipients of a message in the Inbox are now displayed
* Hyperlinking of [[Wiki Links]] properly handles spaces inside
* URLs in all Atom feeds are full, absolute URLs now
* Teams page displays all teams now instead of "active" only
* Fixed link to "add key" page in sign up email
* Removing team creator from the team is impossible now
* Activity feed can't be broken now by removing a repository
* Many other minor bugfixes

## 3.0.0 (2013-11-18)

### New features

* Brand new repository browser, with nicer UI, improved syntax highlighter
* Brand new "Dashboard", giving access to everything user is watching
* Brand new public profiles
* Brand new merge request pages
* Brand new settings page, with settings grouped into tabs
* Service hooks (with Sprint.ly as first integration)

### Changes

* Rails version upgraded to 3.2.15
* Ruby version upgraded to 1.9.3
* All pages have been carefully redesigned
* Diff pages now include a list of commits and a summary of changed files
* Lots of code cleanups, refactoring and removal of dead code

### Bugs fixed

* Countless bugfixes!
