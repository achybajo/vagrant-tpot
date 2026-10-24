# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "almalinux/10"
  config.vm.hostname = "tpot-pps"
  config.vm.network "private_network", ip: "192.168.56.10"
#  config.vm.network "public_network", bridge: "Ethernet", ip: "192.168.1.50", use_dhcp_assigned_default_route: true
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 16384
    vb.cpus = 4
  end
  config.vm.provision "file", source: "tpot.conf",  destination: "/tmp/tpot.conf"
  config.vm.provision "file", source: "users.conf", destination: "/tmp/users.conf"
  config.vm.provision "shell", path: "provision.sh", privileged: true
end