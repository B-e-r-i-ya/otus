# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
 :inetRouter => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.255.1', adapter: 2, netmask: "255.255.255.240", virtualbox__intnet: "router-net"} # intnet это vlan
               ]
  },

 :inetRouter2 => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.255.2', adapter: 2, netmask: "255.255.255.240", virtualbox__intnet: "router-net"}
               ]

  },

  :centralRouter => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.255.3', adapter: 2, netmask: "255.255.255.240", virtualbox__intnet: "router-net"},
                   {ip: '192.168.0.1', adapter: 3, netmask: "255.255.255.240", virtualbox__intnet: "central-net"}
                ]
  },
  
  :centralServer => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.0.2', adapter: 2, netmask: "255.255.255.240", virtualbox__intnet: "central-net"}
                ]
  }

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

        box.vm.provision "shell", inline: <<-SHELL
          mkdir -p ~root/.ssh
                cp ~vagrant/.ssh/auth* ~root/.ssh
        SHELL
        
        
        case boxname.to_s
        when "inetRouter"
          box.vm.provision "shell", run: "always", inline: <<-SHELL
              sudo yum install -y epel-release
              sudo yum install -y iptables-services
              sysctl net.ipv4.conf.all.forwarding=1
              iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
              ip route add 192.168.0.0/16 via 192.168.255.3
              sudo service iptables save
              systemctl restart network

              # Для пользователя vagrant задаем пароль vagrant
              echo "vagrant:vagrant" | chpasswd
              #Включаем авторизацию по паролю
              sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
              sudo systemctl restart sshd

              #Устанавливаем knockd
              sudo yum install -y wget libpcap*
              sudo rpm -ivh http://li.nux.ro/download/nux/dextop/el7Server/x86_64/knock-server-0.7-1.el7.nux.x86_64.rpm
              # Конфигурируем knockd
              sudo echo -e "[options]\nUseSyslog\ninterface = eth1\n[openSSH]\nsequence    = 7000,8000,9000\nseq_timeout = 5\nstart_command     = /sbin/iptables -I INPUT -s %IP% -p tcp --dport 22 -j ACCEPT\ncmd_timeout     = 360\nstop_command    = iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT\ntcpflags    = syn\n[closeSSH]\nsequence    = 9000,8000,7000\nseq_timeout = 5\ncommand     = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT\ntcpflags    = syn\n" > /etc/knockd.conf
              sudo echo -e "OPTIONS="-i eth1"" > /etc/sysconfig/knockd
              # Запускаем knockd
              sudo service knockd on
              sudo service knockd start

              #Блокируем 22 порт для входящих соединений
              sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
              sudo iptables -A INPUT -p tcp --dport 22 -j REJECT
              sudo service iptables save



            SHELL

        when "inetRouter2"
          # Пробрасываем 127.0.0.1:12003 на порт 8080 
          box.vm.network "forwarded_port", guest: 8080, host: 12003, host_ip: "127.0.0.1", id: "nginx"
          box.vm.provision "shell", run: "always", inline: <<-SHELL
            sudo echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf
            sudo sysctl -p
            # устанавливаем iptables
            sudo yum install -y iptables-services
            sudo systemctl enable iptables --now
                        
            # Очистка правил iptables
            sudo iptables -P INPUT ACCEPT
            sudo iptables -P FORWARD ACCEPT
            sudo iptables -P OUTPUT ACCEPT
            sudo iptables -t nat -F
            sudo iptables -t mangle -F
            sudo iptables -F
            sudo iptables -X
            
            # переадресуем пакеты с интерфейса eth0 порта 8080 на 192.168.0.2 порт 80
            sudo iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
            #обратный маршрут для ответов сервера          
            sudo iptables -t nat -A POSTROUTING --destination 192.168.0.2/32 -j SNAT --to-source 192.168.255.2
            sudo service iptables save
            # Убираем маршрут по умолчанию для eth0
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
            # Маршрут по умолчанию на inetRouter (eth1)
            echo "GATEWAY=192.168.255.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            #маршрут для 192.168.0.0/16 подсети
            sudo echo "192.168.0.0/16 via 192.168.255.3 dev eth1" > /etc/sysconfig/network-scripts/route-eth1
            sudo reboot
            SHELL

        when "centralRouter"
          box.vm.provision "shell", run: "always", inline: <<-SHELL
            sudo yum install -y epel-release
            #sudo yum install -y nmap
            # устанавливем knockd
            sudo yum install -y wget libpcap*
            sudo rpm -ivh http://li.nux.ro/download/nux/dextop/el7Server/x86_64/knock-0.7-1.el7.nux.x86_64.rpm
            sudo bash -c 'echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf'; sudo sysctl -p
            
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
            echo "GATEWAY=192.168.255.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            systemctl restart network
            sudo reboot
            SHELL

        when "centralServer"
          box.vm.provision "shell", run: "always", inline: <<-SHELL
            #настройка сети
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
            echo "GATEWAY=192.168.0.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            systemctl restart network
            

            # Установка nginx
            sudo yum install -y epel-release
            sudo yum install -y nginx
            sudo systemctl enable nginx --now

            sudo reboot
            SHELL
        
        end

      end

  end
  
  
end