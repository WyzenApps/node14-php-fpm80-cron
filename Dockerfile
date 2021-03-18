FROM phpdockerio/php80-fpm:latest

# Fix debconf warnings upon build
ARG DEBIAN_FRONTEND=noninteractive
ARG APPDIR=/application
ARG LOCALE="fr_FR.UTF-8"
ARG LC_ALL="fr_FR.UTF-8"
ENV LOCALE="fr_FR.UTF-8"
ENV LC_ALL="fr_FR.UTF-8"
ARG TIMEZONE="Europe/Paris"
ARG NODE_RELEASE=14
ARG PHP_RELEASE=8.0

EXPOSE 9000

COPY config/system/locale.gen /etc/locale.gen
COPY ./config/system/export_locale.sh /etc/profile.d/05-export_locale.sh

RUN apt update \
	&& apt -y --no-install-recommends dist-upgrade

RUN cd /tmp \
	&& groupadd -f --system --gid 33 www-data \
	&& groupadd -f --system --gid 105 crontab \
	&& mkdir -p $APPDIR \
	&& usermod -u 33 -g 33 -d $APPDIR www-data \
	&& chown www-data:www-data $APPDIR \
	&& apt-get -y --no-install-recommends install curl wget git sudo cron locales vim supervisor \
	&& locale-gen $LOCALE && update-locale LANGUAGE=${LOCALE} LC_ALL=${LOCALE} LANG=${LOCALE} LC_CTYPE=${LOCALE}\
	&& ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
	&& . /etc/default/locale \
	&& cat /etc/cron.d/* |grep -v '#' >> /etc/crontab

# NODE, YARN, COMPOSER
RUN cd /tmp && \
	curl -fsS https://getcomposer.org/installer -o composer-setup.php && \
	php composer-setup.php --quiet && mv composer.phar /usr/local/bin/composer && rm composer-setup.php && \
	curl -fsSL https://deb.nodesource.com/setup_${NODE_RELEASE}.x | sudo -E bash - && \
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
	echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
	apt update && apt install -y nodejs yarn

# PHP Packages
RUN apt-get -y --no-install-recommends install \
	php${PHP_RELEASE}-memcached \
	php${PHP_RELEASE}-gd \
	php${PHP_RELEASE}-ldap \
	php${PHP_RELEASE}-redis \
	php${PHP_RELEASE}-pgsql \
	php${PHP_RELEASE}-mysql \
	php${PHP_RELEASE}-sqlite3 \
	php${PHP_RELEASE}-intl \
	php${PHP_RELEASE}-mbstring \
	php${PHP_RELEASE}-xml \
	php${PHP_RELEASE}-curl \
	php${PHP_RELEASE}-zip \
	php-json \
	&& cd /etc/alternatives && ln -sf /usr/bin/php${PHP_RELEASE} php

# CLEAN
RUN apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# ADDITIONALS CONFIG
COPY ./config/php/php-ini-overrides.ini /etc/php/${PHP_RELEASE}/fpm/conf.d/99-overrides.ini
COPY ./config/php/php-ini-overrides.ini /etc/php/${PHP_RELEASE}/cli/conf.d/99-overrides.ini
COPY ./config/system/alias.sh /etc/profile.d/01-alias.sh
COPY ./config/system/service_script.conf /src/supervisor/service_script.conf

RUN cat /etc/profile.d/01-alias.sh > /etc/bash.bashrc

WORKDIR $APPDIR

# Initializing Redis server and Gunicorn server from supervisord
CMD ["supervisord","-nc","/src/supervisor/service_script.conf"]

