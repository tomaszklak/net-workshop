Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # box image we will use
  config.vm.box = "ubuntu/jammy64"
  # install net-tools for all machines before they finish startup
  config.vm.provision "shell", inline: "apt-get install -y net-tools ruby"
  # disable default synced folder
  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.vm.define "client1" do |client1|
    client1.vm.hostname = "client1"
    client1.vm.synced_folder "shared/client1_data", "/vagrant", create: true
    client1.vm.synced_folder "shared/common", "/vagrant_common", create: true
    client1.vm.network "private_network", ip: "192.168.57.11", virtualbox__intnet: "net1"
  end

  config.vm.define "server1" do |server1|
    server1.vm.hostname = "server1"
    server1.vm.synced_folder "shared/server1_data", "/vagrant", create: true
    server1.vm.synced_folder "shared/common", "/vagrant_common", create: true
    server1.vm.network "private_network", ip: "192.168.57.22", virtualbox__intnet: "net1"
    server1.vm.network "private_network", ip: "192.168.58.33", virtualbox__intnet: "net2"
  end

  config.vm.define "server2" do |server2|
    server2.vm.hostname = "server2"
    server2.vm.synced_folder "shared/server2_data", "/vagrant", create: true
    server2.vm.synced_folder "shared/common", "/vagrant_common", create: true
    server2.vm.network "private_network", ip: "192.168.58.44", virtualbox__intnet: "net2"
    server2.vm.network "private_network", ip: "192.168.59.55", virtualbox__intnet: "net3"
  end

  config.vm.define "client2" do |client2|
    client2.vm.hostname = "client2"
    client2.vm.synced_folder "shared/client2_data", "/vagrant", create: true
    client2.vm.synced_folder "shared/common", "/vagrant_common", create: true
    client2.vm.network "private_network", ip: "192.168.59.66", virtualbox__intnet: "net3"
  end
end
