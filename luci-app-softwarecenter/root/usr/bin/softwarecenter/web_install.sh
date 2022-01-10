#!/bin/sh
. /usr/bin/softwarecenter/lib_functions.sh

# Web程序
# (0) tz（雅黑PHP探针）
url_tz="https://codeload.github.com/WuSiYu/PHP-Probe/zip/master"
# (1) phpMyAdmin（数据库管理工具）
url_phpMyAdmin="https://files.phpmyadmin.net/phpMyAdmin/5.1.1/phpMyAdmin-5.1.1-all-languages.zip"
# (2) WordPress（使用最广泛的CMS）
url_WordPress="https://cn.wordpress.org/latest-zh_CN.zip"
# (3) Owncloud（经典的私有云）
url_Owncloud="https://download.owncloud.org/community/owncloud-complete-20210721.zip"
# (4) Nextcloud（Owncloud团队的新作，美观强大的个人云盘）
url_Nextcloud="https://download.nextcloud.com/server/releases/nextcloud-22.2.3.zip"
# (5) h5ai（优秀的文件目录）
url_h5ai="https://release.larsjung.de/h5ai/h5ai-0.30.0.zip"
# (6) Lychee（一个很好看，易于使用的Web相册）
url_Lychee="https://github.com/electerious/Lychee/archive/master.zip"
# (7) Kodexplorer（可道云aka芒果云在线文档管理器）
url_Kodexplorer="https://static.kodcloud.com/update/download/kodbox.1.26.zip"
# (8) Typecho (流畅的轻量级开源博客程序)
url_Typecho="http://typecho.org/downloads/1.1-17.10.30-release.tar.gz"
# (9) Z-Blog (体积小，速度快的PHP博客程序)
url_Zblog="https://update.zblogcn.com/zip/Z-BlogPHP_1_7_0_2950_Tenet.zip"
# (10) DzzOffice (开源办公平台)
url_DzzOffice="https://codeload.github.com/zyx0814/dzzoffice/zip/master"

# 网站程序安装 参数： $1:安装目标 $2:端口号
install_website() {
	# 通用环境变量获取
	get_env
	unset filelink name dirname port hookdir istar
	[ $2 ] && port=$2

	case $1 in
		0)	install_tz ;;
		1)	install_phpmyadmin ;;
		2)	install_wordpress ;;
		3)	install_owncloud ;;
		4)	install_nextcloud ;;
		5)	install_h5ai ;;
		6)	install_lychee ;;
		7)	install_kodexplorer ;;
		8)	install_typecho ;;
		9)	install_zblog ;;
		10)	install_dzzoffice ;;
		*)break ;;
	esac
}

# WEB程序安装器
web_installer() {
	echo -e "\n================================================"
	echo -e "***********************    WEB程序安装器    ***********************"
	echo -e "================================================\n"

	# 获取用户自定义设置
	suffix="zip"
	[ $istar ] && suffix="tar"
	echo_time "开始安装 $name"
	[ -d "/opt/wwwroot/$name" ] && rm -rf /opt/wwwroot/$name /opt/tmp/$name.$suffix /opt/tmp/$name.$suffix \
	/opt/etc/nginx/vhost/$name.conf && echo_time "已删除以前的 $name 文件"

	# 下载程序并解压
	echo_time "正在下载安装包 $name.$suffix 请耐心等待..."
	wget -qO /opt/tmp/$name.$suffix $filelink --show-progress && {
		make_dir /opt/wwwroot/$hookdir
		mv /opt/tmp/$name.* /opt/wwwroot/

		echo_time "正在解压 $name.$suffix..."
		if [ $istar ]; then
			tar -xzf /opt/wwwroot/$name.$suffix -C /opt/wwwroot/$hookdir
		else
			unzip -oq /opt/wwwroot/$name.$suffix -d /opt/wwwroot/$hookdir
		fi
		mv /opt/wwwroot/$dirname /opt/wwwroot/$name

		ls -A /opt/wwwroot/$name >/dev/null 2>&1 && {
			echo_time "$name.$suffix 解压完成..."
			chmod -R 777 /opt/wwwroot/$name
			echo_time "正在配置 $name..."
			port_settings
		} || {
			echo_time "$name 安装失败，回滚操作"
			rm /opt/wwwroot/$name*
		}
	} || {
		echo_time "$name下载失败，检查网络。"
		rm /opt/tmp/$name.$suffix
		exit 1
	}
}

# 网站名称映射 参数；$1:网站选项
website_name_mapping() {
	case $1 in
		0) echo "tz" ;;
		1) echo "phpMyAdmin" ;;
		2) echo "WordPress" ;;
		3) echo "Owncloud" ;;
		4) echo "Nextcloud" ;;
		5) echo "h5ai" ;;
		6) echo "Lychee" ;;
		7) echo "Kodexplorer" ;;
		8) echo "Typecho" ;;
		9) echo "Zblog" ;;
		10) echo "DzzOffice" ;;
		*)break ;;
	esac
}

# 写入nginx配置文件
add_vhost() {
	[ "$website_enabled" ] && uu="vhost" || uu="no_use"
	cat >"/opt/etc/nginx/$uu/$2.conf"<<-EOF
		server {
			listen $1;
			server_name localhost;
			root /opt/wwwroot/$2;
			index index.html index.htm index.php;
			#php-fpm
			#otherconf
		}
	EOF
}

port_settings() {

	find_port() {
	for f in `seq 2100 2120`; do
		/opt/bin/lsof -i:$f >/dev/null 2>&1 || {
			port=$f
			break
		}
	done
	}

	if [ -n "$port" ]; then
		/opt/bin/lsof -i:$port >/dev/null 2>&1 && {
			echo_time "$name 设置的端口 $port 已在用，查找可用端口。"
			find_port
			echo_time "$name 使用空闲 $port 的端口"
		} || {
			port=$port
			echo_time "$name 使用自定义 $port 的端口"
		}
	else
		echo_time "$name 没有设置端口，查找可用端口。"
		find_port
		echo_time "$name 使用空闲 $port 的端口"
	fi
}

# 恢复网站查端口
port_custom() {
	port=`awk '/listen/{print $2}' $1 | sed 's/;//'`
	port_settings
	sed -i "s|listen .*|listen $port;|" $1
	echo_time " $website_name 已启用\n"
}

# 端口修改
port_modification() {
	local name=$website_name
	for kj in $@; do
		local pu=$(awk '/listen/{print $2}' $kj | sed 's/;//')
		if [ $port ]; then
			if [ $pu -ne $port ]; then
				port_settings
				sed -i "s|listen.*|listen $port;|" $kj
				echo_time "$name 端口修改完成\n"
			fi
		else
			if [ $pu -lt 2100 -o $pu -gt 2120 ]; then
				port_settings
				sed -i "s|listen.*|listen $port;|" $kj
				echo_time "$name 端口修改完成\n"
			fi
		fi
	done
}

# 网站删除 参数：$1:conf文件位置 $2:website_dir 说明：本函数仅删除配置文件和目录，并不负责重载Nginx服务器配置，请调用层负责处理
delete_website() {
	rm -rf $1 $2* && \
	echo_time "========== ${2##*/} 已删除 =========="
	/opt/etc/init.d/S80nginx reload > /dev/null 2>&1
}

# 网站配置文件基本属性列表 参数：$1:配置文件位置 说明：本函是将负责解析nginx的配置文件，输出网站文件目录和访问地址,仅接受一个参数
vhost_config_list() {
	get_env
	if [ "$#" -eq "1" ]; then
		path=`awk -F/ '/wwwroo/{print $NF}' $1 | sed 's/;//'`
		port=`awk '/listen/{print $2}' $1 | sed 's/;//'`
		echo -e "$path $localhost:$port"
	fi
}

# 网站一览 说明：显示已经配置注册的网站
vhost_list() {
	echo_time "已运行的网站列表："
	for conf in /opt/etc/nginx/vhost/*; do
		vhost_config_list $conf
	done
}

# 开启 Redis 参数: $1: 安装目录
redis() {
	cp $1/config/config.php $1/config/config.php.bak
	sed -i "/);/d" $1/config/config.php
	cat >>"$1/config/config.php" <<-\EOF
		'memcache.locking' => '\OC\Memcache\Redis',
		'memcache.local' => '\OC\Memcache\Redis',
		'redis' => array(
			'host' => '/opt/var/run/redis.sock',
			'port' => 0,
			),
		);
	EOF
	echo_time "$name已开启Redis"
}

website_config_list=""
#本函数负责清理未写入配置的网站
clean_vhost_config() {
	local_config_list="$(ls /opt/etc/nginx/vhost | sed 's/.conf//')"
	local_no_use_config_list="$(ls /opt/etc/nginx/no_use | sed 's/.conf//')"
	delete_config_list=""

	# 获取要删除的网站
	for i in $local_config_list; do
		flag=""
		for j in $website_config_list; do
			if [ "$i" == "$j" ]; then
				flag="1"
				break
			fi
		done
		if [ -z $flag ]; then
			delete_config_list="$delete_config_list /opt/etc/nginx/vhost/$i.conf"
		fi
	done
	for i in $local_no_use_config_list; do
		flag=""
		for j in $website_config_list; do
			if [ "$i" == "$j" ]; then
				flag="1"
				break
			fi
		done
		if [ -z $flag ]; then
			delete_config_list="$delete_config_list /opt/etc/nginx/no_use/$i.conf"
		fi
	done

	for conf in $delete_config_list; do
		webdir=$(vhost_config_list $conf | awk '{print $1}')
		delete_website $conf $webdir
	done
}

# 网站迭代处理，本函数迭代的配置网站（处理逻辑也许可以更好的优化？）
handle_website() {
	website_config="autodeploy_enable customdeploy_enabled port redis_enabled website_dir website_enabled website_select"
	for pl in $website_config; do
		config_get_bool $pl $1 $pl
		config_get $pl $1 $pl
	done

	if [ "$autodeploy_enable" ]; then
		local website_name=$(website_name_mapping $website_select) # 获取网站名称
		if [ ! -f /opt/etc/*/*/$website_name.conf ]; then
			install_website $website_select $port
			if [ "$website_enabled" ]; then
				echo_time " $name 安装完成"
				echo_time "浏览器地址栏输入：$localhost:$port 即可访问\n"
			else
				echo_time " $name 安装完成，但没有开启！\n"
			fi
		fi
	else
		return 1
	fi

	if [ "$website_enabled" ]; then
		if [ -f /opt/etc/nginx/no_use/$website_name.conf ]; then
			echo_time "启用 $website_name "
			mv /opt/etc/nginx/no_use/$website_name.conf /opt/etc/nginx/vhost/$website_name.conf
			port_custom "/opt/etc/nginx/vhost/$website_name.conf"
		fi

		if [ "$autodeploy_enable" ] && [ "$website_name" = "Nextcloud" ] || [ "$website_name" = "Owncloud" ]; then
			if [ "$redis_enabled" ]; then
				if [ -d /opt/wwwroot/$website_name ] && [ ! -f /opt/wwwroot/$website_name/redis_enabled ]; then
					touch /opt/wwwroot/$website_name/redis_enabled
					redis "/opt/wwwroot/$website_name"
				fi
			else
				rm -rf /opt/wwwroot/$website_name/config/config.php
				rm -rf /opt/wwwroot/$website_name/redis_enabled
			fi
		fi
		port_modification "/opt/etc/nginx/vhost/$website_name.conf"
		/opt/etc/init.d/S80nginx reload >/dev/null 2>&1
	else
		if [ -f /opt/etc/nginx/vhost/$website_name.conf ]; then
			mv /opt/etc/nginx/vhost/$website_name.conf /opt/etc/nginx/no_use/$website_name.conf
			/opt/etc/init.d/S80nginx reload >/dev/null 2>&1 && \
			echo_time " 已关闭 $website_name\n"
		fi
	fi
	website_config_list="$website_config_list $website_name"
}

install_tz() {
	# 默认配置
	filelink=$url_tz
	name="tz"
	dirname="PHP-Probe-master"

	# 运行安装程序
	web_installer
	add_vhost $port $name
	sed -i "{
	s|index.php;|index.php tz.php;|
	s|#php-fpm|include /opt/etc/nginx/conf/php-fpm.conf;|
	}" /opt/etc/nginx/*/$name.conf
}

# 安装phpMyAdmin
install_phpmyadmin() {
	# 默认配置
	filelink=$url_phpMyAdmin
	name="phpMyAdmin"
	dirname="phpMyAdmin-*-languages"
	web_installer
	cp /opt/wwwroot/$name/config.sample.inc.php /opt/wwwroot/$name/config.inc.php
	chmod 644 /opt/wwwroot/$name/config.inc.php
	# 取消-p参数，必须要求webdir创建才可创建文件夹，为部署检测做准备
	make_dir /opt/wwwroot/$name/tmp
	sed -i "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = 'softwarecentersoftwarecentersoftwarecenter';/g" /opt/wwwroot/$name/config.inc.php
	add_vhost $port $name
	sed -i "s|#php-fpm|include /opt/etc/nginx/conf/php-fpm.conf;|" /opt/etc/nginx/*/$name.conf
	echo_time "phpMyaAdmin的用户、密码就是数据库用户：$user 密码：$pass"
}

# 安装WordPress
install_wordpress() {
	# 默认配置
	filelink=$url_WordPress
	name="WordPress"
	dirname="wordpress"
	web_installer
	add_vhost $port $name
	# WordPress的配置文件中有php-fpm了, 不需要外部引入
	sed -i "s|#otherconf|include /opt/etc/nginx/conf/wordpress.conf;|" /opt/etc/nginx/*/$name.conf
	echo_time "可以用phpMyaAdmin建立数据库，然后在这个站点上一步步配置网站信息"
}

# 安装h5ai
install_h5ai() {
	# 默认配置
	filelink=$url_h5ai
	name="h5ai"
	dirname="_h5ai"
	hookdir=$dirname

	# 运行安装程序
	web_installer
	cp /opt/wwwroot/$name/_h5ai/README.md /opt/wwwroot/$name/

	# 添加到虚拟主机
	add_vhost $port $name
	sed -i "{
		s|#php-fpm|include /opt/etc/nginx/conf/php-fpm.conf;|
		s|index .*|index index.html index.php /_h5ai/public/index.php;|
	}" /opt/etc/nginx/*/$name.conf
	sed -i '{
		/show/ {s|false|true|}
		s|googleapis.com|loli.net|
		/enabled/ {s|false|true|g}
		/lang/ {s|: ".*"|: "zh-cn"|}
		/alwaysVisible/ {s|false|true|}
	}' /opt/wwwroot/h5ai/_h5ai/private/conf/options.json
	ln -s $download_dir /opt/wwwroot/h5ai
	ln -s /opt/etc/config /opt/wwwroot/h5ai
	echo_time "配置文件在/opt/wwwroot/$name/_h5ai/private/conf/options.json"
	echo_time "你可以通过修改它来获取更多功能"
	}

# 安装Lychee
install_lychee() {
	# 默认配置
	filelink=$url_Lychee
	name="Lychee"
	dirname="Lychee-master"
	web_installer
	add_vhost $port $name
	sed -i "s|#php-fpm|include /opt/etc/nginx/conf/php-fpm.conf;|" /opt/etc/nginx/*/$name.conf
	echo_time "首次打开会要配置数据库信息"
	echo_time "地址：127.0.0.1 用户、密码就是数据库用户：$user 密码：$pass"
	echo_time "下面的可以不配置，然后下一步创建个用户就可以用了"
}

# 安装kodexplorer芒果云
install_kodexplorer() {
	# 默认配置
	filelink=$url_Kodexplorer
	name="Kodexplorer"
	dirname="kodexplorer"
	hookdir=$dirname
	web_installer
	add_vhost $port $name
	sed -i "s|#php-fpm|include /opt/etc/nginx/conf/php-fpm.conf;|" /opt/etc/nginx/*/$name.conf
}

# 安装 Typecho
install_typecho() {
	# 默认配置
	filelink=$url_Typecho
	name="Typecho"
	dirname="build"
	istar=true
	web_installer
	add_vhost $port $name
	sed -i "{
		s|#php-fpm|include /opt/etc/nginx/conf/php-fpm.conf;|
		s|#otherconf|include /opt/etc/nginx/conf/typecho.conf;|
	}" /opt/etc/nginx/*/$name.conf
	echo_time "可以用phpMyaAdmin建立数据库，然后在这个站点上一步步配置网站信息"
}

# 安装Z-Blog
install_zblog() {
	# 默认配置
	filelink=$url_Zblog
	name="Zblog"
	dirname="Z-BlogPHP_1_5_1_1740_Zero"
	hookdir=$dirname
	web_installer
	add_vhost $port $name
	sed -i "s|#php-fpm|include /opt/etc/nginx/conf/php-fpm.conf;|" /opt/etc/nginx/*/$name.conf
}

# 安装DzzOffice
install_dzzoffice() {
	# 默认配置
	filelink=$url_DzzOffice
	name="DzzOffice"
	dirname="dzzoffice-master"
	web_installer
	add_vhost $port $name
	sed -i "s|#php-fpm|include /opt/etc/nginx/conf/php-fpm.conf;|" /opt/etc/nginx/*/$name.conf # 添加php-fpm支持
	echo_time "DzzOffice应用市场中，某些应用无法自动安装的，请自行参看官网给的手动安装教程"
}

# 安装Owncloud
install_owncloud() {
	# 默认配置
	filelink=$url_Owncloud
	name="Owncloud"
	dirname="owncloud"
	web_installer
	add_vhost $port $name
	# Owncloud的配置文件中有php-fpm了, 不需要外部引入
	sed -i "s|#otherconf|include /opt/etc/nginx/conf/owncloud.conf;|" /opt/etc/nginx/*/$name.conf
	echo_time "首次打开会要配置用户和数据库信息"
	echo_time "地址默认 $localhost 用户、密码就是数据库用户：$user 密码：$pass"
	echo_time "安装好之后可以点击左上角三条杠进入market安装丰富的插件，比如在线预览图片、视频等"
	echo_time "需要先在web界面配置完成后，才能使用开启Redis"
}

# 安装Nextcloud
install_nextcloud() {
	# 默认配置
	filelink=$url_Nextcloud
	name="Nextcloud"
	dirname="nextcloud"
	web_installer
	add_vhost $port $name
	# nextcloud的配置文件中有php-fpm了, 不需要外部引入
	sed -i "s|#otherconf|include /opt/etc/nginx/conf/nextcloud.conf;|" /opt/etc/nginx/*/$name.conf
	echo_time "首次打开会要配置用户和数据库信息"
	echo_time "地址默认 $localhost 用户、密码就是数据库用户：$user 密码：$pass"
	echo_time "需要先在 web 界面配置完成后，才能使用开启Redis"
}

# 网站程序卸载（by自动化接口安装）参数；$1:删除的目标
delete_website_byauto() {
	name=`website_name_mapping $1`
	delete_website /opt/etc/nginx/vhost/$name.conf /opt/wwwroot/$name
}

# 自定义部署通用函数 参数：$1:文件目录 $2:端口号
install_custom() {
	webdir=$1
	port_settings
	# 运行安装程序
	echo_time "正在配置$webdir..."

	# 目录检查
	if [ ! -d /opt/wwwroot/$webdir ]; then
		echo_time "目录不存在，部署中断"
		exit 1
	fi
	chmod -R 777 /opt/wwwroot/$webdir

	# 添加到虚拟主机
	add_vhost $port $webdir
	sed -i "s|#php-fpm|include /opt/etc/nginx/conf/php-fpm.conf;|" /opt/etc/nginx/vhost/$webdir.conf
	echo_time "$webdir 安装完成"
}
