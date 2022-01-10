#!/bin/sh
. /usr/bin/softwarecenter/lib_functions.sh

pkglist_nginx="nginx-extras"
pkglist_php7="coreutils-stat coreutils-fold php7 php7-cgi php7-cli php7-fastcgi php7-fpm"
phpmod="php7-mod-calendar php7-mod-ctype php7-mod-curl php7-mod-dom php7-mod-exif php7-mod-fileinfo php7-mod-filter php7-mod-ftp php7-mod-gd php7-mod-gettext php7-mod-gmp php7-mod-iconv php7-mod-intl php7-mod-json php7-mod-ldap php7-mod-mbstring php7-mod-mysqli php7-mod-opcache php7-mod-openssl php7-mod-pcntl php7-mod-pdo php7-mod-pdo-mysql php7-mod-phar php7-mod-session php7-mod-shmop php7-mod-simplexml php7-mod-snmp php7-mod-soap php7-mod-sockets php7-mod-sqlite3 php7-mod-sysvmsg php7-mod-sysvsem php7-mod-sysvshm php7-mod-tokenizer php7-mod-xml php7-mod-xmlreader php7-mod-xmlwriter php7-mod-zip php7-pecl-dio php7-pecl-http php7-pecl-libevent php7-pecl-propro php7-pecl-raphf php7-pecl-redis redis-utils snmp-mibs snmp-utils zoneinfo-core"
dblist="mariadb-client mariadb-client-extra mariadb-server mariadb-server-extra php7-mod-pdo-mysql"

# PHP初始化
init_php() {
	# 安装php
	opkg_install $pkglist_php7 $phpmod
	make_dir /opt/usr/php/session/

	sed -i "{
		/^doc_root/d
		/^memory_limit/ {s|= .*|= 128M|}
		/^post_max_size/ {s|= .*|= 8000M|}
		/^output_buffering/ {s|= .*|= 4096|}
		/^max_execution_time/ {s|= .*|= 2000|}
		/^upload_max_filesize/ {s|= .*|= 8000M|}
	}" /opt/etc/php.ini
	sed -i "/listen.mode/ {s|= .*|= 0666|}" /opt/etc/php7-fpm.d/www.conf

	# PHP配置文件
	cat >>"/opt/etc/php.ini" <<-\PHPINI
		session.save_path = "/opt/usr/php/session/"
		opcache.enable=1
		opcache.enable_cli=1
		opcache.interned_strings_buffer=8
		opcache.max_accelerated_files=10000
		opcache.memory_consumption=128
		opcache.save_comments=1
		opcache.revalidate_freq=60
		opcache.fast_shutdown=1
		mysqli.default_socket=/opt/var/run/mysqld.sock
		pdo_mysql.default_socket=/opt/var/run/mysqld.sock
	PHPINI

	cat >>"/opt/etc/php7-fpm.d/www.conf" <<-\PHPFPM
		env[HOSTNAME] = $HOSTNAME
		env[PATH] = /opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin
		env[TMP] = /opt/tmp
		env[TMPDIR] = /opt/tmp
		env[TEMP] = /opt/tmp
	PHPFPM
	echo_time " PHP 安装完成\n"
}

# 安装nginx
init_nginx() {
	get_env
	echo_time "开始安装 php 环境\n"
	opkg_install "$pkglist_nginx"
	init_php
	make_dir /opt/etc/nginx/vhost /opt/etc/nginx/no_use /opt/etc/nginx/conf

	# 初始化nginx配置文件
	cat >"/opt/etc/nginx/nginx.conf" <<-EOF
		user $username root;
		pid /opt/var/run/nginx.pid;
		worker_processes auto;
		events {
			use epoll;
			multi_accept on;
			worker_connections 1024;
		}
		http {
			charset utf-8;
			include mime.types;
			default_type application/octet-stream;

			sendfile on;
			tcp_nopush on;
			tcp_nodelay on;
			keepalive_timeout 60;

			client_max_body_size 2000m;
			client_body_temp_path /opt/tmp/;

			gzip on;
			gzip_vary on;
			gzip_proxied any;
			gzip_min_length 1k;
			gzip_buffers 4 8k;
			gzip_comp_level 2;
			gzip_disable "msie6";
			gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript image/svg+xml;
			include /opt/etc/nginx/vhost/*.conf;
			include /opt/etc/nginx/conf.d/*.conf;
		}
	EOF

	# 特定程序的nginx配置
	nginx_special_conf

	# 初始化redis
	echo -e "unixsocket /opt/var/run/redis.sock\nunixsocketperm 777" >> /opt/etc/redis.conf
	echo_time " nginx 安装完成\n"
}

# 卸载nginx
del_nginx() {
	nginx_manage stop
	del_php
	remove_soft "$pkglist_nginx"
	rm -rf /opt/etc/nginx
	/usr/bin/find -name "*nginx*" -exec rm -rf {} \;
	rm /opt/etc/redis.conf
}

# 卸载PHP
del_php() {
	remove_soft "$pkglist_php7" "$phpmod"
	rm /opt/etc/php.ini
	/usr/bin/find /opt -name "php*" -exec rm -rf {} \;
}

# Nginx Server管理 参数：$1:动作
nginx_manage() {
	/opt/etc/init.d/S47snmpd $1 >/dev/null 2>&1
	/opt/etc/init.d/S70redis $1 >/dev/null 2>&1
	/opt/etc/init.d/S80nginx $1 >/dev/null 2>&1
	/opt/etc/init.d/S79php7-fpm $1 >/dev/null 2>&1
}

# 特定程序的nginx配置
nginx_special_conf() {
	# php-fpm
	cat >"/opt/etc/nginx/conf/php-fpm.conf" <<-\OOO
		location ~ \.php(?:$|/) {
			fastcgi_split_path_info ^(.+\.php)(/.+)$;
			fastcgi_pass unix:/opt/var/run/php7-fpm.sock;
			fastcgi_index index.php;
			fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
			include fastcgi_params;
		}
	OOO

	# nextcloud
	cat >"/opt/etc/nginx/conf/nextcloud.conf" <<-\OOO
		add_header X-Content-Type-Options nosniff;
		add_header X-XSS-Protection "1; mode=block";
		add_header X-Robots-Tag none;
		add_header X-Download-Options noopen;
		add_header X-Permitted-Cross-Domain-Policies none;
		location = /robots.txt {
			allow all;
			log_not_found off;
			access_log off;
		}
		location = /.well-known/carddav {
			return 301 $scheme://$host/remote.php/dav;
		}
		location = /.well-known/caldav {
			return 301 $scheme://$host/remote.php/dav;
		}
		fastcgi_buffers 64 4K;
		fastcgi_send_timeout 300;
		fastcgi_read_timeout 2400;
		gzip on;
		gzip_vary on;
		gzip_comp_level 4;
		gzip_min_length 256;
		gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
		gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
		location / {
			rewrite ^ /index.php$request_uri;
		}
		location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
			deny all;
		}
		location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
			deny all;
		}
		location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+)\.php(?:$|/) {
			fastcgi_split_path_info ^(.+?\.php)(/.*)$;
			include fastcgi_params;
			fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
			fastcgi_param PATH_INFO $fastcgi_path_info;
			fastcgi_param modHeadersAvailable true;
			fastcgi_param front_controller_active true;
			fastcgi_pass unix:/opt/var/run/php7-fpm.sock;
			fastcgi_intercept_errors on;
			fastcgi_request_buffering off;
		}
		location ~ ^/(?:updater|ocs-provider)(?:$|/) {
			try_files $uri/ =404;
			index index.php;
		}
		location ~ \.(?:css|js|woff|svg|gif)$ {
			try_files $uri /index.php$request_uri;
			add_header Cache-Control "public, max-age=15778463";
			add_header X-Content-Type-Options nosniff;
			add_header X-XSS-Protection "1; mode=block";
			add_header X-Robots-Tag none;
			add_header X-Download-Options noopen;
			add_header X-Permitted-Cross-Domain-Policies none;
			access_log off;
		}
		location ~ \.(?:png|html|ttf|ico|jpg|jpeg)$ {
			try_files $uri /index.php$request_uri;
			access_log off;
		}
	OOO

	# owncloud
	cat >"/opt/etc/nginx/conf/owncloud.conf" <<-\OOO
		add_header X-Content-Type-Options nosniff;
		add_header X-Frame-Options "SAMEORIGIN";
		add_header X-XSS-Protection "1; mode=block";
		add_header X-Robots-Tag none;
		add_header X-Download-Options noopen;
		add_header X-Permitted-Cross-Domain-Policies none;
		location = /robots.txt {
			allow all;
			log_not_found off;
			access_log off;
		}
		location = /.well-known/carddav {
			return 301 $scheme://$host/remote.php/dav;
		}
		location = /.well-known/caldav {
			return 301 $scheme://$host/remote.php/dav;
		}
		gzip off;
		fastcgi_buffers 8 4K;
		fastcgi_send_timeout 300;
		fastcgi_read_timeout 2400;
		fastcgi_ignore_headers X-Accel-Buffering;
		error_page 403 /core/templates/403.php;
		error_page 404 /core/templates/404.php;
		location / {
			rewrite ^ /index.php$uri;
		}
		location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
			return 404;
		}
		location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
			return 404;
		}
		location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\.php(?:$|/) {
			fastcgi_split_path_info ^(.+\.php)(/.*)$;
			include fastcgi_params;
			fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
			fastcgi_param SCRIPT_NAME $fastcgi_script_name;
			fastcgi_param PATH_INFO $fastcgi_path_info;
			fastcgi_param modHeadersAvailable true;
			fastcgi_param front_controller_active true;
			fastcgi_read_timeout 180;
			fastcgi_pass unix:/opt/var/run/php7-fpm.sock;
			fastcgi_intercept_errors on;
			fastcgi_request_buffering on;
		}
		location ~ ^/(?:updater|ocs-provider)(?:$|/) {
			try_files $uri $uri/ =404;
			index index.php;
		}
		location ~ \.(?:css|js)$ {
			try_files $uri /index.php$uri$is_args$args;
			add_header Cache-Control "max-age=15778463";
			add_header X-Content-Type-Options nosniff;
			add_header X-Frame-Options "SAMEORIGIN";
			add_header X-XSS-Protection "1; mode=block";
			add_header X-Robots-Tag none;
			add_header X-Download-Options noopen;
			add_header X-Permitted-Cross-Domain-Policies none;
			access_log off;
		}
		location ~ \.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg|map)$ {
			add_header Cache-Control "public, max-age=7200";
			try_files $uri /index.php$uri$is_args$args;
			access_log off;
		}
	OOO

	# wordpress
	cat >"/opt/etc/nginx/conf/wordpress.conf" <<-\OOO
		location = /favicon.ico {
			log_not_found off;
			access_log off;
		}
		location = /robots.txt {
			allow all;
			log_not_found off;
			access_log off;
		}
		location ~ /\. {
			deny all;
		}
		location ~ ^/wp-content/uploads/.*\.php$ {
			deny all;
		}
		location ~* /(?:uploads|files)/.*\.php$ {
			deny all;
		}
		location / {
			try_files $uri $uri/ /index.php?$args;
		}
		location ~ \.php$ {
			include fastcgi.conf;
			fastcgi_intercept_errors on;
			fastcgi_pass unix:/opt/var/run/php7-fpm.sock;
			fastcgi_buffers 16 16k;
			fastcgi_buffer_size 32k;
		}
		location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
			expires max;
			log_not_found off;
		}
	OOO

	# typecho
	cat >"/opt/etc/nginx/conf/typecho.conf" <<-\OOO
		if (!-e $request_filename) {
				rewrite ^(.*)$ /index.php$1 last;
			}
	OOO

}

# 重置、初始化MySQL #
init_mysql() {
	get_env
	opkg_install "$dblist"
	cat >"/opt/etc/mysql/my.cnf" <<-EOF
		[client-server]
		port               = 3306
		socket             = /opt/var/run/mysqld.sock

		[mysqld]
		user               = $username
		socket             = /opt/var/run/mysqld.sock
		pid-file           = /opt/var/run/mysqld.pid
		basedir            = /opt
		lc_messages_dir    = /opt/share/mariadb
		lc_messages        = en_US
		datadir            = /opt/var/mariadb/
		tmpdir             = /opt/tmp/

		skip-external-locking

		bind-address       = 127.0.0.1

		key_buffer_size    = 24M
		max_allowed_packet = 24M
		thread_stack       = 192K
		thread_cache_size  = 8

		[mysqldump]
		quick
		quote-names
		max_allowed_packet = 24M

		[mysql]
		#no-auto-rehash

		[isamchk]
		key_buffer_size    = 24M

		[mysqlhotcopy]
		interactive-timeout
	EOF

	chmod 644 /opt/etc/mysql/my.cnf
	make_dir /opt/var/mysql

	# 数据库安装，同步方式，无需延时等待
	echo_time "正在初始化数据库，请稍等1分钟"
	mysql_install_db --user=$username --basedir=/opt --datadir=/opt/var/mariadb/ >/dev/null 2>&1

	# 初次启动MySQL，异步方式，加延时等待
	echo_time "正在启动MySQL"
	/opt/etc/init.d/S70mysqld start >/dev/null 2>&1
	sleep 10

	# 设置数据库密码
	if [ $user ] && [ $pass ]; then
		echo_time "使用自定义数据库用户：$user 密码：$pass"
	else
		user="root"
		pass="123456"
		echo_time "使用自定义数据库用户：$user 密码：$pass"
	fi
	mysqladmin -u $user password $pass
	echo_time " MySQL 安装完成\n"
}

del_mysql() {
	# 停止MySQL
	/opt/etc/init.d/S70mysqld stop >/dev/null 2>&1
	echo_time "正在停止MySQL"
	sleep 10

	# 卸载相关的软件包，文件与目录
	remove_soft "`opkg list-installed | awk '/mariadb/{print $1}' | xargs echo`"
	rm -rf /opt/etc/mysql /opt/var/mariadb/ /opt/var/mysql
}
