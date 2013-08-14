Vagrant.configure("2") do |config|
  config.vm.box = "quantal64"
  config.vm.network :forwarded_port, guest: 3000, host: 3000
  config.vm.synced_folder ".", "/vagrant", :nfs => true
end
