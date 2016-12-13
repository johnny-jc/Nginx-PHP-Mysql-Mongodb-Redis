#!/bin/bash
logdir=/tmp/log/shell          #日志路径
log=$logdir/shell.log            #日志文件 
is_font=1                #终端是否打印日志: 1打印 0不打印 
is_log=0                 #是否记录日志: 1记录 0不记录

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

echo "################ 开 始 安 装 #####################"
echo "##################################################"
echo "添加所需支持.................."
echo "##################################################"
yum install gcc gcc-c++ -y

#redis version
Redis_Ver='redis-3.2.4'

#redis path  文件路径
cur_dir=$(pwd)

#download 下载、解压
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

#tar 解压
Tar_Cd()
{
	local FileName=$1
	local DirName=$2
	cd $(cur_dir)/src
	[[ -d "$(DirName)" ]] && rm -rf $(DirName)
		echo "Uncompress ${FileName}..."
	tar xf ${FileName}
		echo "cd ${FileName}..."
	cd ${DirName}
}

cd ${cur_dir}
echo "##################################################"
echo "下载redis版本..."
echo "##################################################"
Download_Files http://download.redis.io/releases/${Redis_Ver}.tar.gz ${Redis_Ver}.tar.gz
Tar_Cd ${Redis_Ver}.tar.gz ${Redis_Ver}

#install  安装
echo "##################################################"
echo "开始安装..."
echo "##################################################"
make PREFIX=/usr/local/redis install

#copy redis.conf redis  拷贝配置文件、服务执行文件
echo "##################################################"
echo "创建配置文件目录..."
echo "##################################################"
mkdir -p /usr/local/redis/etc/
mkdir -p /usr/local/redis/db/

\cp redis.conf /usr/local/redis/etc/
echo "修改/usr/local/redis/etc/redis.conf配置文件"
sed -i 's/daemonize no/daemonize yes/g' /usr/local/redis/etc/redis.conf
sed -i 's/pidfile \/var\/run\/redis_6379.pid/pidfile \/var\/run\/redis.pid/g' /usr/local/redis/etc/redis.conf
sed -i 's/# requirepass foobared/requirepass 123456/g' /usr/local/redis/etc/redis.conf
sed -i 's/bind 127.0.0.1/#bind 127.0.0.1/g' /usr/local/redis/etc/redis.conf
sed -i 's/dir .\//dir \/usr\/local\/redis\/db/g' /usr/local/redis/etc/redis.conf
echo "##################################################"
echo "添加redis启动文件..."
echo "##################################################"
cat >/etc/init.d/redis<<'EOF'
#chkconfig:2345 10 90
#description:start and stop redis

PATH=/usr/local/bin:/sbin:/usr/bin:/bin

PORT=6379
EXEC=/usr/local/redis/bin/redis-server
REDIS_CLI=/usr/local/redis/bin/redis-cli
AUTH_PASSWD=123456

PIDFILE=/var/run/redis.pid
CONF="/usr/local/redis/etc/redis.conf"

case "$1" in
        start)
                if [ -f $PIDFILE ];then
                        echo "$PIDFILE exists,process is already running or crashed."
                else
                        echo "Starting Redis server..."
                        $EXEC $CONF
                        if [ "$?"="0" ];then
                                echo "Redis is running..."
                        else
                                echo "Redis start failed."
                        fi
                fi
                ;;
        stop)
                if [ ! -f $PIDFILE ];then
                        echo "$PIDFILE exists,process is not running."
                else
                        PID=$(cat $PIDFILE)
                        echo "Stopping..."
                        $REDIS_CLI -p $PORT -a $AUTH_PASSWD SHUTDOWN
                        while [ -x $PIDFILE ]
                        do
                                echo "Waiting for Redis to shutdown..."
                                sleep 1
                        done
                        echo "Redis stopped"
                fi
                ;;
        restart|force-reload)
                ${0} stop
                ${0} start
                ;;
        *)
                echo "Usage:/etc/init.d/redis {start|stop|restart|force-reload}">&2
                exit 1
                ;;
esac
EOF
echo "##################################################"
echo "添加redis启动文件执行权限..."
echo "##################################################"
chmod +x /etc/init.d/redis

#start redis
echo "##################################################"
echo "添加启动项，并启动redis..."
echo "##################################################"
echo "添加到启动项..."
chkconfig --add redis&&chkconfig redis on
service redis start
print_log "初始化配置完成."
print_log "redis默认开启远程访问，默认密码：123456"
print_log "默认db存放位置:/usr/local/redis/db"
print_log "默认配置文件位置:/usr/loca/redis/etc/redis.conf"
print_log "确认redis已启动:"&ps -aux|grep redis
