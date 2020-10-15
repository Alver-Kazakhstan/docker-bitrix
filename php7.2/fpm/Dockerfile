FROM php:7.2-fpm

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
		libfreetype6-dev \
		libjpeg-dev \
		libmagickwand-dev \
		libpng-dev \
		libwebp-dev \
		libxml2-dev \
	; \
	\
	docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr --with-webp-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		mysqli \
		pdo_mysql \
		zip \
	; \
	\
	# https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=43&LESSON_ID=2795
	pecl install imagick-3.4.4; \
	pecl install redis-5.3.1; \
	\
	docker-php-ext-enable \
	imagick \
	opcache \
	redis \
	; \
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
	echo 'date.timezone = "Europe/Moscow"' > /usr/local/etc/php/conf.d/docker-bitrix-ext-date.ini; \
	\
	echo 'max_input_vars = "10000"' > /usr/local/etc/php/conf.d/docker-bitrix-ext-max-input-vars.ini; \
	\
	{ \
		echo 'mbstring.func_overload = "0"'; \
		echo 'mbstring.internal_encoding = "UTF-8"'; \
	} > /usr/local/etc/php/conf.d/docker-bitrix-ext-mbstring.ini; \
	\
	echo 'memory_limit = "512M"' > /usr/local/etc/php/conf.d/docker-bitrix-ext-memory-limit.ini; \
	\
	{ \
		echo 'opcache.max_accelerated_files = "100000"'; \
		echo 'opcache.revalidate_freq = "0"'; \
	} > /usr/local/etc/php/conf.d/docker-bitrix-ext-opcache.ini; \
	\
	echo 'sendmail_path = "/usr/bin/msmtp -t"' > /usr/local/etc/php/conf.d/docker-bitrix-ext-sendmail.ini; \
	\
	echo 'upload_max_filesize = "64M"' > /usr/local/etc/php/conf.d/docker-bitrix-ext-upload-max-filesize.ini



RUN set -ex; \
	\
	mkdir /usr/src/bitrix; \
	# https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&LESSON_ID=4891
	curl -fsSL 'https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php' -o /usr/src/bitrix/bitrixsetup.php; \
	# https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&CHAPTER_ID=02014&LESSON_PATH=3903
	curl -fsSL 'https://www.1c-bitrix.ru/download/files/scripts/restore.php' -o /usr/src/bitrix/restore.php

COPY www/* /usr/src/bitrix/

RUN set -ex; \
	\
	chown -R www-data:www-data /usr/src/bitrix; \
	chown -R www-data:root /var/www; \
	chmod -R g=u /var/www

VOLUME /var/www/html

COPY *.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
