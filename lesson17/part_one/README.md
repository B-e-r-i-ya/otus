### PART_ONE

 ```
	Запустить nginx на нестандартном порту 3-мя разными способами:
	- переключатели setsebool;
	- добавление нестандартного порта в имеющийся тип;
	- формирование и установка модуля SELinux.
	К сдаче:
	- README с описанием каждого решения (скриншоты и демонстрация приветствуются).

 ```

 
## Описание:
 	Поднимаем машину на основе образа ` centos/7 ` с публичной сетью ` config.vm.network "public_network", ip: "" `
 	Устанавливаем EPEL release  устанавливает NGINX и стартуем его по средствам ansible 
 	```
	 	config.vm.provision "ansible" do |ansible|
		    ansible.playbook = "playbook.yml"
		    ansible.become = "true"
		end
 	```
# Vagrantfile

 ```
	# -*- mode: ruby -*-
	# vi: set ft=ruby :

	Vagrant.configure(2) do |config|
	  config.vm.box = "centos/7"

	  config.vm.provider "virtualbox" do |v|
		  v.memory = 512
	  end

	  config.vm.provision "ansible" do |ansible|
	    ansible.playbook = "playbook.yml"
	    ansible.become = "true"
	  end

	  config.vm.define "nginx" do |nginx|
	    config.vm.network "public_network", ip: "192.168.112.121"
	    nginx.vm.hostname = "nginxserver"
	  end
	end

 ```
# Playbook

```
--- 
- hosts: all
  become: true
  tasks: 
    - name: "Install EPEL release"
      shell: yum install -y epel-release
    - name: "Install NGINX"
      yum: 
        name: "{{ packages }}"
        state: present
      vars: 
        packages: 
          - nginx
    - name: "Enable/Start NGINX service"
      systemd: 
        enabled: true
        name: nginx
        state: started

```

### Начало экспиримента

 - заходим в виртуальную машину
			```
				# vagrant ssh
				$ sudo su
			```


 - меняем порт NGINX:

 		```
 			[root@nginxserver vagrant]# vi /etc/nginx/nginx.conf
 		```

 		```
	 			  server {
	        listen       8092 default_server;
	        listen       [::]:8092 default_server;
	        server_name  _;
	        root         /usr/share/nginx/html;
	        # Load configuration files for the default server block.
	        include /etc/nginx/default.d/*.conf;
	        location / {
	        }
	        error_page 404 /404.html;
	        location = /404.html {
	        }
 		```

 - Перезапускаем сервис:

 		```
 			[root@nginxserver vagrant]# systemctl restart nginx.service
 			Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
			[root@nginxserver vagrant]# 
 		```

 - Смотрим стату сервиса

 		```
	 		[root@nginxserver vagrant]# systemctl status nginx.service 
			● nginx.service - The nginx HTTP and reverse proxy server
			   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
			   Active: failed (Result: exit-code) since Sun 2020-11-22 11:08:35 UTC; 1min 1s ago
			  Process: 4132 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
			  Process: 4370 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
			  Process: 4369 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
			 Main PID: 4134 (code=exited, status=0/SUCCESS)
			Nov 22 11:08:35 nginxserver systemd[1]: Stopped The nginx HTTP and reverse p....
			Nov 22 11:08:35 nginxserver systemd[1]: Starting The nginx HTTP and reverse ....
			Nov 22 11:08:35 nginxserver nginx[4370]: nginx: the configuration file /etc/...k
			Nov 22 11:08:35 nginxserver nginx[4370]: nginx: [emerg] bind() to 0.0.0.0:80...)
			Nov 22 11:08:35 nginxserver nginx[4370]: nginx: configuration file /etc/ngin...d
			Nov 22 11:08:35 nginxserver systemd[1]: nginx.service: control process exite...1
			Nov 22 11:08:35 nginxserver systemd[1]: Failed to start The nginx HTTP and r....
			Nov 22 11:08:35 nginxserver systemd[1]: Unit nginx.service entered failed state.
			Nov 22 11:08:35 nginxserver systemd[1]: nginx.service failed.
			Hint: Some lines were ellipsized, use -l to show in full.
 		```

 - Установим policycoreutils-python для анализа auditlog
 
 		```
 		 [root@nginxserver vagrant]# yum install -y policycoreutils-python
 		```		

 - Анализируем аулитлог

 		```
	 		[root@nginxserver vagrant]# audit2why < /var/log/audit/audit.log 
			type=AVC msg=audit(1606043315.433:1312): avc:  denied  { name_bind } for  pid=4370 comm="nginx" src=8092 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
				Was caused by:
				The boolean nis_enabled was set incorrectly. 
				Description:
				Allow nis to enabled
				Allow access by executing:
				# setsebool -P nis_enabled 1
 		```

# Вариант 1

 		Сразу имеется подсказка:

 		"Allow access by executing:
	    # setsebool -P nis_enabled 1"
 
 - Выполняем предложенное

 		```
 		setsebool -P nis_enabled 1
 		```
 
 - Перезагружаем службу и проверяем работоспособность

 		```
	 		[root@nginxserver vagrant]# systemctl restart nginx.service 
			[root@nginxserver vagrant]# systemctl status nginx.service 
			● nginx.service - The nginx HTTP and reverse proxy server
			   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
			   Active: active (running) since Sun 2020-11-22 11:19:25 UTC; 1s ago
			  Process: 4407 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
			  Process: 4405 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
			  Process: 4404 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
			 Main PID: 4409 (nginx)
			   CGroup: /system.slice/nginx.service
			           ├─4409 nginx: master process /usr/sbin/nginx
			           └─4410 nginx: worker process
			Nov 22 11:19:24 nginxserver systemd[1]: Starting The nginx HTTP and reverse ....
			Nov 22 11:19:25 nginxserver nginx[4405]: nginx: the configuration file /etc/...k
			Nov 22 11:19:25 nginxserver nginx[4405]: nginx: configuration file /etc/ngin...l
			Nov 22 11:19:25 nginxserver systemd[1]: Failed to parse PID from file /run/n...t
			Nov 22 11:19:25 nginxserver systemd[1]: Started The nginx HTTP and reverse p....
			Hint: Some lines were ellipsized, use -l to show in full.
 		```

# Вариант 2

 - Смотрим к какому правилу добавить порт
	 ```
		[root@nginxserver vagrant]# semanage port -l| grep http 
		http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
		http_cache_port_t              udp      3130
		http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
		pegasus_http_port_t            tcp      5988
		pegasus_https_port_t           tcp      5989
	```
 - Выбираем  это правило:
 	```
 		http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
 	```
 - добавляем нужный порт в правило
 	```
	[root@nginxserver vagrant]# semanage port -a -t http_port_t -p tcp 8092
	```
 - Пререзапускаем сервис и проверяем
 	```
 	[root@nginxserver vagrant]# systemctl restart nginx
	[root@nginxserver vagrant]# systemctl status nginx
	● nginx.service - The nginx HTTP and reverse proxy server
	   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
	   Active: active (running) since Sun 2020-11-22 12:14:10 UTC; 4min 28s ago
	  Process: 25244 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
	  Process: 25242 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
	  Process: 25241 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
	 Main PID: 25245 (nginx)
	   CGroup: /system.slice/nginx.service
	           ├─25245 nginx: master process /usr/sbin/nginx
	           └─25246 nginx: worker process
	Nov 22 12:14:10 nginxserver systemd[1]: nginx.service: main process exited, ...L
	Nov 22 12:14:10 nginxserver systemd[1]: Stopped The nginx HTTP and reverse p....
	Nov 22 12:14:10 nginxserver systemd[1]: Unit nginx.service entered failed state.
	Nov 22 12:14:10 nginxserver systemd[1]: nginx.service failed.
	Nov 22 12:14:10 nginxserver systemd[1]: Starting The nginx HTTP and reverse ....
	Nov 22 12:14:10 nginxserver nginx[25242]: nginx: the configuration file /etc...k
	Nov 22 12:14:10 nginxserver nginx[25242]: nginx: configuration file /etc/ngi...l
	Nov 22 12:14:10 nginxserver systemd[1]: Failed to parse PID from file /run/n...t
	Nov 22 12:14:10 nginxserver systemd[1]: Started The nginx HTTP and reverse p....
	Hint: Some lines were ellipsized, use -l to show in full.
 	```

# Вариант 3

 - Создаем свое правило

 	```
 	[root@nginxserver vagrant]# audit2allow -M nginx_add --debug < /var/log/audit/audit.log 
	******************** IMPORTANT ***********************
	To make this policy package active, execute:
	semodule -i nginx_add.pp
	[root@nginxserver vagrant]# semodule -i nginx_add.pp
 	```
 - Перезагружаем и проверяем
 	```
 	[root@nginxserver vagrant]# systemctl restart nginx
	[root@nginxserver vagrant]# systemctl status nginx
	● nginx.service - The nginx HTTP and reverse proxy server
	   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
	   Active: active (running) since Sun 2020-11-22 12:29:00 UTC; 7s ago
	  Process: 25312 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
	  Process: 25310 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
	  Process: 25309 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
	 Main PID: 25314 (nginx)
	   CGroup: /system.slice/nginx.service
	           ├─25314 nginx: master process /usr/sbin/nginx
	           └─25315 nginx: worker process
	Nov 22 12:29:00 nginxserver systemd[1]: Starting The nginx HTTP and reverse ....
	Nov 22 12:29:00 nginxserver nginx[25310]: nginx: the configuration file /etc...k
	Nov 22 12:29:00 nginxserver nginx[25310]: nginx: configuration file /etc/ngi...l
	Nov 22 12:29:00 nginxserver systemd[1]: Failed to parse PID from file /run/n...t
	Nov 22 12:29:00 nginxserver systemd[1]: Started The nginx HTTP and reverse p....
	Hint: Some lines were ellipsized, use -l to show in full.
 	```