### Lesson 29

```
Домашнее задание
OSPF
- Поднять три виртуалки
- Объединить их разными vlan
1. Поднять OSPF между машинами на базе Quagga
2. Изобразить ассиметричный роутинг
3. Сделать один из линков "дорогим", но что бы при этом роутинг был симметричным
```
Запускаем `vagrant up`
Заходим `vagrant ssh r1`

Проверяем:
```
[vagrant@r1 ~]$ tracepath -n 10.10.20.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.20.1                                            1.206ms reached
 1:  10.10.20.1                                            0.534ms reached
     Resume: pmtu 1500 hops 1 back 1 

```
Меняем цену и проверяем:
```
[vagrant@r1 ~]$ sudo vtysh

Hello, this is Quagga (version 0.99.22.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

r1# configure  terminal  
r1(config)# interface  eth2
r1(config-if)# ip ospf  cost  1000
r1(config-if)# exit
r1(config)# exit
r1# exit
[vagrant@r1 ~]$ tracepath -n 10.10.20.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  192.168.3.2                                           1.063ms 
 1:  192.168.3.2                                           1.042ms 
 2:  10.10.20.1                                            1.781ms reached
     Resume: pmtu 1500 hops 2 back 2 
```