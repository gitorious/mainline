#!/bin/sh
# This script expects to run as root

# ONLY CHANGE THIS PART
export SERVER_NAME=gitorious.org
export GITORIOUS_REPO=git://gitorious.org/gitorious/akitaonrails-gitorious.git


# DO NOT CHANGE THIS PART
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -q -y build-essential apache2 mysql-server mysql-client git git-svn apg geoip-bin libgeoip1 libgeoip-dev sqlite3 libsqlite3-dev imagemagick libpcre3 libpcre3-dev zlib1g zlib1g-dev libyaml-dev libmysqlclient15-dev apache2-dev sendmail memcached

# Checks for 64-bit flag
while [ "$#" -gt "0" ]
do
  case $1 in
      -64)
          SIXTY_FOUR_FLAG=1
          ;;
  esac
  shift
done

/etc/init.d/mysql stop
mysqld_safe --skip-grant-tables &
sleep 5
mysql mysql -e "update user set Password=password('root') where User='root';"
/etc/init.d/mysql stop
/etc/init.d/mysql start

if [ -d ~/tmp ]; then rm -Rf ~/tmp; fi
mkdir ~/tmp && cd ~/tmp

test -f onig-5.9.1.tar.gz || wget http://www.geocities.jp/kosako3/oniguruma/archive/onig-5.9.1.tar.gz
test -d onig-5.9.1 || tar xvfz onig-5.9.1.tar.gz 
cd onig-5.9.1
./configure && make && make install
cd ..

test -f sphinx-0.9.8.tar.gz || wget http://www.sphinxsearch.com/downloads/sphinx-0.9.8.tar.gz
test -d sphinx-0.9.8 || tar xvfz sphinx-0.9.8.tar.gz
cd sphinx-0.9.8
./configure && make && make install
cd ..

test -f ImageMagick-6.5.6-10.tar.gz || wget ftp://ftp.imagemagick.net/pub/ImageMagick/ImageMagick-6.5.6-10.tar.gz
test -d ImageMagick-6.5.6-10 || tar xvfz ImageMagick-6.5.6-10.tar.gz
cd ImageMagick-6.5.6-10
./configure && make && make install
cd ..

if [ "$SIXTY_FOUR_FLAG" = "1" ]; then
    # unattended ruby enterprise install for all other OSes (only tested on Ubuntu 8.10 64-bit)
    # there may be some performance penalty
    # but Gitorious is not really a performance-hungry application
    #
    # More information about state of 64-bit support on Ruby Enterprise:
    # http://blog.phusion.nl/2008/12/30/ruby-enterprise-edition-second-sponsorship-campaign/
    # http://www.rubyenterpriseedition.com/faq.html#thirty_three_percent_mem_reduction

    cd ~/tmp
    test -f ruby-enterprise-1.8.7-2010.01.tar.gz || wget http://rubyforge.org/frs/download.php/68719/ruby-enterprise-1.8.7-2010.01.tar.gz
    tar xzvf ruby-enterprise-1.8.7-2010.01.tar.gz
    echo "" > unattended-install-script
    echo "/opt/ruby-enterprise" >> unattended-install-script
    cd ruby-enterprise-1.8.7-2010.01 && cat ../unattended-install-script | ./installer
    cd ..
    rm unattended-install-script
else
    test -f ruby-enterprise_1.8.7-2010.01_i386.deb || wget http://rubyforge.org/frs/download.php/68718/ruby-enterprise_1.8.7-2010.01_i386.deb
    dpkg -i ruby-enterprise_1.8.7-2010.01_i386.deb
fi

if [ -f /etc/profile.git ]; then cp /etc/profile.git /etc/profile; fi
cp /etc/profile /etc/profile.git
echo "export LD_LIBRARY_PATH=\"/usr/local/lib\"" >> /etc/profile
echo "export LDFLAGS=\"-L/usr/local/lib -Wl,-rpath,/usr/local/lib\"" >> /etc/profile

if [ -f /etc/ld.so.conf.git ]; then cp /etc/ld.so.conf.git /etc/ld.so.conf; fi
touch ld.so.conf
echo "/usr/local/lib" >> ld.so.conf
cat /etc/ld.so.conf >> ld.so.conf
cp /etc/ld.so.conf /etc/ld.so.conf.git
mv ld.so.conf /etc/ld.so.conf

. /etc/profile
ldconfig

test -f /usr/bin/ruby.old || mv /usr/bin/ruby /usr/bin/ruby.old
test -f /usr/bin/ruby || ln -s /usr/local/bin/ruby /usr/bin/ruby

gem install passenger --no-rdoc --no-ri --version 2.2.9
yes '' | /usr/local/bin/passenger-install-apache2-module

if [ -f /etc/apache2/mods-available/passenger.load ]; then rm /etc/apache2/mods-available/passenger.load; fi
if [ -f /etc/apache2/mods-available/passenger.conf ]; then rm /etc/apache2/mods-available/passenger.conf; fi
if [ -f /etc/apache2/sites-available/gitorious ]; then rm /etc/apache2/sites-available/gitorious; fi

touch /etc/apache2/mods-available/passenger.load
touch /etc/apache2/mods-available/passenger.conf
touch /etc/apache2/sites-available/gitorious
 
echo "LoadModule passenger_module /usr/local/lib/ruby/gems/1.8/gems/passenger-2.2.9/ext/apache2/mod_passenger.so" >> /etc/apache2/mods-available/passenger.load
echo "PassengerRoot /usr/local/lib/ruby/gems/1.8/gems/passenger-2.2.9" >> /etc/apache2/mods-available/passenger.load
echo "PassengerRuby /usr/local/bin/ruby" >> /etc/apache2/mods-available/passenger.conf
 
a2enmod passenger

echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/gitorious
echo "  ServerName $SERVER_NAME" >> /etc/apache2/sites-available/gitorious
echo "  DocumentRoot /var/www/gitorious/public" >> /etc/apache2/sites-available/gitorious
echo "</VirtualHost>" >> /etc/apache2/sites-available/gitorious
 
rm /etc/apache2/sites-enabled/000*
ln -s /etc/apache2/sites-available/gitorious /etc/apache2/sites-enabled/000-gitorious

cd /var/www
test -d gitorious || git clone $GITORIOUS_REPO gitorious
test -f /usr/local/bin/gitorious || ln -s /var/www/gitorious/script/gitorious /usr/local/bin/gitorious

gem install bundler
cd /var/www/gitorious && bundle install

cp /var/www/gitorious/doc/templates/ubuntu/git-daemon /etc/init.d
cp /var/www/gitorious/doc/templates/ubuntu/git-ultrasphinx /etc/init.d
cp /var/www/gitorious/doc/templates/ubuntu/git-poller /etc/init.d
cp /var/www/gitorious/doc/templates/ubuntu/stomp /etc/init.d

chmod +x /etc/init.d/git-ultrasphinx
chmod +x /etc/init.d/git-daemon
chmod +x /etc/init.d/git-poller
chmod +x /etc/init.d/stomp
update-rc.d -f stomp start 99 2 3 4 5 .
update-rc.d -f git-daemon start 99 2 3 4 5 .
update-rc.d -f git-ultrasphinx start 99 2 3 4 5 .
update-rc.d -f git-poller start 99 2 3 4 5 .

yes '' | adduser git --disabled-password
chown -R git:git /var/www/gitorious

su - git -c "mkdir ~/.ssh"
su - git -c "chmod 700 ~/.ssh"
su - git -c "touch ~/.ssh/authorized_keys"
cp /var/www/gitorious/config/database.sample.yml /var/www/gitorious/config/database.yml
cp /var/www/gitorious/config/gitorious.sample.yml /var/www/gitorious/config/gitorious.yml
cp /var/www/gitorious/config/broker.yml.example /var/www/gitorious/config/broker.yml

export SECRET=`apg -m 64 | tr -d '\n'`
cat /var/www/gitorious/config/gitorious.yml | sed \
  -e "s/cookie_secret\:.*$/cookie_secret\: $SECRET/g" \
  -e "s/repository_base_path\:.*$/repository_base_path\: \/home\/git/g" \
  -e "s/public_mode\:.*$/public_mode\: false/g" \
  -e "s/gitorious_client_port\:.*/gitorious_client_port\: 80/g" \
  -e "s/gitorious_host\:.*$/gitorious_host\: $SERVER_NAME/g" \
  > ~/tmp/foo
mv ~/tmp/foo /var/www/gitorious/config/gitorious.yml

cat /var/www/gitorious/config/database.yml | sed 's/password\:/password\: root/g' > ~/tmp/foo
mv ~/tmp/foo /var/www/gitorious/config/database.yml

chown git:git /var/www/gitorious/config/database.yml
chown git:git /var/www/gitorious/config/gitorious.yml
chown git:git /var/www/gitorious/config/broker.yml


su - git -c "if [ -f ~/.bash_profile ]; rm ~/.bash_profile; fi"
su - git -c "touch ~/.bash_profile"
su - git -c "echo 'export GEM_HOME=/usr/local/lib/ruby/gems/1.8/gems' >> ~/.bash_profile"

su - git -c "cd /var/www/gitorious && rake db:create RAILS_ENV=production"
su - git -c "cd /var/www/gitorious && rake db:setup RAILS_ENV=production"
su - git -c "cd /var/www/gitorious && rake ultrasphinx:bootstrap RAILS_ENV=production"

rm ~/tmp/crontab && touch ~/tmp/crontab
echo "*/2 * * * * /usr/bin/ruby /var/www/gitorious/script/task_performer" >> ~/tmp/crontab
echo "* */1 * * * cd /var/www/gitorious && /usr/local/bin/rake ultrasphinx:index RAILS_ENV=production" >> ~/tmp/crontab
mv ~/tmp/crontab /home/git
chown git:git /home/git/crontab
su - git -c "crontab -u git /home/git/crontab"

/etc/init.d/git-daemon start
/etc/init.d/git-ultrasphinx start
/etc/init.d/stomp start
/etc/init.d/git-poller start

cp /var/www/gitorious/doc/templates/ubuntu/gitorious-logrotate /etc/logrotate.d/gitorious
chmod 644 /etc/logrotate.d/gitorious

/etc/init.d/apache2 reload