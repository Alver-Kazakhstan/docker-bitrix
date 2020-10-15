#!/bin/bash
set -euo pipefail

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(<"${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

if [ -n "${SMTP_HOST+x}" ]; then
	echo 'Configuring SMTP...'

	{
		echo 'defaults'
		echo 'account default'

		if [ -n "${SMTP_AUTH+x}" ]; then
			file_env SMTP_USER
			file_env SMTP_PASSWORD

			echo "auth ${SMTP_AUTH}"
			echo "user ${SMTP_USER}"
			echo "password ${SMTP_PASSWORD}"
		else
			echo 'auth off'
		fi

		echo "from ${SMTP_FROM}"
		echo "host ${SMTP_HOST}"
		echo "port ${SMTP_PORT}"

		if [ -n "${SMTP_TLS+x}" ]; then
			echo "tls ${SMTP_TLS}"

			if [ -n "${SMTP_TLS_CERTCHECK+x}" ]; then
				echo "tls_certcheck ${SMTP_TLS_CERTCHECK}"
			else
				echo 'tls_certcheck off'
			fi

			if [ -n "${SMTP_TLS_STARTTLS+x}" ]; then
				echo "tls_starttls ${SMTP_TLS_STARTTLS}"
			else
				echo 'tls_starttls off'
			fi
		else
			echo 'tls off'
		fi
	} > /etc/msmtprc

	echo 'Complete! SMTP has been successfully configuried'
fi

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
	if [ "$(id -u)" = '0' ]; then
		case "$1" in
		apache2*)
			user="${APACHE_RUN_USER:-www-data}"
			group="${APACHE_RUN_GROUP:-www-data}"
			pound='#'
			user="${user#$pound}"
			group="${group#$pound}"
			;;
		*)
			user='www-data'
			group='www-data'
			;;
		esac
	else
		user="$(id -u)"
		group="$(id -g)"
	fi

	if [ ! -e index.php ]; then
		if [ "$(id -u)" = '0' ] && [ "$(stat -c '%u:%g' .)" = '0:0' ]; then
			chown "$user:$group" .
		fi

		echo >&2 "Bitrix not found in $PWD - copying installer now..."

		if [ -n '$(find -mindepth 1 -maxdepth 1 -not -name bitrix)' ]; then
			echo >&2 "WARNING: $PWD is not empty! (copying anyhow)"
		fi

		cp -a /usr/src/bitrix/* .

		echo >&2 "Complete! Bitrix installer has been successfully copied to $PWD"
	fi

	for e in "${envs[@]}"; do
		unset "$e"
	done
fi

exec "$@"
