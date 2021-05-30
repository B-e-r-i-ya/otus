#!/bin/bash

lockfile=/tmp/lockfile
if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
then
	 trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT KILL
	 #================= Создаем функции ==================
	 		#========== Обратываем лог в нужный формат ===
			log_processing(){
							for ((i=1; i < ${line}; i++))
							do
							     str=`sed -n ${i}p ${logfile}`
							     text=`echo $str|awk '{print $1}'`

							     req=`echo $str|awk '{print $7}'|cut -c 1`
							     if [ ${req} = "/" ]
							     then
							     	req=`echo $str|awk '{print $7}'`
							     else
							     	req=`echo $str|awk '{print $6}'`
							     fi

							     cod=`echo $str|awk '{print $9}'`
							     if [ ${cod} = ${bash} ]
							     then
							     	cod=`sed -n ${i}p ${logfile}|awk '{print $7}'`
							     fi
							     text="${text} ${req} ${cod}"

							     echo $text >> /tmp/templog
							done
							} 

			#========== Считываем получившийся лог и обрабатываем значения 
			log_report(){
								tmpfile=/tmp/acccc
								n=10 #топ n значений для отчета
								line=`wc $1|awk '{print $1}'` #узнаем сколько строк в файле
								sed -n -e ${LINE},${line}p $1 > $tmpfile #считываем нужную часть во временный файл
								touch /tmp/report
								s=`cat access-4560-644067.log |awk '{print $4}'|head -n 1`
								po=`tail -n 1 ${tmpfile}|awk '{print $4}'`
								period="Период с ${s} по ${po}"
								echo $period >> /tmp/report
								echo "${n} IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта" >> /tmp/report
								cat ${tmpfile} | sort | awk '{print $1}' | uniq -c | sort -rn | head -n $n >> /tmp/report
								echo "${n} запрашиваемых адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта" >> /tmp/report
								cat ${tmpfile} | awk '{print $2}' | sort | uniq -c | sort -rn | head -n $n >> /tmp/report
								echo "все ошибки c момента последнего запуска" >> /tmp/report
								#cat ${tmpfile} | awk '{print $3}'| grep -v "-" | sort | uniq -c | sort -rn >> /tmp/report
								(cat ${tmpfile} | awk '{print $3}' | grep ^5|sort | uniq -c | sort -rn && cat ${tmpfile}| awk '{print $3}' | grep ^4|sort | uniq -c | sort -rn)|sort -rn >> /tmp/report
								echo "список всех кодов возврата с указанием их кол-ва с момента последнего запуска" >> /tmp/report
								cat ${tmpfile} | awk '{print $3}'|sort | uniq -c | sort -rn >> /tmp/report
								rm ${tmpfile}

							}

			send_mail()		{
								echo "test"
								
							}

	#================== Присваиваем значение переменным =================

			logfile=/home/stilet/otus/lesson7/access-4560-644067.log
			line=`wc ${logfile}|awk '{print $1}'`
			bash="\"-\""
			#
	#================= Вызываем функции ======================
			log_processing 
			log_report

rm -f "$lockfile"
	 trap - INT TERM EXIT
	else
	 echo "Failed to acquire lockfile: $lockfile."
	 echo "Held by $(cat $lockfile)"
fi