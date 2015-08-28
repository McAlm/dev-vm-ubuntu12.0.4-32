# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  
  # base box and URL where to get it if not present
  config.vm.box = "ubuntu/trusty64"

  # config for the appserver box
  config.vm.define "appserver" do |app|
   #app.vm.boot_mode = :gui
    app.vm.network :hostonly, "33.33.33.10"
    app.vm.host_name = "appserver01.local"
    app.vm.provision :puppet do |puppet|
      puppet.manifests_path = "manifests"
      puppet.manifest_file = "appserver.pp"
    end
  end
end
