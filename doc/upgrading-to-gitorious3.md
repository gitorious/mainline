# Gitorious 3 Upgrade

Gitorious went through quite a few changes from version 2 to version
3. Most significantly Rails was updated from version 2.3.5 to 3.2.8.
This brought with it a few changes, and since the upgrade wasn't going
to be fully automated anyway, we took the opportunity to make a few
other long pending issues.

## IMPORTANT! Assumptions / Disclaimers

This upgrade walkthrough assumes a Gitorious 2 installation
similar to what you'd get if you ran the automated Gitorious Community
Installer for a recent version of Gitorious (for instance v2.4.12).

An alternative to upgrading your existing server is to simply install
Gitorious 3 on a new server from scratch, and use the snapshot/restore
scripts to migrate from the old instance to the new one.

If you have an older community installation, or a custom, manual
installation, please don't proceed with the upgrade instructions below
unless you are absolutely sure you know what you are doing.

## Upgrading an older version of Gitorious

If you do decide to attempt upgrading a pre-2.4.x version of
Gitorious, keep the following in mind:

* If you are using stomp server or ActiveMQ with the Gitorious stomp
  backend, you must replace it. Gitorious no longer supports stomp.
  The replacement is Redis and Resque. Install Redis from source, and
  take a look at doc/templates/upstart/resque-worker.conf for a sample
  configuration for Resque workers. If your installation is
  low-traffic and performance is not critical, you can also consider
  using the "sync" messaging adapter. Note however, that this will
  make pushes slow.

* If you upgrade Ruby (see below), you must reinstall passenger if you
are serving the app with it.

## Install a Ruby version manager and an updated Ruby version

Gitorious now supports Ruby 1.9.3, and you should take advantage of
the performance boost that comes along with it. Future versions of
Gitorious may no longer support Ruby 1.8.7.

Getting the right Ruby version from your system's package manager may
be tricky. We highly recommend that you install two tools which will
make your life a lot easier: ruby-install and chruby. The instructions
below will show how to do so in CentOS but should work in other
distros as well.

### Install Ruby-install

First of all install
[ruby-install](https://github.com/postmodern/ruby-install), a simple
tool to install custom versions of Ruby either system-wide or for a
single user:

```sh
sudo -s
cd /tmp
wget --no-check-certificate -O ruby-install-0.2.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.2.1.tar.gz
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


* Fetch the latest code from the Gitorious project, check out version 3. Example:

```sh
cd /var/www/gitorious/app/ && git fetch origin && git checkout next
```

* Install new dependencies: the native postgresql development libraries and the
  libicu development libraries. Example for yum-based package install in CentOS
  (64bit):

```sh
yum install postgresql-devel libicu-devel
```

* Make sure you have at least version 1.3.5 of the Bundler rubygem
  installed.

```sh
su git
source /etc/profile.d/chruby.sh && gem install bundler
```

  Then run "bundler -v" to verify.

* Remove any old local bundle-managed gems.

```sh
rm -rf /var/www/gitorious/app/.bundle
```

Then run bundler in in the Gitorious root:

```sh
cd /var/www/gitorious/app/ && bundle --deployment
```

Update all submodules:

```sh
cd /var/www/gitorious/app/ && env GIT_SSL_NO_VERIFY=true git submodule update --init --recursive
```

* Upgrade your gitorious.yml. This can be done automatically for you
  by running bin/upgrade-gitorious3-config.

```sh
cd /var/www/gitorious/app/
bin/upgrade-gitorious3-config config/gitorious.yml config/gitorious3.yml
cp config/gitorious.yml config/gitorious2.yml
cp config/gitorious3.yml config/gitorious.yml
```sh

  Your old configuration will mostly work. If you decide to not
  upgrade it at this point, the app will print deprecation warnings
  for settings that have changed.  The upgrade script keeps a copy of
  your existing configuration.

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
* Gitorious has migrated from using the ultrasphinx gem for interfacing
  with the Sphinx search engine. If you have rake tasks or crontab
  entries for controlling this, you should use the bin/search_engine
  script instead of shelling out to rake. This script will load the
  correct environment, including setting up a Rails environment and
  switching to the correct user, and can be called without changing
  directories into the Gitorious root directory.

```sh
/var/www/gitorious/app/bin/search_engine stop
/var/www/gitorious/app/bin/search_engine start
/var/www/gitorious/app/bin/search_engine restart
```
  should all work.

* If you don't have a /var/www/gitorious/app/config/unicorn.rb file,
  create it using the version controlled sample file:

```sh
cp /var/www/gitorious/app/config/unicorn.sample.rb /var/www/gitorious/app/config/unicorn.rb
```

* Update the monit and upstart config files to use the correct version of Ruby

If you have installed with the Gitorious Community Installer you use
Monit to keep services like Unicorn, Thinking Sphinx etc
running. You'll need to tell Monit to use the specific Ruby version
you installed above for running each of the services.

Update the monit config files handling starting/stopping the services
in question:

#/etc/monit.d/unicorn.monit
```sh
check process unicorn with pidfile /var/www/gitorious/app/tmp/pids/unicorn.pid
  start program = "/usr/local/bin/chruby-exec ruby-1.9.3-p448 -- /var/www/gitorious/app/bin/unicorn -c config/unicorn.rb -D"
  stop program = "/bin/sh -c '/bin/kill `cat /var/www/gitorious/app/tmp/pids/unicorn.pid`'"
```

If you have the old git-daemons monit script, remove it: Replace it with a new git-proxy monit script, see below.

```sh
rm /etc/monit.d/git-daemons.monit
touch /etc/monit.d/git-proxy.monit
```

#/etc/monit.d/git-proxy.monit
```sh
check process git-proxy with pidfile /var/www/gitorious/app/log/git-proxy.pid
  start program = "/usr/local/bin/chruby-exec ruby-1.9.3-p448 -- /var/www/gitorious/app/bin/git-proxy --pid=/var/www/gitorious/app/log/git-proxy.pid --detach --log=/var/www/gitorious/app/log/git-proxy.log1"
  stop program = "/bin/kill `cat /var/www/gitorious/app/log/git-proxy.pid`"
  if failed port 9418 then restart
```

#/etc/monit.d/thinking-sphinx.monit
```sh
check process thinking-sphinx with pidfile /var/www/gitorious/app/log/searchd.production.pid
  start program = "/usr/local/bin/chruby-exec ruby-1.9.3-p448 -- /var/www/gitorious/app/bin/rake ts:start"
  stop program = "/usr/local/bin/chruby-exec ruby-1.9.3-p448 -- /var/www/gitorious/app/bin/rake ts:stop"
```

#/etc/init/resque-worker.conf
```sh
description "Run a Resque worker on all queues"
author "Marius Mårnes Mathiesen <marius@gitorious.com>"

start on started rc RUNLEVEL=[35]
stop on runlevel [06]

env PATH=/bin:/usr/bin:/usr/local/bin
env QUEUE=*
env PIDFILE=/var/www/gitorious/app/tmp/pids/resque-worker1.pid

exec /usr/local/bin/chruby-exec ruby-1.9.3-p448 -- /var/www/gitorious/app/bin/rake resque:work
respawn
```

* Rebuild the search index

```sh
cd /var/www/gitorious/app && bin/rake ts:rebuild
```

* Make sure the git user owns all files in the Gitorious application

```sh
cd /var/www/gitorious/app/ && chown -R git:git *
```


* Stop all currently running services, clean out pidfiles

```sh
monit stop all
find . | grep [.]pid | xargs rm
monit start all
```

* Reboot your server to check if everything comes up again.
