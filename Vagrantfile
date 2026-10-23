# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "rockylinux/10"
  config.vm.hostname = "tpot-pps"

  # Deshabilitar carpeta compartida para evitar bloqueos de sincronización
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 8192
    vb.cpus   = 4
    vb.name   = "tpot-pps-node"
  end

  # Redireccionamiento de puertos de administración T-Pot (NAT)
  config.vm.network "forwarded_port", guest: 64294, host: 64294
  config.vm.network "forwarded_port", guest: 64295, host: 64295

  # Red Privada Host-Only: Canal de acceso estable independiente de Docker y T-Pot
	config.vm.network "public_network", bridge: "en0: Ethernet"

  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    set -e
    echo "[*] Configurando permisos sudo e instalando dependencias..."
    echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant
    chmod 0440 /etc/sudoers.d/vagrant
    dnf update -y
    dnf install -y git curl
  SHELL

#  config.vm.provision "shell", privileged: false, inline: <<-SHELL
#    set -e
#    if [ ! -d "/home/vagrant/tpotce" ]; then
#        git clone https://github.com/telekom-security/tpotce.git /home/vagrant/tpotce
#    fi
#    echo "[*] Entorno preparado en /home/vagrant/tpotce"
#  SHELL
 
  # Script automatizado que se ejecuta dentro de la VM tras el primer booteo
  config.vm.provision "shell", path: "provision/setup.sh"
end