FROM php:7.0-apache

# https://dev.1c-bitrix.ru/learning/course/?COURSE_ID=43&LESSON_ID=2943
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		busybox-static \
		msmtp \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	mkdir -p /var/spool/cron/crontabs; \
	echo '*/1 * * * * php -f /var/www/html/bitrix/modules/main/tools/cron_events.php' > /var/spool/cron/crontabs/www-data

# https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&LESSON_ID=3183
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libcurl4-openssl-dev \
		libfreetype6-dev \
		libjpeg-dev \
		libmagickwand-dev \
		libpng-dev \
		libwebp-dev \
		libxml2-dev \
		libzip-dev \
	; \
	\
	mkdir -p /usr/src/php/ext/igbinary; \
	curl -fsSL https://github.com/igbinary/igbinary/archive/3.1.6.tar.gz | tar xvz -C /usr/src/php/ext/igbinary --strip 1; \
	cp -r /usr/src/php/ext/igbinary /usr/local/include/php/ext; \
	\
	# https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=43&LESSON_ID=2795
	mkdir -p /usr/src/php/ext/redis; \
	curl -fsSL https://github.com/phpredis/phpredis/archive/5.3.1.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1; \
	docker-php-ext-configure redis --enable-redis-igbinary; \
	\
	mkdir -p /usr/src/php/ext/imagick; \
	curl -fsSL https://github.com/imagick/imagick/archive/3.4.4.tar.gz | tar xvz -C /usr/src/php/ext/imagick --strip 1; \
	\
	docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr --with-webp-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		igbinary \
		imagick \
		mysqli \
		pdo_mysql \
		redis \
		zip \
	; \
	\
	docker-php-ext-enable opcache; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=135&LESSON_ID=2593
RUN set -ex; \
	\
	echo 'allow_url_fopen = "0"' > /usr/local/etc/php/conf.d/docker-php-allow-url-fopen.ini; \
	echo 'date.timezone = "Europe/Moscow"' > /usr/local/etc/php/conf.d/docker-php-date.ini; \
	echo 'display_errors = "0"' > /usr/local/etc/php/conf.d/docker-php-display-errors.ini; \
	echo 'max_execution_time = "300"' > /usr/local/etc/php/conf.d/docker-php-max-execution-time.ini; \
	echo 'max_file_uploads = "100"' > /usr/local/etc/php/conf.d/docker-php-max-file-uploads.ini; \
	echo 'max_input_vars = "10000"' > /usr/local/etc/php/conf.d/docker-php-max-input-vars.ini; \
	{ \
		echo 'mbstring.func_overload = "2"'; \
		echo 'mbstring.internal_encoding = "UTF-8"'; \
	} > /usr/local/etc/php/conf.d/docker-php-mbstring.ini; \
	echo 'memory_limit = "512M"' > /usr/local/etc/php/conf.d/docker-php-memory-limit.ini; \
	{ \
		echo 'opcache.max_accelerated_files = "100000"'; \
		echo 'opcache.revalidate_freq = "0"'; \
	} > /usr/local/etc/php/conf.d/docker-php-opcache.ini; \
	echo 'post_max_size = "1024M"' > /usr/local/etc/php/conf.d/docker-php-post-max-size.ini; \
	echo 'request_order = "GP"' > /usr/local/etc/php/conf.d/docker-php-request-order.ini; \
	echo 'sendmail_path = "/usr/bin/msmtp -t"' > /usr/local/etc/php/conf.d/docker-php-sendmail.ini; \
	echo 'upload_max_filesize = "1024M"' > /usr/local/etc/php/conf.d/docker-php-upload-max-filesize.ini


RUN set -ex; \
	a2enmod rewrite expires; \
	\
	# https://httpd.apache.org/docs/2.4/mod/mod_remoteip.html
	a2enmod remoteip; \
	{ \
		echo 'RemoteIPHeader X-Forwarded-For'; \
		echo 'RemoteIPTrustedProxy 10.0.0.0/8'; \
		echo 'RemoteIPTrustedProxy 127.0.0.0/8'; \
		echo 'RemoteIPTrustedProxy 172.16.0.0/12'; \
		echo 'RemoteIPTrustedProxy 169.254.0.0/16'; \
		echo 'RemoteIPTrustedProxy 192.168.0.0/16'; \
	} > /etc/apache2/conf-available/remoteip.conf; \
	a2enconf remoteip; \
	\
	find /etc/apache2 -type f -name '*.conf' -exec sed -ri 's/([[:space:]]*LogFormat[[:space:]]+"[^"]*)%h([^"]*")/\1%a\2/g' '{}' +


RUN set -ex; \
	\
	mkdir /usr/src/bitrix; \
	# https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&LESSON_ID=4891
	curl -fsSL https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php -o /usr/src/bitrix/bitrixsetup.php; \
	# https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&CHAPTER_ID=02014&LESSON_PATH=3903
	curl -fsSL https://www.1c-bitrix.ru/download/files/scripts/restore.php -o /usr/src/bitrix/restore.php

COPY www/* /usr/src/bitrix/

RUN set -ex; \
	\
	chown -R www-data:www-data /usr/src/bitrix; \
	chown -R www-data:root /var/www; \
	chmod -R g=u /var/www

VOLUME /var/www/html

COPY *.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
