#!/bin/bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

imagickVersion="$(
	git ls-remote --tags https://github.com/mkoppanen/imagick.git |
		cut -d/ -f3 |
		grep -viE '[a-z]' |
		tr -d '^{}' |
		sort -V |
		tail -1
)"

redisVersion="$(
	git ls-remote --tags https://github.com/phpredis/phpredis.git |
		cut -d/ -f3 |
		grep -viE '[a-z]' |
		tr -d '^{}' |
		sort -V |
		tail -1
)"

declare -A bases=(
	[apache]='debian'
	[fpm]='debian'
)

declare -A cmds=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
)

declare -A crontabInts=(
	[default]='1'
)

declare -A extras=(
	[apache]="$(< apache-extras.template)"
)

declare -A peclVersions=(
	[imagick]=$imagickVersion
	[redis]=$redisVersion
)

declare -A phpVersions=(
	[default]='7.4'
	[7.0]='7.0'
	[7.2]='7.2'
	[7.3]='7.3'
)

sed_escape_rhs() {
	sed -e 's/[\/&]/\\&/g; $!a\'$'\n''\\n' <<< "$*" | tr -d '\n'
}

for phpVersion in ${phpVersions[@]}; do
	phpVersionDir="php$phpVersion"

	for variant in apache fpm; do
		dir="$phpVersionDir/$variant"
		mkdir -p $dir

		base=${bases[$variant]}
		cmd=${cmds[$variant]}
		extras=${extras[$variant]:-}
		if [ -n "$extras" ]; then
			extras=$'\n'"$extras"$'\n'
		fi

		entrypoint='docker-entrypoint.sh'

		sed -r \
			-e "s!%%CMD%%!$cmd!g" \
			-e "s!%%CRONTAB_INT%%!${crontabInts[default]}!g" \
			-e "s!%%IMAGICK_VERSION%%!${peclVersions[imagick]}!g" \
			-e "s!%%PHP_VERSION%%!$phpVersion!g" \
			-e "s!%%REDIS_VERSION%%!${peclVersions[redis]}!g" \
			-e "s!%%VARIANT%%!$variant!g" \
			-e "s!%%VARIANT_EXTRAS%%!$(sed_escape_rhs "$extras")!g" \
			"Dockerfile-${base}.template" > "$dir/Dockerfile"

		case $phpVersion in
		7.0)
			sed -ri \
				-e 's!mbstring.func_overload = "0"!mbstring.func_overload = "2"!g' \
				"$dir/Dockerfile"
			;;
		esac
		case $phpVersion in
		7.2)
			sed -ri \
				-e '/libzip-dev/d' \
				"$dir/Dockerfile"
			;;
		esac
		case $phpVersion in
		7.0 | 7.2 | 7.3)
			sed -ri \
				-e 's!gd --with-freetype --with-jpeg --with-webp!gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr --with-webp-dir=/usr!g' \
				"$dir/Dockerfile"
			;;
		esac

		for name in cron entrypoint; do
			cp "docker-$name.sh" "$dir/docker-$name.sh"
		done

		cp -rT .www "$dir/www"
	done
done
