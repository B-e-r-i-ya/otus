# -*- mode: ruby -*-
# vim: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.box_check_update = true
 #config.vbguest.auto_update = false
    
  
  config.vm.define "r1" do |r1|
    r1.vm.hostname = 'r1'
    r1.vm.network "private_network", ip: "10.10.10.1", netmask: "255.255.255.0" , adapter: 2,  virtualbox__intnet: "r1"
    r1.vm.network "private_network", ip: "192.168.1.1", netmask: "255.255.255.252" , adapter: 3,  virtualbox__intnet: "r1r2"
    r1.vm.network "private_network", ip: "192.168.3.1", netmask: "255.255.255.252" , adapter: 4,  virtualbox__intnet: "r1r3"
    r1.vm.provider :virtualbox do |v|
    v.name = "r1"
    end

  end
  
  config.vm.define "r2", primary: true do |r2|
    r2.vm.hostname = 'r2'
    r2.vm.network "private_network", ip: "10.10.20.1", netmask: "255.255.255.0" , adapter: 2,  virtualbox__intnet: "r2"
    r2.vm.network "private_network", ip: "192.168.1.2", netmask: "255.255.255.252" , adapter: 3,  virtualbox__intnet: "r1r2"
    r2.vm.network "private_network", ip: "192.168.2.2", netmask: "255.255.255.252" , adapter: 4,  virtualbox__intnet: "r2r3"
    r2.vm.provider :virtualbox do |v|
    v.name = "r2"

    end

  
  
  end

  config.vm.define "r3" do |r3|
    r3.vm.hostname = 'r3'
    r3.vm.network "private_network", ip: "10.10.30.1", netmask: "255.255.255.0" , adapter: 2,  virtualbox__intnet: "r3"
    r3.vm.network "private_network", ip: "192.168.3.2", netmask: "255.255.255.252" , adapter: 3,  virtualbox__intnet: "r1r3"
    r3.vm.network "private_network", ip: "192.168.2.1", netmask: "255.255.255.252" , adapter: 4,  virtualbox__intnet: "r2r3"
    r3.vm.provider :virtualbox do |v|
    v.name = "r3"
    end

  end

  config.vm.provision "ansible" do |ansible|
    #ansible.verbose = "vvv"
    #ansible.inventory_path = './playbooks/all.yml'
    ansible.playbook = "./provision/playbook.yml"
    ansible.become = "true"
  end
  
end
