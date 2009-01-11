#!/bin/sh
# This script expects to run as root

# ONLY CHANGE THIS PART
export SERVER_NAME=gitorious.org
export GITORIOUS_REPO=git://gitorious.org/gitorious/mainline.git


# DO NOT CHANGE THIS PART
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -q -y build-essential apache2 mysql-server mysql-client git git-svn apg geoip-bin libgeoip1 libgeoip-dev sqlite3 libsqlite3-dev imagemagick libpcre3 libpcre3-dev zlib1g zlib1g-dev libyaml-dev libmysqlclient15-dev apache2-dev sendmail

/etc/init.d/mysql stop
mysqld_safe --skip-grant-tables &
sleep 5
mysql mysql -e "update user set Password=password('root') where User='root';"
/etc/init.d/mysql stop
/etc/init.d/mysql start

mkdir ~/tmp
cd ~/tmp

wget http://www.geocities.jp/kosako3/oniguruma/archive/onig-5.9.1.tar.gz
tar xvfz onig-5.9.1.tar.gz 
cd onig-5.9.1
./configure && make && make install
cd ..

wget http://www.sphinxsearch.com/downloads/sphinx-0.9.8.tar.gz
tar xvfz sphinx-0.9.8.tar.gz
cd sphinx-0.9.8
./configure && make && make install
cd ..

wget ftp://ftp.imagemagick.net/pub/ImageMagick/ImageMagick-6.4.6-9.tar.gz
tar xvfz ImageMagick-6.4.6-9.tar.gz 
cd ImageMagick-6.4.6-9
./configure && make && make install
cd ..

wget http://rubyforge.org/frs/download.php/48625/ruby-enterprise_1.8.6-20081215-i386.deb
dpkg -i ruby-enterprise_1.8.6-20081215-i386.deb

echo "export PATH=/opt/ruby-enterprise/bin:$PATH" >> /etc/profile
echo "export LD_LIBRARY_PATH=\"/usr/local/lib\"" >> /etc/profile
echo "export LDFLAGS=\"-L/usr/local/lib -Wl,-rpath,/usr/local/lib\"" >> /etc/profile

touch ld.so.conf
echo "/usr/local/lib" >> ld.so.conf
cat /etc/ld.so.conf >> ld.so.conf
mv ld.so.conf /etc/ld.so.conf

source /etc/profile
ldconfig

mv /usr/bin/ruby /usr/bin/ruby.old
ln -s /opt/ruby-enterprise/bin/ruby /usr/bin/ruby

gem install passenger --no-rdoc --no-ri --version=2.0.6
yes '' | /opt/ruby-enterprise/bin/passenger-install-apache2-module

touch /etc/apache2/mods-available/passenger.load
touch /etc/apache2/mods-available/passenger.conf
touch /etc/apache2/sites-available/gitorious
 
echo "LoadModule passenger_module /opt/ruby-enterprise/lib/ruby/gems/1.8/gems/passenger-2.0.6/ext/apache2/mod_passenger.so" >> /etc/apache2/mods-available/passenger.load
echo "PassengerRoot /opt/ruby-enterprise/lib/ruby/gems/1.8/gems/passenger-2.0.6" >> /etc/apache2/mods-available/passenger.load
echo "PassengerRuby /opt/ruby-enterprise/bin/ruby" >> /etc/apache2/mods-available/passenger.conf
 
a2enmod passenger

echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/gitorious
echo "  ServerName $SERVER_NAME" >> /etc/apache2/sites-available/gitorious
echo "  DocumentRoot /var/www/gitorious/public" >> /etc/apache2/sites-available/gitorious
echo "</VirtualHost>" >> /etc/apache2/sites-available/gitorious
 
rm /etc/apache2/sites-enabled/000*
ln -s /etc/apache2/sites-available/gitorious /etc/apache2/sites-enabled/000-gitorious

gem install mime-types oniguruma textpow chronic BlueCloth ruby-yadis ruby-openid rmagick geoip ultrasphinx rspec rspec-rails RedCloth echoe daemons geoip --no-rdoc --no-ri

cd /var/www
git clone $GITORIOUS_REPO gitorious
ln -s /var/www/gitorious/script/gitorious /usr/local/bin/gitorious

cp /var/www/gitorious/doc/templates/ubuntu/git-daemon /etc/init.d
cp /var/www/gitorious/doc/templates/ubuntu/git-ultrasphinx /etc/init.d

chmod +x /etc/init.d/git-ultrasphinx
chmod +x /etc/init.d/git-daemon
update-rc.d -f git-daemon start 99 2 3 4 5 .
update-rc.d -f git-ultrasphinx start 99 2 3 4 5 .

yes '' | adduser git --disabled-password
chown -R git:git /var/www/gitorious

su - git -c "mkdir ~/.ssh"
su - git -c "chmod 700 ~/.ssh"
su - git -c "touch ~/.ssh/authorized_keys"
cp /var/www/gitorious/config/database.sample.yml /var/www/gitorious/config/database.yml
cp /var/www/gitorious/config/gitorious.sample.yml /var/www/gitorious/config/gitorious.yml

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

su - git -c "cd /var/www/gitorious && rake db:create RAILS_ENV=production"
su - git -c "cd /var/www/gitorious && rake db:migrate RAILS_ENV=production"
su - git -c "cd /var/www/gitorious && rake ultrasphinx:bootstrap RAILS_ENV=production"

rm ~/tmp/foo && touch ~/tmp/foo
echo "*/2 * * * * /opt/ruby-enterprise/bin/ruby /var/www/gitorious/script/task_performer" >> ~/tmp/foo
echo "* */1 * * * cd /var/www/gitorious && /opt/ruby-enterprise/bin/rake ultrasphinx:index RAILS_ENV=production" >> ~/tmp/foo
mv ~/tmp/foo /home/git
chown git:git /home/git/foo
su - git -c "crontab -u git /home/git/foo"

su - git -c "touch ~/.bash_profile"
su - git -c "echo 'export RUBY_HOME=/opt/ruby-enterprise' >> ~/.bash_profile"
su - git -c "echo 'export GEM_HOME=$RUBY_HOME/lib/ruby/gems/1.8/gems' >> ~/.bash_profile"
su - git -c "echo 'export PATH=$RUBY_HOME/bin:$PATH' >> ~/.bash_profile"

/etc/init.d/git-daemon start
/etc/init.d/git-ultrasphinx start

cp /var/www/gitorious/doc/templates/gitorious-logrotate /etc/logrotate.d/gitorious
chmod 644 /etc/logrotate.d/gitorious

/etc/init.d/apache2 reload