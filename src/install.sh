#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

cur_dir=$(pwd)
Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}
Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Install_Mongodb()
{
	. include/mongod_install.sh
}

Install_Redis()
{
	. include/redis_install.sh
}

Display_Selection()
{
	echo "==========================="
	Echo_Yellow "What do you want to install ?"
	echo "0:Install All"
	echo "1:Install Mongodb"
	echo "2:Install Redis"
	read -p "Enter your choice (0,1,2):" Install_Select
	
	case "${Install_Select}" in
	0)
		echo "You will install Mongodb Redis"
		sleep 3
		;;
	1)
		echo "You will install Mongodb"
		sleep 3
		;;
	2)
		echo "You will install Redis"
		sleep 3
		;;
	*)
		echo "No input,exit"
		exit
		;;
	esac
}
Select_Stack()
{
	Display_Selection
	if [ "${Install_Select}" = "0" ];then
		Install_Mongodb&&Install_Redis
	elif [ "${Install_Select}" = "1" ];then
		Install_Mongodb
	elif [ "${Install_Select}" = "2" ];then
		Install_Redis
	fi
}


Select_Stack 2>&1 | tee /root/lnmp-install.log
