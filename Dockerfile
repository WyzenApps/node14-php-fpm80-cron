FROM php:8.1-fpm-bullseye

# Fix debconf warnings upon build
ARG DEBIAN_FRONTEND=noninteractive
ARG APPDIR=/application
ARG LOCALE="fr_FR.UTF-8"
ARG LC_ALL="fr_FR.UTF-8"
ENV LOCALE="fr_FR.UTF-8"
ENV LC_ALL="fr_FR.UTF-8"
ARG TIMEZONE="Europe/Paris"
ARG PHP_RELEASE=8.1

EXPOSE 9000

COPY config/system/locale.gen /etc/locale.gen
COPY ./config/system/export_locale.sh /etc/profile.d/05-export_locale.sh
COPY ./config/php/php.ini /usr/local/etc/php/php.ini

RUN apt update && apt dist-upgrade -y && apt install -y curl wget git sudo locales vim unzip \
	libfreetype6-dev \
	libjpeg62-turbo-dev \
	libpng-dev

RUN cd /tmp \
	&& groupadd -f --system --gid 33 www-data \
	&& mkdir -p $APPDIR \
	&& usermod -u 33 -g 33 -d $APPDIR www-data \
	&& chown www-data:www-data $APPDIR \
	&& locale-gen $LOCALE && update-locale LANGUAGE=${LOCALE} LC_ALL=${LOCALE} LANG=${LOCALE} LC_CTYPE=${LOCALE}\
	&& ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
	&& . /etc/default/locale

# COMPOSER
RUN cd /tmp && \
	curl -fsS https://getcomposer.org/installer -o composer-setup.php && \
	php composer-setup.php --quiet && mv composer.phar /usr/local/bin/composer && rm composer-setup.php

# PHP Packages
RUN apt install -y zlib1g zlib1g-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
	libldap2-dev \
	libpq-dev \
	libicu-dev \
	libzip-dev \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install -j$(nproc) \
	gd \
	calendar \
	ldap \
	pdo_pgsql \
	pdo_mysql \
	intl \
	zip

# CLEAN
RUN apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# ADDITIONALS CONFIG
COPY ./config/php/php-ini-overrides.ini /usr/local/etc/php/conf.d/99-overrides.ini
COPY ./config/system/alias.sh /etc/profile.d/01-alias.sh

RUN cat /etc/profile.d/01-alias.sh > /etc/bash.bashrc

VOLUME [ "$APPDIR", "/usr/local/etc/php/conf.d" ]
WORKDIR $APPDIR

# Initializing Redis server and Gunicorn server from supervisord
# CMD ["supervisord","-nc","/src/supervisor/service_script.conf"]

