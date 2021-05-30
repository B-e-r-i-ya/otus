### Lesson27

```
Сценарии iptables
1) реализовать knocking port
- centralRouter может попасть на ssh inetrRouter через knock скрипт
пример в материалах
2) добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост
3) запустить nginx на centralServer
4) пробросить 80й порт на inetRouter2 8080
5) дефолт в инет оставить через inetRouter

* реализовать проход на 80й порт без маскарадинга
```

Берем Vagrantfile с предвдущей лабораторной (25 занятие), убераем лишнии сервера(сети office1 и office2), добавляем InetRouter2(через который будем маршрутизировать Nginx)

Vagrantfile c подробными коменнариями прилагается

***запускаем `vagrant up`***


***Проверяем работу NGINX***
```
root@Profff:/home/stilet/otus/lesson27# curl http://127.0.0.1:12003
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css"> 

	html {
	background-image:url(img/html-background.png);
	background-color: white;
	font-family: "DejaVu Sans", "Liberation Sans", sans-serif;
	font-size: 0.85em;
	line-height: 1.25em;
	margin: 0 4% 0 4%;
	}

	body {
	border: 10px solid #fff;
	margin:0;
	padding:0;
	background: #fff;
	}

.....
```

***Проверяем Knock***

- заходим на centralRouter `vagrant ssh centralRouter`
- сначала посылаем "шифр" `knock 192.168.255.1 7000 8000 9000 -d 500`
- пробуем подключиться:
	```
	[vagrant@centralRouter ~]$ ssh vagrant@192.168.255.1
The authenticity of host '192.168.255.1 (192.168.255.1)' can't be established.
ECDSA key fingerprint is SHA256:8SFxOrcfELBvIYOEPZJEFZMX2uSnA9Nd+TBBNCFSCHk.
ECDSA key fingerprint is MD5:36:8f:8f:54:4a:01:e2:b9:0c:61:8e:17:89:92:7b:b5.
Are you sure you want to continue connecting (yes/no)? 
Warning: Permanently added '192.168.255.1' (ECDSA) to the list of known hosts.
vagrant@192.168.255.1's password: 
	```
 
 вводим пароль `vagrant`

 ```
 [vagrant@inetRouter ~]$ 
 ```

- Выходим и отправляем код закрытия порта `knock 192.168.255.1 9000 8000 7000 -d 500`, либо яерез 5 минут он сам закроется

***Проверяем хождение трафика***

Заходим на centralServer `vagrant ssh centralServer`

```
[vagrant@centralServer ~]$ tracepath -nb 8.8.8.8
 1?: [LOCALHOST]                                         pmtu 1500
 1:  192.168.0.1 (gateway)                                 0.320ms 
 1:  192.168.0.1 (gateway)                                 0.480ms 
 2:  192.168.255.1 (192.168.255.1)                         2.137ms 
 3:  no reply
 4:  no reply
 5:  no reply
 6:  94.251.84.150 (ns-bar3bras-po1-912.ll-bar.zsttk.ru)  13.538ms asymm 64 
 7:  188.43.27.210 (brl06rb.transtelecom.net)              7.025ms asymm 63 
 8:  188.43.30.218 (BL-gw.transtelecom.net)               16.472ms asymm 62 
 9:  188.43.30.185 (BlackList-gw.transtelecom.net)        15.540ms asymm 61 
10:  217.150.55.234 (mskn15-Lo1.transtelecom.net)         54.126ms asymm 60 
```

