Gitorious.org
=========================

Contributing
-------------
Please see HACKING


License
-------------
Please see the LICENSE file


Further documentation
---------------------
Also see the files in the doc/ folder, they contain further detailed information
about setting up the application for specific linux distributions such as 
CenOS and Ubuntu/Debian


===========================================================================

Installation to a production environment -- a partial walkthrough.

===========================================================================

=== Make ready

You may want to make separate directories, away from everything, to hold the
site code and the git repository respectively.  In production, you'll be setting
up a special user account too, but don't worry about that yet.

For this intro we're going to use, as examples,

* /www/gitorious           -- directory for the website code
* /gitorious/repositories  -- root directory for the git repositories
* a MySQL database on localhost at port 3306 with a _mysql_ user 'gitorious'
* eventually, a system account named 'gitslave'

All of these can be adjusted to suit: specifically, dirs within your home
directory are fine, and (though MySQL has the best development coverage), the
website code should be free of mysql-isms/quirks.

=== Dependencies

First, install each of these Libraries/applications:

* Git                   (http://git-scm.org)
* Oniguruma C library   (http://www.geocities.jp/kosako3/oniguruma/)
* Sphinx                (http://sphinxsearch.com/)
* MySQL                 (or whatever)
* ImageMagick           (need version >= 6.3.0)
* libyadis-ruby
* aspell (optional)

Next, get the gitorious code itself:

  # mkdir /www/gitorious
  # cd    /www/gitorious
  # git clone git://gitorious.org/gitorious/repositories/mainline.git gitorious

Install each of these Ruby libraries/bindings/gems:

* mysql
* RedCloth      (http://redcloth.org/)
* mime-types    (http://rubyforge.org/projects/mime-types)
* oniguruma     (http://rubyforge.org/projects/oniguruma)
* textpow       (http://rubyforge.org/projects/textpow)
* chronic       (http://rubyforge.org/projects/chronic)
* rmagick       (http://rubyforge.org/projects/rmagick)
* geoip
* ultrasphinx
* rmagick       (in ubuntu I had to sudo apt-get install librmagick-ruby librmagick-ruby-doc)
* ruby-openid   
* ruby-iconv

  # gem install mysql RedCloth mime-types oniguruma textpow \
      chronic rmagick geoip ultrasphinx ruby-openid 

=== Database

First we need a database.  Use the mysql command line app, or phpMyAdmin, or
whatever to create first a user.  Referring to
http://www-css.fnal.gov/dsg/external/freeware/mysqlAdmin.html:

  # mysql -p  -u root -h localhost
  CREATE USER 'git'@'localhost' IDENTIFIED BY 'awesome_password';
  GRANT ALL PRIVILEGES ON `git\_%` . * TO 'git'@'localhost';
  FLUSH PRIVILEGES;
  CREATE DATABASE `git_dev`  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
  CREATE DATABASE `git_test` DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
  CREATE DATABASE `git_prod` DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

If you haven't set a password for the root user, now's a good time for that, too.

---

Edit database.yml to reflect your local database connection.  This is a standard
Ruby on Rails config file, not specific to gitorious -- if you have questions
here they're answered on the web, or consult the rails IRC channel.  (One hint:
NO TABS AT ALL in a .yml file.)  Our example:

development: 
  adapter:      mysql
  username:     git
  password:     awesome_password
  host:         localhost
  database:     git_dev

# The 'test' database will be erased and re-generated from your development
# database when you run 'rake'.  Must be different than the others!!
test:
  adapter:      mysql
  username:     git
  password:     awesome_password
  host:         localhost
  database:     git_test

production:
  adapter:      mysql
  username:     git
  password:     awesome_password
  host:         localhost
  database:     git_prod

---

Use rake to create the databases, migrate each, and run the tests:

rake db:create:all
for RAILS_ENV in development test production ; do
  rake db:migrate
done
rake test

FTW!

=== Gitorious config
  
* Copy the config/gitorious.sample.yml file to config/gitorious.yml

* Create a directory to hold project files
 
  # sudo mkdir  /gitorious/repositories
  
* Make a long, complicated string. You can run "apg -m 64", or if you lack 'apg'
    `dd if=/dev/random count=1 | md5sum` ,
  and put that on the 'cookie_secret' line (replacing the 'ssssht').

* Here's an example gitorious.yml (omitting comments) for local testing:

  cookie_secret: 26ee61bc4d6aa9870ab48d118a55e6ebcd11011dd6b61aa33536c024853c48d4e7c3d672aa57859
  repository_base_path:         "/gitorious/repositories"
  extra_html_head_data:
  system_message:
  gitorious_client_port:        3000
  gitorious_client_host:        localhost
  gitorious_host:               localhost       # gitorious.org
  gitorious_user:               gitslave
  

=== Get Sphinx going
for RAILS_ENV in development test production ; do
  RAILS_ENV=$RAILS_ENV rake ultrasphinx:configure
  RAILS_ENV=$RAILS_ENV rake ultrasphinx:index
done
RAILS_ENV=production rake ultrasphinx:daemon:start &

=== Tweak environment

* In environment.rb, uncomment config.action_controller.session -- choose a new
  session key string and generate your own secret key using something like
    (uptime; date) |sha1sum

* If you haven't set up your mailer, production mode will fail on login. Set
    config.action_mailer.delivery_method = :test
  for immediate gratification.

  
=== Run the server

From the gitorious directory,

# ./script/server

# RAILS_ENV=production ./script/server

It should start up on port 3000, listening only to local connections.  Ue "ssh
-L 3000:127.0.0.1:3000 -N you@yourbox.com" for testing.

You can now visit the site, sign up with your OpenID, put in your ssh key, and
poke around!  Once you get bored, make a test repository, wonder why nothing is
there yet, and then....

=== Hand-start the task_performer 

Key adoption, repo generation and other tasks are handled by the
'task_performer' script, which must be run periodically or on demand.
Run the script/task_performer and let it create the repository for you.

  # ./script/task_performer

   
4. Get your git on!

Push something to that repository (cd to a git repository with commits and do
"git push path/to/the/bare/repository/you/just/created master").  The actual
(bare) repos live in repository_base_path/#{project.slug}/#{repository.name}.git
Ex: the fubar project's mainline fork sits in a directory called
  
    /gitorious/repositories/fubar/mainline/fubar.git

This will be a 'bare' git repo -- you won't see files in it.

=== Button up

* In production, you'll want to have a limited-privileges user to run the git
  processes, just as you do for your webserver

* Make the tree invisible to any other non-root user; make the tree read-only by
  that user; but grant write access to the /tmp and /public/cache directories.

* Consider setting up the standard (lighttpd|nginx|apache) frontend <=> mongrel
  backend if you see traffic.


=== More Help

* Consult the mailinglist (http://groups.google.com/group/gitorious) or drop in
  by #gitorious on irc.freenode.net if you have questions.

=== Gotchas

Gitorious will add a 'forced command' to your ~/.ssh/authorized_keys file for
the target host: if you start finding ssh oddities suspect this first.  Don't
log out until you've ensured you can still log in remotely.
