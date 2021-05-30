#### SELinux: проблема с удаленным обновлением зоны DNS

Инженер настроил следующую схему:

- ns01 - DNS-сервер (192.168.50.10);
- client - клиентская рабочая станция (192.168.50.15).

При попытке удаленно (с рабочей станции) внести изменения в зону ddns.lab происходит следующее:
```bash
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
>
```
Инженер перепроверил содержимое конфигурационных файлов и, убедившись, что с ними всё в порядке, предположил, что данная ошибка связана с SELinux.

В данной работе предлагается разобраться с возникшей ситуацией.


#### Задание

- Выяснить причину неработоспособности механизма обновления зоны.
- Предложить решение (или решения) для данной проблемы.
- Выбрать одно из решений для реализации, предварительно обосновав выбор.
- Реализовать выбранное решение и продемонстрировать его работоспособность.


#### Формат

- README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них.
- Исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.



### РЕШЕНИЕ

Смотрим аудит лог:

```
[root@ns01 vagrant]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1606049743.211:2014): avc:  denied  { create } for  pid=5429 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.


```

Судя по логу не совпадает `context=system_u:system_r:named_t:s0`  с `tcontext=system_u:object_r:etc_t:s0`
Ищем исполняемый файл `find / -name named.ddns.lab.view1`
проверяем контекст найденного файла
	```
	[root@ns01 vagrant]# ls -Z /etc/named/dynamic/named.ddns.lab.view1
	-rw-rw----. named named system_u:object_r:etc_t:s0       /etc/named/dynamic/named.ddns.lab.view1
	```

## Выводы

Анализируя аулит лог выявляем проблему и 3 способа решения проблемы:

1. Изменить контекст исполняемого файла
2. Включить httpd_verify_dns (getsebool)
3. Создать модуль для selinux по данным аудит лога 