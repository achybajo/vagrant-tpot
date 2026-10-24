# -*- mode: ruby -*-
# vi: set ft=ruby :

# Los archivos de configuracion reales no se suben a git (contienen claves).
# Se crean a partir de los .example:  cp users.conf.example users.conf
%w[users.conf tpot.conf].each do |f|
  abort "Falta #{f}. Copia #{f}.example a #{f} y editalo." unless File.exist?(File.join(__dir__, f))
end

Vagrant.configure("2") do |config|
  config.vm.box      = "almalinux/10"
  config.vm.hostname = "tpot"

  # --- RED (EDITAR) ---------------------------------------------------------
  # bridge: nombre exacto de tu placa (VBoxManage list bridgedifs, campo "Name")
  # ip:     una IP LIBRE dentro de tu red, ej. si tu PC es 192.168.0.x usa 192.168.0.x
  config.vm.network "public_network",
    bridge: "NOMBRE_DE_TU_PLACA",
    ip: "192.168.1.50",
    use_dhcp_assigned_default_route: true

  # --- RECURSOS -------------------------------------------------------------
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "tpot-alma"
    vb.memory = 16384   # T-Pot Hive recomienda 16 GB
    vb.cpus   = 4
  end

  # --- APROVISIONAMIENTO ----------------------------------------------------
  config.vm.provision "file", source: "users.conf", destination: "/tmp/users.conf"
  config.vm.provision "file", source: "tpot.conf",  destination: "/tmp/tpot.conf"
  config.vm.provision "shell", path: "provision.sh"
end
