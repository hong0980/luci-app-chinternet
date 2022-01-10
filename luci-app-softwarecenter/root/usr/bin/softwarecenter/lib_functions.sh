#!/bin/sh
export PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
webui_name=$(uci get softwarecenter.main.webui_name)
webui_pass=$(uci get softwarecenter.main.webui_pass)
download_dir=$(uci get softwarecenter.main.download_dir)

status() {
	local pf=$?
	# echo -en "\\033[40G[ "
	if [ "$pf" = "0" ]; then
		# echo -e "\\033[1;33m成功\\033[0;39m ]"
		echo "   成功"
		return 0
	else
		# echo -e "\\033[1;31m失败\\033[0;39m ]"
		echo "   失败"
		return 1
	fi
}

make_dir() {
	for p in "$@"; do
		[ -d "$p" ] || mkdir -m 777 -p $p
	done
	return 0
}

_pidof() {
	for g in $@; do
		ps | grep $g | grep -q opt && {
			echo_time "$g 已经运行\n"
			return 0
		} || {
			echo_time "$g 没有运行"
			return 1
		}
	done
}

network() {
    #超时时间
    local timeout=1
    #目标网站
    local target=bin.entware.net
    #获取响应状态码
    local ret_code=`curl -I -s --connect-timeout ${timeout} ${target} -w %{http_code} | tail -n1`
    if [ "x$ret_code" != "x200" ]; then
        echo_time "${target} 网络不畅通"
		[ -e /tmp/ping ] && rm /tmp/ping
        return 1
    else
		[ -e /tmp/ping ] || echo_time "${target} 网络平均响应时间 `ping -c 3 ${target} | awk -F/ '/avg/{print $4}' | tee /tmp/ping`毫秒"
		# echo_time "${target} 网络平均响应时间 `ping -c 3 ${target} | awk -F/ '/avg/{print $4}'`毫秒"
        return 0
    fi
}

echo_time() {
	echo -e "[ $(date +"%m月%d日 %H:%M:%S") ]  $@" | sed '/\\\033/d'
}

# entware环境设定 参数：$1:安装位置 $2:设备底层架构 说明：此函数用于写入新配置
entware_set() {
	entware_unset
	[ "$1" ] && disk_mount="$1" || { echo_time "未选择安装路径！" && exit 1; }
	[ "$2" ] && PLATFORM="$2" || { echo_time "未选择CPU架构！" && exit 1; }
	system_check $disk_mount
	make_dir $disk_mount/opt /opt
	mount -o bind $disk_mount/opt /opt

	case $PLATFORM in
		x86_64)
			arch=x64-k3.2
			;;
		x86)
			arch=x86-k2.6
			;;
		armv5)
			arch=armv5sf-k3.2
			;;
		mipsel)
			arch=mipselsf-k3.4
			;;
		mips)
			arch=mipssf-k3.4
			;;
		aarch64)
			arch=aarch64-k3.10
			;;
		armv7)
			arch=armv7sf-k3.2
			;;
	esac

	if [ $arch ]; then
		network && {
			echo_time "开始安装 Entware"
			wget -t5 -qcNO - bin.entware.net/$arch/installer/generic.sh | /bin/sh >/dev/null 2>&1 || {
				echo_time "安装 Entware 出错，请重试！"
				exit 1
			}
		}
	else
		echo_time "抱歉，不支持您的设备！"
		exit 1
	fi

	cat >"/etc/init.d/entware" <<-\ENTWARE
		#!/bin/sh /etc/rc.common
		START=51

		get_entware_path() {
			for mount_point in `mount | awk '/mnt/{print $3}'`; do
				if [ -e "$mount_point/opt/etc/init.d/rc.unslung" ]; then
					echo "$mount_point"
					break
				fi
			done
		}

		start() {
			[ -d opt ] || mkdir -p /opt
			entware_path=`get_entware_path`
			[ $entware_path ] || entware_path=`uci get softwarecenter.main.disk_mount`
			mount -o bind $entware_path/opt /opt
		}

		stop() {
			/opt/etc/init.d/rc.unslung stop
			umount -lf /opt
			rm -r /opt
		}

		restart() {
			stop
			start
		}
	ENTWARE

	chmod +x /etc/init.d/entware
	/etc/init.d/entware enable
	sed -i 's|PATH="/|PATH="/opt/bin:/opt/sbin:/|' /etc/profile

	wget -qcNO- -t5 bin.entware.net/other/i18n_glib231.tar.gz | tar xz -C /opt/share/ && {
		/opt/bin/localedef.new -c -f UTF-8 -i zh_CN zh_CN.UTF-8
		sed -i 's/en_US.UTF-8/zh_CN.UTF-8/g' /opt/etc/profile
		ln -sf /opt/share/zoneinfo/Asia/Shanghai /opt/etc/localtime
	}
	sed -i '/^ansi/d' /opt/etc/init.d/rc.func
	echo_time "Entware 安装成功！\n"
}

# entware环境解除 说明：此函数用于删除OPKG配置设定
entware_unset() {
	/etc/init.d/entware stop >/dev/null 2>&1
	/etc/init.d/entware disable >/dev/null 2>&1
	rm /etc/init.d/entware
	sed -i "s|/opt/bin:/opt/sbin:||" /etc/profile
	source /etc/profile >/dev/null 2>&1
	umount -lf /opt
	rm -rf /opt
}

# 磁盘分区挂载
system_check() {
	partition_disk="$1"
	grep -q $partition_disk /proc/mounts && {
		filesystem="$(grep $partition_disk /proc/mounts | awk '{print $3}')"
		lo=`lsblk | grep $partition_disk | awk '{print $4}' | sed 's/G//'`
		if [ "$filesystem" = "ext4" ]; then
			[[ "${lo%%.*}" -gt 2 ]] && {
				echo_time "磁盘 $1 符合安装要求"
			} || {
				echo_time "磁盘 $1 小于2G"
				exit 1
			}
		else
			echo_time "磁盘 $partition_disk 原是 $filesystem 重新格式化ext4。"
			umount -l "$partition_disk"
			echo y | mkfs.ext4 ${partition_disk/mnt/dev}
			mount ${partition_disk/mnt/dev} "$partition_disk"
		fi
	} || {
		partition_disk=`uci get softwarecenter.main.partition_disk`
		echo_time "磁盘$partition_disk没有分区，进行分区并格式化ext4。"
		parted -s "$partition_disk" mklabel msdos
		parted -s "$partition_disk" mklabel gpt \
		mkpart primary ext4 512s 100%
		sync
		sleep 2
		echo y | mkfs.ext4 "$partition_disk"1
		make_dir ${partition_disk/dev/mnt}1
		mount "$partition_disk"1 ${partition_disk/dev/mnt}1
	}
}

# 配置交换分区文件 参数: $1:交换分区挂载点 $2:交换空间大小(M)
config_swap_init() {
	[ "x$2" = "x" ] && swap_path=/opt || swap_path=$2
	grep -q "$swap_path/.swap" /proc/swaps || {
		[ -e "$swap_path/.swap" ] || {
			echo_time "正在生成swap文件，请耐心等待..."
			dd if=/dev/zero of=$swap_path/.swap bs=1M count=$1 >/dev/null 2>&1
			mkswap $swap_path/.swap
			chmod 0600 $swap_path/.swap
		}
		# 启用交换分区
		swapon $swap_path/.swap && \
		echo_time "$swap_path/.swap 交换分区已启用\n"
	}
}

# 删除交换分区文件 参数: $1:交换分区挂载点
config_swap_del() {
	[ "x$1" = "x" ] && swap_path=/opt
	[ -e $swap_path/.swap ] && {
		swapoff $swap_path/.swap
		rm -f $swap_path/.swap
		echo_time "$swap_path/.swap 交换分区已删除！\n"
	}
}

# 获取通用环境变量
get_env() {
	# 获取用户名
	[ "$USER" ] && username=$USER || username=$(awk -F: 'NR==1{print $1}' /etc/passwd)

	# 获取路由器IP
	localhost=$(ifconfig | awk '/inet addr/{print $2}' | awk -F: 'NR==1{print $2}')
	[ "$localhost" ] || localhost="你的路由器IP"
}

# 容量验证 参数：$1：目标位置
check_available_size() {
	available_size="$(lsblk -s | grep $1 | awk '{print $4}')"
	[ $available_size ] && echo "$available_size"
}

# 软件包卸载 参数: $1:卸载列表 说明：本函数将负责强制卸载指定的软件包
remove_soft() {
	for ipk in $@; do
		echo_time "正在卸载 ${ipk}\c"
		opkg remove --force-depends $ipk >/dev/null 2>&1
		status
	done
}

# 软件包安装 参数: $@:安装列表
install_soft() {
	network && {
		opkg update >/dev/null 2>&1
		for ipk in $@; do
			which $ipk >/dev/null 2>&1 && {
				echo_time "$ipk	已经安装 $(which $ipk)"
			} || {
				echo_time "正在安装  $ipk\c"
				opkg install $ipk >/dev/null 2>&1
				status || {
					echo_time "强制安装  $ipk\c"
					opkg install $ipk --force-depends --force-overwrite >/dev/null 2>&1
					status
				}
			}
		done
	} || exit 1
}

# 应用安装 参数: $@:安装列表
opkg_install() {
	network && {
		# opkg update 2>/dev/null | xargs echo 2>/dev/null | grep -q "bin.entware.net" || {
			# echo_time "更新软件源中"
			# source /etc/profile >/dev/null 2>&1 && \
			# opkg update >/dev/null 2>&1
		# }
		opkg update >/dev/null 2>&1

		for ipk in $@; do
			if [ "$(opkg list 2>/dev/null | awk '{print $1}' | grep -w $ipk)" ]; then
				which $ipk | grep -q opt && {
					echo_time "$ipk	已经安装 $(which $ipk | grep -q opt)"
				} || {
					echo_time "正在安装  $ipk\c"
					opkg install $ipk >/dev/null 2>&1
					status
				}
			else
				echo_time "$ipk 不在 Entware 软件源，跳过安装！"
			fi
		done
	} || exit 1
	make_dir /opt/etc/config $download_dir
}

if [ $1 ]; then
	pd=$(mount | awk '/mnt/{print $3}')
	case $1 in
		web_list)
			get_env
			if [ $2 ]; then
				for conf in /opt/etc/nginx/vhost/*; do
					name=`awk -F/ '/wwwroo/{print $NF}' $conf | sed 's/;//'`
					port=`awk '/listen/{print $2}' $conf | sed 's/;//'`
					echo -n "$name $localhost:$port "
				done
			else
				echo -n `ls /opt/etc/nginx/vhost 2>/dev/null | wc -l`
			fi
			;;
		disk_list)
			for mounted in $pd; do
				echo $mounted
			done
			;;
		disk_system)
			i=1
			for mounted in $pd; do
				for m in $(seq 6); do
					eval value$m=$(df -h | grep $mounted | awk 'NR==1{print $(eval echo '$m')}')
					eval pp$m=$(mount | grep $mounted | awk 'NR==1{print $5}')
				done
				echo "$i) $value6 [ $value1 总容量:$value2 ($pp5) 可用:$value4 已用:$value3($value5) ]<br>"
				i=$((i + 1))
			done
			;;
		*) break ;;
	esac
fi
