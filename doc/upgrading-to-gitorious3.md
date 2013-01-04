# Gitorious 3 Upgrade

Gitorious went through quite a few changes from version 2 to version
3. Most significantly Rails was updated from version 2.3.5 to 3.2.8.
This brought with it a few changes, and since the upgrade wasn't going
to be fully automated anyway, we took the opportunity to make a few
other long pending issues.

The steps to upgrade are as follows:

* Upgrade Ruby to version 1.9.3. This step is completely optional, but
  recommended. Gitorious did not properly support Ruby 1.9 in previous
  versions. Now it does, and you should take advantage of the
  performance boost that comes along with it. Future versions of
  Gitorious may no longer support Ruby 1.8.7. Note: If you upgrade
  Ruby, you must reinstall passenger if you are serving the app with
  it.
* Upgrade your gitorious.yml. This can be done automatically for you
  by running bin/upgrade-gitorious3-config. Your old configuration
  will mostly work. If you decide to not upgrade it at this point, the
  app will print deprecation warnings for settings that have changed.
  The upgrade script keeps a copy of your existing configuration.
* Run `bundle` in the Gitorious root.
* If you are using stomp server or ActiveMQ with the Gitorious stomp
  backend, you must replace it. Gitorious no longer supports stomp.
  The replacement is Redis and Resque. Install Redis from source, and
  take a look at doc/templates/upstart/resque-worker.conf for a sample
  configuration for Resque workers. If your installation is
  low-traffic and performance is not critical, you can also consider
  using the "sync" messaging adapter. Note however, that this will
  make pushes slow.
* Update your config/database.yml. The adapter used to be named
  "mysql", it is now called "mysql2".
* script/gitorious has moved to bin/gitorious. If you have this script
  symlinked onto your PATH, please make the symlink over, this time
  pointing it to bin/gitorious.
* script/git-proxy has moved to bin/git-proxy. If you have this script
  symlinked onto your PATH, please make the symlink over, this time
  pointing it to bin/git-proxy.
* Gitorious has migrated from using the ultrasphinx gem for intefacing
  with the Sphinx search engine. If you have rake tasks or crontab
  entries for controlling this, you should use the bin/search_engine
  script instead of shelling out to rake. This script will load the
  correct environment, including setting up a Rails environment and
  switching to the correct user, and can be called without changing
  directories into the Gitorious root directory.

  `/var/www/gitorious/app/bin/search_engine start`
  `/var/www/gitorious/app/bin/search_engine stop`
  `/var/www/gitorious/app/bin/search_engine restart`

  should all work.
* Restart your server.
