# Настраиваем split-dns

## Задачи
взять стенд https://github.com/erlong15/vagrant-bind
добавить еще один сервер client2
завести в зоне dns.lab имена:
- web1 смотрит на клиент1
- web2 смотрит на клиент2

завести еще одну зону newdns.lab
завести в ней запись
- www - смотрит на обоих клиентов

настроить split-dns
- клиент1 - видит обе зоны, но в зоне dns.lab только web1

- клиент2 видит только dns.lab

*) настроить все без выключения selinux


### завести в зоне dns.lab имена:
   ***- web1 смотрит на клиент1***
   ***- web2 смотрит на клиент2***

Добавил web1 и web2 в зону dns.lab

файлы:
named.dns.lab
named.dns.lab.rev


### завести еще одну зону newdns.lab

Создаем конфиг зоны:
```
$TTL 3600
$ORIGIN newdns.lab.
@               IN      SOA     ns01.newdns.lab. root.newdns.lab. (
                            1706202001 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.newdns.lab.
                IN      NS      ns02.newdns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

; All other records
www             IN      A       192.168.50.15
www             IN      A       192.168.50.16
```


### настроить split-dns

   ***- клиент1 - видит обе зоны, но в зоне dns.lab только web1***
   ***- клиент2 видит только dns.lab***

```
acl "view1" {
    127.0.0.1/32; //ns01
    192.168.50.10/32; //ns01
    192.168.50.11/32; //ns02
    192.168.50.15/32; //client
};

acl "view2" {
    192.168.50.16/32; //client2
};
```

```
view "view1" {
    match-clients { "view1"; };

    // root zone
    zone "." IN {
        type hint;
        file "named.ca";
    };

    // zones like localhost
    include "/etc/named.rfc1912.zones";
    // root's DNSKEY
    include "/etc/named.root.key";

    // lab's zone
    zone "dns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab";
    };

    // lab's zone reverse
    zone "50.168.192.in-addr.arpa" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab.rev";
    };

    // lab's ddns zone
    zone "ddns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.ddns.lab";
    };

    // newdns zone
    zone "newdns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.newdns.lab";
    };

    // newdns ddns zone
    zone "newddns.lab" {
        type master;
        file "/etc/named/named.newddns.lab";
    };
};

view "view2" {
    match-clients { "view2"; };

    // zones like localhost
    include "/etc/named.rfc1912.zones";
    // root's DNSKEY
    include "/etc/named.root.key";

    // lab's zone
    zone "dns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab";
    };

    // lab's zone reverse
    zone "50.168.192.in-addr.arpa" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab.rev";
    };

    // lab's ddns zone
    zone "ddns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.ddns.lab";
    };

};

```
***Проверяем***

```
[vagrant@client2 ~]$ host web
Host web not found: 3(NXDOMAIN)
[vagrant@client2 ~]$ host web1
web1.dns.lab has address 192.168.50.15


[vagrant@client ~]$ host web1
web1.dns.lab has address 192.168.50.15
[vagrant@client ~]$ host web2
Host web2 not found: 3(NXDOMAIN)
```