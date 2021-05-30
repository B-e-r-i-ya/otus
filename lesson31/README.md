### Lesson 31
```
Домашнее задание VPN:

1. Между двумя виртуалками поднять vpn в режимах
- tun
- tap
Прочуствовать разницу.

2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку

*
3. Самостоятельно изучить, поднять ocserv и подключиться с хоста к виртуалке
```
### Part 1

Создаем Vagrantfile 

```
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
 config.vm.box = "centos/7"
 config.vm.define "server" do |server|
 #server.vm.hostname = "server.loc"
 server.vm.network "private_network", ip: "192.168.10.10"
 server.vm.hostname = "server"
 end
 config.vm.define "client" do |client|
 #client.vm.hostname = "client.loc"
 client.vm.network "private_network", ip: "192.168.10.20"
 client.vm.hostname = "client"
 end

  config.vm.provision "ansible" do |ansible|
    #ansible.verbose = "vvv"
    #ansible.inventory_path = './playbooks/all.yml'
    ansible.playbook = "./provision/playbook.yml"
    ansible.become = "true"
  end

end
```
Создаем Playbook

```
---
- hosts: all
  become: true
  tasks:
  - name: install packages
    yum:
      name: "{{ packages }}"
      state: present
    vars:
      packages:
      - epel-release
 
  - name: Отключаем SELinux
    selinux:
      state: disabled

  - name: install packages
    yum:
      name: "{{ packages }}"
      state: present
    vars:
      packages:
      - openvpn
      - iperf3

  - name: открываем порт 5201/tcp
    firewalld:
      port: 5201/tcp
      permanent: yes
      state: enabled

  - name: Настраиваем сервер
    block:
    - name: create key
      shell: openvpn --genkey --secret /etc/openvpn/static.key
    - name:  Synchronization key
      fetch:
        src: /etc/openvpn/static.key
        dest: key
    - name: configure server
      copy:
        src: server.conf
        dest: /etc/openvpn/server.conf
    - name: 
      systemd:
        state: started
        name: openvpn@server
        enabled: yes
    when: ansible_hostname == "server"

  - name: Настраиваем клиент
    block:
    - name: configure client
      copy:
        src: client.conf
        dest: /etc/openvpn/server.conf
    - name:  Synchronization key
      copy:
        src: key/server/etc/openvpn/static.key
        dest: /etc/openvpn/static.key
    - name: started server
      systemd:
        state: started
        name: openvpn@server
        enabled: yes
    when: ansible_hostname == "client"
```
Два конфигурационных файла для сервера и клиента

server.conf:
```
dev tap
ifconfig 10.10.10.1 255.255.255.0
topology subnet
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```
client.conf:
```
dev tap
remote 192.168.50.10
ifconfig 10.10.10.2 255.255.255.0
topology subnet
route 192.168.50.0 255.255.255.0
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```
Запускаем `vagrabt up`

После выполнения будет запущенно 2 машины с тонелем 10.10.10.0/24

Запускаем на сервере: `iperf3 -s`
			на клиенте: `iperf3 -c 10.10.10.1 -t 40 -i 5`

Результаты: 
	на клиенте:

```
[vagrant@client ~]$ sudo iperf3 -c 10.10.10.1
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 56212 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-1.00   sec  20.4 MBytes   171 Mbits/sec    1    172 KBytes       
[  4]   1.00-2.00   sec  20.7 MBytes   173 Mbits/sec   31    115 KBytes       
[  4]   2.00-3.00   sec  21.5 MBytes   181 Mbits/sec    0    208 KBytes       
[  4]   3.00-4.00   sec  22.4 MBytes   188 Mbits/sec    0    272 KBytes       
[  4]   4.00-5.00   sec  21.5 MBytes   180 Mbits/sec   35    112 KBytes       
[  4]   5.00-6.00   sec  23.3 MBytes   195 Mbits/sec    4    169 KBytes       
[  4]   6.00-7.01   sec  20.2 MBytes   169 Mbits/sec   39    197 KBytes       
[  4]   7.01-8.00   sec  22.7 MBytes   191 Mbits/sec  103    151 KBytes       
[  4]   8.00-9.00   sec  22.3 MBytes   188 Mbits/sec   13    179 KBytes       
[  4]   9.00-10.00  sec  23.9 MBytes   201 Mbits/sec   88    186 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-10.00  sec   219 MBytes   184 Mbits/sec  314             sender
[  4]   0.00-10.00  sec   218 MBytes   183 Mbits/sec                  receiver

iperf Done.
[vagrant@client sudo iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 56216 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec   109 MBytes   183 Mbits/sec  237    147 KBytes       
[  4]   5.00-10.01  sec   112 MBytes   188 Mbits/sec  145    137 KBytes       
[  4]  10.01-15.00  sec   110 MBytes   185 Mbits/sec  228    147 KBytes       
[  4]  15.00-20.00  sec   115 MBytes   192 Mbits/sec  217    138 KBytes       
[  4]  20.00-25.01  sec   113 MBytes   189 Mbits/sec  194    170 KBytes       
[  4]  25.01-30.00  sec   113 MBytes   190 Mbits/sec  157    114 KBytes       
[  4]  30.00-35.00  sec   114 MBytes   192 Mbits/sec  175    166 KBytes       
[  4]  35.00-40.01  sec   115 MBytes   192 Mbits/sec   79    144 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-40.01  sec   901 MBytes   189 Mbits/sec  1432             sender
[  4]   0.00-40.01  sec   900 MBytes   189 Mbits/sec                  receiver

iperf Done.

```
	на сервере:

```
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 56214
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 56216
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec  19.3 MBytes   162 Mbits/sec                  
[  5]   1.00-2.00   sec  20.7 MBytes   174 Mbits/sec                  
[  5]   2.00-3.00   sec  22.4 MBytes   188 Mbits/sec                  
[  5]   3.00-4.00   sec  22.2 MBytes   186 Mbits/sec                  
[  5]   4.00-5.00   sec  22.4 MBytes   188 Mbits/sec                  
[  5]   5.00-6.00   sec  23.3 MBytes   196 Mbits/sec                  
[  5]   6.00-7.00   sec  21.4 MBytes   179 Mbits/sec                  
[  5]   7.00-8.00   sec  22.4 MBytes   188 Mbits/sec                  
[  5]   8.00-9.00   sec  22.1 MBytes   186 Mbits/sec                  
[  5]   9.00-10.00  sec  22.9 MBytes   191 Mbits/sec                  
[  5]  10.00-11.00  sec  22.5 MBytes   189 Mbits/sec                  
[  5]  11.00-12.00  sec  18.3 MBytes   154 Mbits/sec                  
[  5]  12.00-13.00  sec  22.8 MBytes   192 Mbits/sec                  
[  5]  13.00-14.00  sec  23.2 MBytes   195 Mbits/sec                  
[  5]  14.00-15.00  sec  23.3 MBytes   195 Mbits/sec                  
[  5]  15.00-16.00  sec  23.0 MBytes   193 Mbits/sec                  
[  5]  16.00-17.00  sec  23.8 MBytes   200 Mbits/sec                  
[  5]  17.00-18.00  sec  22.5 MBytes   189 Mbits/sec                  
[  5]  18.00-19.01  sec  23.2 MBytes   193 Mbits/sec                  
[  5]  19.01-20.00  sec  22.2 MBytes   187 Mbits/sec                  
[  5]  20.00-21.00  sec  22.0 MBytes   184 Mbits/sec                  
[  5]  21.00-22.00  sec  22.9 MBytes   192 Mbits/sec                  
[  5]  22.00-23.00  sec  23.3 MBytes   195 Mbits/sec                  
[  5]  23.00-24.00  sec  22.3 MBytes   188 Mbits/sec                  
[  5]  24.00-25.00  sec  21.9 MBytes   184 Mbits/sec                  
[  5]  25.00-26.00  sec  23.2 MBytes   195 Mbits/sec                  
[  5]  26.00-27.00  sec  23.1 MBytes   194 Mbits/sec                  
[  5]  27.00-28.00  sec  22.5 MBytes   189 Mbits/sec                  
[  5]  28.00-29.00  sec  22.4 MBytes   188 Mbits/sec                  
[  5]  29.00-30.00  sec  21.6 MBytes   181 Mbits/sec                  
[  5]  30.00-31.00  sec  22.7 MBytes   190 Mbits/sec                  
[  5]  31.00-32.00  sec  22.5 MBytes   189 Mbits/sec                  
[  5]  32.00-33.00  sec  23.1 MBytes   194 Mbits/sec                  
[  5]  33.00-34.00  sec  23.3 MBytes   195 Mbits/sec                  
[  5]  34.00-35.00  sec  23.2 MBytes   194 Mbits/sec                  
[  5]  35.00-36.00  sec  22.6 MBytes   190 Mbits/sec                  
[  5]  36.00-37.00  sec  22.5 MBytes   189 Mbits/sec                  
[  5]  37.00-38.00  sec  23.2 MBytes   194 Mbits/sec                  
[  5]  38.00-39.00  sec  23.5 MBytes   197 Mbits/sec                  
[  5]  39.00-40.00  sec  22.9 MBytes   192 Mbits/sec                  
[  5]  40.00-40.06  sec  1.33 MBytes   188 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-40.06  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-40.06  sec   900 MBytes   188 Mbits/sec                  receiver

```


Меняем настройки `dev tap` на `dev tun`, перезапускаем сервис на обоих хостах и повторно запускаем нагрузку

Результат:
	на сервере:
	```	
	[vagrant@server ~]$ sudo iperf3 -s
	-----------------------------------------------------------
	Server listening on 5201
	-----------------------------------------------------------
	Accepted connection from 10.10.10.2, port 56218
	[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 56220
	[ ID] Interval           Transfer     Bandwidth
	[  5]   0.00-1.00   sec  18.6 MBytes   155 Mbits/sec                  
	[  5]   1.00-2.00   sec  20.1 MBytes   169 Mbits/sec                  
	[  5]   2.00-3.00   sec  21.8 MBytes   182 Mbits/sec                  
	[  5]   3.00-4.00   sec  22.0 MBytes   184 Mbits/sec                  
	[  5]   4.00-5.00   sec  20.0 MBytes   168 Mbits/sec                  
	[  5]   5.00-6.00   sec  21.5 MBytes   180 Mbits/sec                  
	[  5]   6.00-7.00   sec  22.2 MBytes   187 Mbits/sec                  
	[  5]   7.00-8.00   sec  21.8 MBytes   182 Mbits/sec                  
	[  5]   8.00-9.00   sec  22.2 MBytes   186 Mbits/sec                  
	[  5]   9.00-10.00  sec  21.0 MBytes   177 Mbits/sec                  
	[  5]  10.00-11.00  sec  21.4 MBytes   179 Mbits/sec                  
	[  5]  11.00-12.00  sec  22.0 MBytes   184 Mbits/sec                  
	[  5]  12.00-13.00  sec  22.7 MBytes   191 Mbits/sec                  
	[  5]  13.00-14.00  sec  22.8 MBytes   192 Mbits/sec                  
	[  5]  14.00-15.00  sec  23.1 MBytes   193 Mbits/sec                  
	[  5]  15.00-16.00  sec  22.0 MBytes   184 Mbits/sec                  
	[  5]  16.00-17.01  sec  22.7 MBytes   190 Mbits/sec                  
	[  5]  17.01-18.00  sec  21.8 MBytes   184 Mbits/sec                  
	[  5]  18.00-19.00  sec  21.9 MBytes   184 Mbits/sec                  
	[  5]  19.00-20.01  sec  22.1 MBytes   185 Mbits/sec                  
	[  5]  20.01-21.00  sec  21.6 MBytes   182 Mbits/sec                  
	[  5]  21.00-22.00  sec  18.8 MBytes   157 Mbits/sec                  
	[  5]  22.00-23.00  sec  22.7 MBytes   190 Mbits/sec                  
	[  5]  23.00-24.00  sec  19.5 MBytes   165 Mbits/sec                  
	[  5]  24.00-25.00  sec  22.2 MBytes   186 Mbits/sec                  
	[  5]  25.00-26.00  sec  23.0 MBytes   193 Mbits/sec                  
	[  5]  26.00-27.00  sec  19.1 MBytes   160 Mbits/sec                  
	[  5]  27.00-28.00  sec  21.7 MBytes   182 Mbits/sec                  
	[  5]  28.00-29.00  sec  20.9 MBytes   175 Mbits/sec                  
	[  5]  29.00-30.00  sec  17.7 MBytes   148 Mbits/sec                  
	[  5]  30.00-31.00  sec  22.1 MBytes   185 Mbits/sec                  
	[  5]  31.00-32.01  sec  22.1 MBytes   185 Mbits/sec                  
	[  5]  32.01-33.00  sec  22.1 MBytes   185 Mbits/sec                  
	[  5]  33.00-34.00  sec  22.2 MBytes   187 Mbits/sec                  
	[  5]  34.00-35.00  sec  21.8 MBytes   183 Mbits/sec                  
	[  5]  35.00-36.00  sec  22.3 MBytes   187 Mbits/sec                  
	[  5]  36.00-37.00  sec  21.9 MBytes   184 Mbits/sec                  
	[  5]  37.00-38.01  sec  22.5 MBytes   188 Mbits/sec                  
	[  5]  38.01-39.00  sec  22.4 MBytes   189 Mbits/sec                  
	[  5]  39.00-40.00  sec  22.6 MBytes   189 Mbits/sec                  
	[  5]  40.00-40.07  sec  1.77 MBytes   210 Mbits/sec                  
	- - - - - - - - - - - - - - - - - - - - - - - - -
	[ ID] Interval           Transfer     Bandwidth
	[  5]   0.00-40.07  sec  0.00 Bytes  0.00 bits/sec                  sender
	[  5]   0.00-40.07  sec   864 MBytes   181 Mbits/sec                  receiver
	```
	на клиенте:
	```
	[vagrant@client ~]$ sudo iperf3 -c 10.10.10.1 -t 40 -i 5
	Connecting to host 10.10.10.1, port 5201
	[  4] local 10.10.10.2 port 56220 connected to 10.10.10.1 port 5201
	[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
	[  4]   0.00-5.01   sec   105 MBytes   175 Mbits/sec  192    145 KBytes       
	[  4]   5.01-10.00  sec   109 MBytes   182 Mbits/sec  121    148 KBytes       
	[  4]  10.00-15.00  sec   112 MBytes   188 Mbits/sec  155    214 KBytes       
	[  4]  15.00-20.00  sec   111 MBytes   185 Mbits/sec  230    207 KBytes       
	[  4]  20.00-25.01  sec   105 MBytes   176 Mbits/sec  169    279 KBytes       
	[  4]  25.01-30.00  sec   102 MBytes   172 Mbits/sec  199    124 KBytes       
	[  4]  30.00-35.01  sec   111 MBytes   186 Mbits/sec  112    161 KBytes       
	[  4]  35.01-40.00  sec   111 MBytes   187 Mbits/sec  157    205 KBytes       
	- - - - - - - - - - - - - - - - - - - - - - - - -
	[ ID] Interval           Transfer     Bandwidth       Retr
	[  4]   0.00-40.00  sec   865 MBytes   181 Mbits/sec  1335             sender
	[  4]   0.00-40.00  sec   864 MBytes   181 Mbits/sec                  receiver
	iperf Done.
	```

### Выводы:

	Можно сделать вывод что скорость передачи достигается выше при `dev tun`.


### Part 2

`Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку`




