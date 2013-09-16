Vagrant.configure("2") do |config|
  config.vm.box = "quantal64"
  config.vm.network :forwarded_port, guest: 3000, host: 3000
  config.vm.network :forwarded_port, guest: 80, host: 80 
  config.vm.network :forwarded_port, guest: 81, host: 81 
  config.vm.network :forwarded_port, guest: 443, host: 443 
  config.vm.synced_folder ".", "/vagrant", :nfs => true
end
