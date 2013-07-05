# Gitorious 3 Upgrade

Gitorious went through quite a few changes from version 2 to version
3. Most significantly Rails was updated from version 2.3.5 to 3.2.8.
This brought with it a few changes, and since the upgrade wasn't going
to be fully automated anyway, we took the opportunity to make a few
other long pending issues.

## Install a Ruby version manager and an updated Ruby version

Getting the right Ruby version from your system's package manager may
be tricky. We highly recommend that you install two tools which will
make your life a lot easier.

### Install Ruby-install

First of all install
[ruby-install](https://github.com/postmodern/ruby-install), a simple
tool to install custom versions of Ruby either system-wide or for a
single user:

```sh
sudo -s
cd /tmp
wget -O ruby-install-0.2.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.2.1.tar.gz
tar -xzvf ruby-install-0.2.1.tar.gz
cd ruby-install-0.2.1/
make install
exit
```

### Install Ruby 1.9.3 with ruby-install

Next, use `ruby-install` to install Ruby 1.9.3-p448:

```sh
sudo -s
ruby-install ruby 1.9.3-p448
exit
```

### Install chruby

Now, install [chruby](https://github.com/postmodern/chruby), a
non-intrusive Ruby version switcher:

```sh
sudo -s
cd /tmp
wget -O chruby-0.3.6.tar.gz https://github.com/postmodern/chruby/archive/v0.3.6.tar.gz
tar -xzvf chruby-0.3.6.tar.gz
cd chruby-0.3.6/
make install
exit
```

Now, set up the newly installed Ruby version as system default:

```sh
sudo -s
cat << EOF > /etc/profile.d/chruby.sh
source /usr/local/share/chruby/chruby.sh
chruby 1.9.3-p448
EOF
exit
```

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
* Previous install guides recommended setting up a symlink to the
  gitorious script from Gitorious from somewhere on the default PATH
  on your system. If your server has such a symlink, remove it and
  replace it with a small wrapper script which allows you to use a
  non-system Ruby. Replace `GITORIOUS_ROOT` (if necessary), and run
  the following (please note that this assumes you installed chruby,
  ruby-install and the specified Ruby version above):

```sh
which gitorious >/dev/null 2>&1 && rm -f $(which gitorious) || echo "No symlink"

GITORIOUS_ROOT=/var/www/gitorious/app

cat << EOF > /usr/bin/gitorious
#!/bin/sh

RUBIES=(/opt/rubies/*)
source /etc/profile.d/chruby.sh

exec $GITORIOUS_ROOT/bin/gitorious \$@
EOF
chmod 0755 /usr/bin/gitorious
```

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

```sh
/var/www/gitorious/app/bin/search_engine start
/var/www/gitorious/app/bin/search_engine stop
/var/www/gitorious/app/bin/search_engine restart
```
  should all work.
* Restart your server.
