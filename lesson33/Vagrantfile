# -*- mode: ruby -*-
# vim: set ft=ruby :
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
:inetRouter => {
        :box_name => "centos/7",
        #:public => {:ip => '10.10.10.1', :adapter => 1},
        :net => [
                      {adapter: 2, auto_config: false, virtualbox__intnet: true},
                      {adapter: 3, auto_config: false, virtualbox__intnet: true},                
               ]
  },
  :centralRouter => {
        :box_name => "centos/7",
        :net => [
                    {adapter: 2, auto_config: false, virtualbox__intnet: true},
                    {adapter: 3, auto_config: false, virtualbox__intnet: true},      
                    {ip: '10.1.1.1', adapter: 6, netmask: "255.255.255.252", virtualbox__intnet: "central-net1"},
                                
                  
                ]
  },
  
  :office1Router => {
    :box_name => "centos/7",
    :net => [
               {ip: '10.1.1.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "central-net1"},
               {ip: '192.168.2.1', adapter: 3, netmask: "255.255.255.192", virtualbox__intnet: "dev1-net"},
               {adapter: 3, auto_config: false, virtualbox__intnet: true},
               {adapter: 4, auto_config: false, virtualbox__intnet: true},
            ]
  },

  :testServer1 => {
    :box_name => "centos/7",
    :net => [
               {adapter: 2, auto_config: false, virtualbox__intnet: true},
            ]
},

:testServer2 => {
    :box_name => "centos/7",
    :net => [
               {adapter: 2, auto_config: false, virtualbox__intnet: true},
            ]
},

:testClient1 => {
    :box_name => "centos/7",
    :net => [
               {adapter: 2, auto_config: false, virtualbox__intnet: true},
            ]
},

:testClient2 => {
    :box_name => "centos/7",
    :net => [
               {adapter: 2, auto_config: false, virtualbox__intnet: true},
            ]
},

}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|
      
    config.vm.define boxname do |box|

        box.vm.box = boxconfig[:box_name]
        box.vm.host_name = boxname.to_s

        config.vm.provider "virtualbox" do |v|
          v.memory = 256
        end

        boxconfig[:net].each do |ipconf|
          box.vm.network "private_network", ipconf
        end
        
        if boxconfig.key?(:public)
          box.vm.network "public_network", boxconfig[:public]
        end

        
        case boxname.to_s
          when "inetRouter"
            box.vm.provision "shell", run: "always", inline: <<-SHELL
              sysctl net.ipv4.conf.all.forwarding=1
              iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
              #ip route add 192.168.0.0/16 via 192.168.255.2
              SHELL
          when "centralRouter"
            box.vm.provision "shell", run: "always", inline: <<-SHELL
              echo net.ipv4.conf.all.forwarding=1  >> /etc/sysctl.conf
              echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
              sysctl -p /etc/sysctl.conf
              echo "GATEWAY=192.168.255.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
              echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
              systemctl restart network
              #ip route add 192.168.2.0/24 via 10.1.1.2
              #ip route add 192.168.1.0/24 via 10.1.2.2
              SHELL
          when "office1Router"
            box.vm.provision "shell", run: "always", inline: <<-SHELL
              echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
              sysctl -p /etc/sysctl.conf
              echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
              echo "GATEWAY=10.1.1.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
              systemctl restart network
              SHELL
          when "office1Server"
            box.vm.provision "shell", run: "always", inline: <<-SHELL
              echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
              echo "GATEWAY=192.168.2.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
              systemctl restart network
              SHELL
        
    end
  end

  end
        config.vm.provision "ansible" do |ansible|
          #ansible.verbose = "vvv"
          #ansible.inventory_path = './playbooks/all.yml'
          ansible.playbook = "./provision/playbook.yml"
          ansible.become = "true"
        end
end
