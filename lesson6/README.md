# Lesson 6

`
Работа с загрузчиком
1. Попасть в систему без пароля несколькими способами
2. Установить систему с LVM, после чего переименовать VG
3. Добавить модуль в initrd
4(*). Сконфигурировать систему без отдельного раздела с /boot, а только с LVM
Репозиторий с пропатченым grub: https://yum.rumyantsev.com/centos/7/x86_64/
PV необходимо инициализировать с параметром --bootloaderareasize 1m
`

***1. Попасть в систему без пароля:***

- Заходим в загрузчик до старта системы (перед тем, как начнется загрузка нужно успеть нажать на клашиву e)

- Затем находим строку linux16 и убираем из нее все значение console, а частности: console=tty0 console=ttyS0,115200n8 и добавляем rd.break, далее нажимаем Ctrl+X

- Произойдет загрузка системы в аварийном режиме, далее выполняем команду перемонтирования корня для чтения и записи - `mount -o remount,rw /sysroot`, далее chroot /sysroot

- Далее мы можем поменять пароль, выполнив команду passwd или passwd root

- После смены пароля необходимо создать скрытый файл .autorelabel в /, выполнив `touch /.autorelabel`, этот файл нужен, для того чтобы выполнить relabel файлов в системе, если selinux включен и находиться в режиме Enforcing. 
Без этого вы не сможете залогиниться в систему после ее загрузки. Однако в моем случае автоматически autorelabel не произошел.

- Далее мне пришлось снова зайти в grub до загрузки системы, после чего в строке linux16 передать ядру параметр загрузки enforcing=0, этот параметр говорит ядру, загрузить систему в режиме selinux=Permissive, в этом режиме система безопасности только лишь пишет в лог файл о найденных нарушениях в файлах, но не блокирует их работу.
Загрузка произошла, теперь мы можем зайти под root, введя измененный пароль

- Далее выполняем команду fixfiles -f relabel, происходит relabeling файлов, selinux перечитывает файлы системы и начинаем им доверять
После чего заходим в /etc/selinux/config и приводим строку к SELINUX=Enforcing или можем выполнить команду setenforce 1, что также включит полностью selinux.
Далее можем перезагружаться и попробовать войти в систему, это получится сделать. Как проверить что SELINUX выключен? - Проверить это можно через команду getenforce или увидев, что в файле /etc/selinux/config SELINUX равен Disabled.
Другой способ:

Попасть в систему для смены пароля можно также, успев до загрузки зайти в grub, нажам клавишу e, после чего добавить к строке linux16 init=/bin/sh и убрать из этой же строки console=tty0 console=ttyS0,115200n8 после чего нажать Ctrl+X для начала загрузки системы
Далее перемонтируем корень - mount -o remount,rw /, далее меняем пароль командой passwd, далее проверяем включен для SELUX cat /etc/selinux/config, если SELINUX=Enforcing, то меняем или на Permissive или Disabled, перезагружаемся
Заходим в систему по новому паролю, если SELINUX включен, то делаем fixfilex -f relabel