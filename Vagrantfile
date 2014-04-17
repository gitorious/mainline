# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.provider :virtualbox do |vb, override|
    override.vm.box = "quantal64"
    override.vm.network :forwarded_port, guest: 3000, host: 3000
    override.vm.network :forwarded_port, guest: 80, host: 80 
    override.vm.network :forwarded_port, guest: 81, host: 81 
    override.vm.network :forwarded_port, guest: 443, host: 443 
    override.vm.synced_folder ".", "/vagrant", nfs: true
  end

  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "precise64"
    override.vm.network :forwarded_port, guest: 80, host: 8080
    override.vm.network :forwarded_port, guest: 5678, host: 5678
  end

end
