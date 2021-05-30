# Lesson33

```
Домашнее задание
Строим бонды и вланы
в Office1 в тестовой подсети появляется сервера с доп интерфесами и адресами
в internal сети testLAN
- testClient1 - 10.10.10.254
- testClient2 - 10.10.10.254
- testServer1- 10.10.10.1
- testServer2- 10.10.10.1

равести вланами
testClient1 <-> testServer1
testClient2 <-> testServer2

между centralRouter и inetRouter
"пробросить" 2 линка (общая inernal сеть) и объединить их в бонд
проверить работу c отключением интерфейсов

для сдачи - вагрант файл с требуемой конфигурацией
Разворачиваться конфигурация должна через ансибл
```


*** Запускаем `vagrant up` ***

*** Проверяем VLAN ***

`vagrant ssh testServer1`
```
[vagrant@testServer1 ~]$ ip -c a show eth1.1
4: eth1.1@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:bb:86:6d brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.1/24 brd 10.10.10.255 scope global noprefixroute eth1.1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:febb:866d/64 scope link 
       valid_lft forever preferred_lft forever
```
```
[vagrant@testServer1 ~]$ ping -c 5 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.044 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.054 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.053 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=0.066 ms
64 bytes from 10.10.10.1: icmp_seq=5 ttl=64 time=0.062 ms

--- 10.10.10.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 3996ms
rtt min/avg/max/mdev = 0.044/0.055/0.066/0.012 ms

[vagrant@testServer1 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:4d:77:d3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 85904sec preferred_lft 85904sec
    inet6 fe80::5054:ff:fe4d:77d3/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:bb:86:6d brd ff:ff:ff:ff:ff:ff
    inet6 fe80::8ba:fd8f:4cc5:3185/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
4: eth1.1@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:bb:86:6d brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.1/24 brd 10.10.10.255 scope global noprefixroute eth1.1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:febb:866d/64 scope link 
       valid_lft forever preferred_lft forever

```


*** Проверяем BOND ***


`vagrant ssh centralRouter`

```
[vagrant@centralRouter ~]$ sudo more /proc/net/bonding/bond0 
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: fault-tolerance (active-backup)
Primary Slave: None
Currently Active Slave: eth1
MII Status: up
MII Polling Interval (ms): 1
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:e3:fa:a2
Slave queue ID: 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:a4:69:90
Slave queue ID: 0

```
В другом терминале запускаем ping:
```
[vagrant@centralRouter ~]$ ping 192.168.255.1
PING 192.168.255.1 (192.168.255.1) 56(84) bytes of data.
64 bytes from 192.168.255.1: icmp_seq=1 ttl=64 time=3.13 ms
64 bytes from 192.168.255.1: icmp_seq=2 ttl=64 time=0.962 ms
64 bytes from 192.168.255.1: icmp_seq=3 ttl=64 time=0.850 ms
64 bytes from 192.168.255.1: icmp_seq=4 ttl=64 time=0.726 ms
64 bytes from 192.168.255.1: icmp_seq=5 ttl=64 time=0.767 ms
64 bytes from 192.168.255.1: icmp_seq=6 ttl=64 time=0.880 ms
64 bytes from 192.168.255.1: icmp_seq=7 ttl=64 time=0.827 ms
64 bytes from 192.168.255.1: icmp_seq=8 ttl=64 time=0.986 ms
64 bytes from 192.168.255.1: icmp_seq=9 ttl=64 time=0.837 ms
64 bytes from 192.168.255.1: icmp_seq=10 ttl=64 time=0.799 ms

```

отключаем один из интерфейсов

```
[root@centralRouter vagrant]# ifdown eth2
Device 'eth2' successfully disconnected.
[root@centralRouter vagrant]# cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: fault-tolerance (active-backup)
Primary Slave: None
Currently Active Slave: eth1
MII Status: up
MII Polling Interval (ms): 1
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:e3:fa:a2
Slave queue ID: 0

```
Смотрим на другой терминал пинг не потерялся

