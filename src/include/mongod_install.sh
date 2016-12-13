#!/bin/bash 
#自动安装mongodb和初始化配置
#缺省的配置如下
 
logdir=/tmp/log/shell          #日志路径
log=$logdir/shell.log            #日志文件 
is_font=1                #终端是否打印日志: 1打印 0不打印 
is_log=0                 #是否记录日志: 1记录 0不记录
#random_time=$(date +%Y%m%d_%H%M%S)
PWD=$(pwd)
#mongodb版本
mongodb_pakges="mongodb-linux-x86_64-rhel62-3.4.0.tgz" 

#download
Download_Files()
{
	local URL=$1
	local FileName=$2
	if [ -s "${FileName}" ];then
		echo "${FileName} [found]"
	else
		echo "Notice:${FileName} not found!! Download now..."
		wget -c --progress=bar:froce ${URL}
	fi
}
#获取时间
datef(){
date "+%Y-%m-%d %H:%M:%S"
}
#输出信息 
print_log(){
if [[ $is_log -eq 1  ]];then
[[ -d $logdir ]] || mkdir -p $logdir
echo "[ $(datef) ] $1" >> $log
fi
if [[ $is_font -eq 1  ]];then
echo -e "[ $(datef) ] $1"
fi
}

Install_Mongodb(){
if [[  -d  /usr/local/mongodb  ]];then
print_log "mongodb已经安装,请不要再重复安装:/usr/local/mongodb"
echo "=============================================================="
Echo_Yellow "What do you want to Remove ?"
echo "1:Remove Mongodb"
echo "2:No Mongodb"
read -p "Enter your choice (1,2):" Install_Select
echo "============================================================="
case "${Install_Select}" in
1)
        echo "You will Remove Mongodb"
        sleep 3
        ;;
2)
        echo "You will No Mongodb"
        sleep 3
        ;;
*)
        echo "No input,exit"
        exit
        ;;
esac

if [ "${Install_Select}" = "1" ];then
        rm -rf /usr/local/mongodb
elif [ "${Install_Select}" = "2" ];then
        exit
fi

fi
print_log "下载指定版本的mongodb"
#Download_Files https://fastdl.mongodb.org/linux/$mongodb_pakges
Download_Files https://fastdl.mongodb.org/linux/$mongodb_pakges
print_log "解压文件中,请稍后..."

#Determine whether to download a success
if [ $? -eq 0 ];then
tar -zxf $mongodb_pakges  -C /usr/local/
mv /usr/local/$(echo $mongodb_pakges|awk -F'/' '{print $NF}'|sed "s/.tgz//g")   /usr/local/mongodb

if [[  -d  /usr/local/mongodb  ]];then
print_log "mongodb已经安装成功:/usr/local/mongodb"
else
print_log "mongodb已经安装失败:/usr/local/mongodb"
fi

#指定mongodb数据文件存放位置
dbpath=/usr/local/mongodb/db

if [[ -d $dbpath  ]];then
print_log "mongodb: 数据目录:$dbpath已经存在"
else
mkdir -p $dbpath 
fi 

#指定mongodb配置文件位置
mongodblog=/usr/local/mongodb/conf

if [[ !  -d $mongodblog ]];then
mkdir -p  $mongodblog
cat >/usr/local/mongodb/conf/mongodb.conf<<'EOF'
dbpath=/usr/local/mongodb/db #数据目录存在位置
logpath=/usr/local/mongodb/mongodb.log #日志文件存放目录
port=27017  #端口
fork=true  #以守护程序的方式启用，即在后台运行

verbose=true
vvvv=true #启动verbose冗长信息，它的级别有 vv~vvvvv，v越多级别越高，在日志文件中记录的信息越详细.
maxConns=20000 #默认值：取决于系统（即的ulimit和文件描述符）限制。MongoDB中不会限制其自身的连接。
logappend=true #写日志的模式:设置为true为追加。
pidfilepath=/usr/local/mongodb/mongo.pid
EOF
else
print_log "mongodb: 日志目录:$mongodblog已经存在"
fi

profile_num=$(cat /etc/profile |grep mongodb |wc -l)
if [[ $profile_num -eq 0  ]];then
echo "MONGODBPATH=/usr/local/mongodb/bin:\$PATH"  >> /etc/profile
echo "export MONGODBPATH" >> /etc/profile
fi

if [[ ! -f $mongodb_init   ]];then
cat >/etc/init.d/mongod<<'EOF'
#!/bin/sh  
# chkconfig: 2345 93 18  
# author:QingFeng 
# description:MongoDB(MongoDB-2.4.9)  

#默认参数设置
#mongodb 家目录  
MONGODB_HOME=/usr/local/mongodb

#mongodb 启动命令  
MONGODB_BIN=$MONGODB_HOME/bin/mongod

#mongodb 配置文件
MONGODB_CONF=$MONGODB_HOME/conf/mongodb.conf

#mongodb PID
MONGODB_PID=/usr/local/mongodb/mongo.pid

#最大文件打开数量限制
SYSTEM_MAXFD=65535

#mongodb 名字  
MONGODB_NAME="mongodb"
. /etc/rc.d/init.d/functions

if [ ! -f $MONGODB_BIN ]
then
        echo "$MONGODB_NAME startup: $MONGODB_BIN not exists! "  
        exit
fi


start(){
         ulimit -HSn $SYSTEM_MAXFD
         $MONGODB_BIN --config="$MONGODB_CONF"  
         ret=$?
         if [ $ret -eq 0 ]; then
            action $"Starting $MONGODB_NAME: " /bin/true
         else
            action $"Starting $MONGODB_NAME: " /bin/false
         fi
      
}

stop(){
        PID=$(ps aux |grep "$MONGODB_NAME" |grep "$MONGODB_CONF" |grep -v grep |wc -l) 
        if [[ $PID -eq 0  ]];then
        action $"Stopping $MONGODB_NAME: " /bin/false
        exit
        fi
        kill -HUP `cat $MONGODB_PID`
        ret=$?
        if [ $ret -eq 0 ]; then
                action $"Stopping $MONGODB_NAME: " /bin/true
                rm -f $MONGODB_PID
        else   
                action $"Stopping $MONGODB_NAME: " /bin/false
        fi

}

restart() {

        stop
        sleep 2
        start
}

case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        status)
        status $prog
                ;;
        restart)
                restart
                ;;
        *)
                echo $"Usage: $0 {start|stop|status|restart}"
esac
EOF
chmod a+x /etc/init.d/mongod
chkconfig --add mongod
chkconfig mongod on
else
print_log "mongodb: 启动脚本已经存在."
fi 

print_log "初始化配置完成."
print_log "数据目录为:$dbpath 日志文件为:$mongodblog"
print_log "配置目录为:/usr/local/mongodb/conf"
print_log "启动脚本为:/etc/init.d/mongod"
print_log "启动mongodb服务:"&&service mongod start
sleep 2
print_log "确认mongodb已启动:"&ps -aux|grep mongod
#做一个mongo热链，方便直接使用mongo
ln /usr/local/mongodb/bin/mongo /usr/bin/mongo

else
        echo "下载失败! 正在重新下载!"
exit
fi

}

Install_Mongodb