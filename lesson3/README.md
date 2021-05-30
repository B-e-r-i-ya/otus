### Lesson3 

Работа с LVM
на имеющемся образе
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /

уменьшить том под / до 8G
выделить том под /home
выделить том под /var
/var - сделать в mirror
/home - сделать том для снэпшотов
прописать монтирование в fstab
попробовать с разными опциями и разными файловыми системами ( на выбор)
- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановится со снэпшота
- залоггировать работу можно с помощью утилиты script

-------

Запускаем `vagrant up`

по жавершении работы playbok, в котором пошагово все расписано, нужно зайти под пользователем root :


Отмонтируем раздел home 

```
umount -f /home
```
Восстановим snapshot
```
lvconvert --merge /dev/VolGroup00/home_snapshot
```
смонтируем обратно
```
sudo mount /home
```

Посмотрим файлы в директории после восстановления:
```
[vagrant@lvm ~]$ ls -la /home/
total 92160
drwxr-xr-x   3 root    root         147 Jan  5 15:27 .
drwxr-xr-x. 18 root    root         239 Jan  5 15:25 ..
-rw-r--r--   1 root    root    10485760 Jan  5 15:27 file_1
-rw-r--r--   1 root    root    10485760 Jan  5 15:27 file_2
-rw-r--r--   1 root    root    10485760 Jan  5 15:27 file_3
-rw-r--r--   1 root    root    10485760 Jan  5 15:27 file_4
-rw-r--r--   1 root    root    10485760 Jan  5 15:27 file_5
-rw-r--r--   1 root    root    10485760 Jan  5 15:27 file_6
-rw-r--r--   1 root    root    10485760 Jan  5 15:27 file_7
-rw-r--r--   1 root    root    10485760 Jan  5 15:27 file_8
-rw-r--r--   1 root    root    10485760 Jan  5 15:27 file_9
drwx------   4 vagrant vagrant       90 Jan  5 15:22 vagrant

```
