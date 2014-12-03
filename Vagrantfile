# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.provider :virtualbox do |vb, override|
    override.vm.box = "ubuntu/trusty64"
    override.vm.network :forwarded_port, guest: 80, host: 8080
    override.vm.network :forwarded_port, guest: 443, host: 8443
    override.vm.network :forwarded_port, guest: 3000, host: 3000
    override.vm.synced_folder ".", "/vagrant", type: "nfs"
    override.vm.network "private_network", ip: "10.5.7.5"
    vb.memory = 2048
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.provision :shell, inline: <<EOS
    set -e

    export DEBIAN_FRONTEND=noninteractive

    apt-get update

    apt-get install -y memcached redis-server mysql-server git \
      build-essential libmysqlclient-dev libxml2-dev libxslt1-dev \
      libreadline6 libicu-dev imagemagick nodejs mysql-client cmake \
      pkg-config nginx

    cd /tmp
    wget -O ruby-install-0.4.3.tar.gz https://github.com/postmodern/ruby-install/archive/v0.4.3.tar.gz
    tar -xzvf ruby-install-0.4.3.tar.gz
    cd ruby-install-0.4.3/
    make install

    ruby-install -p https://gist.githubusercontent.com/plexus/10021261/raw/305492ebd17308e55eee1baab27568fafaa940cb/ruby-2.0-p451-readline.patch ruby 2.0

    cd /tmp
    wget -O chruby-0.3.8.tar.gz https://github.com/postmodern/chruby/archive/v0.3.8.tar.gz
    tar -xzvf chruby-0.3.8.tar.gz
    cd chruby-0.3.8/
    make install

    cat <<EOF >/etc/profile.d/chruby.sh
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh
EOF


    cat <<EOF >/usr/bin/gitorious
#!/bin/bash
source /etc/profile.d/chruby.sh
cd /vagrant
exec bin/gitorious "$@"
EOF

    chmod a+x /usr/bin/gitorious
EOS

end
