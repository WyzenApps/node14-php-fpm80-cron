FROM phpdockerio/php80-fpm:latest

# Fix debconf warnings upon build
ARG DEBIAN_FRONTEND=noninteractive
ARG APPDIR=/application
ARG LOCALE=fr_FR.UTF-8
ARG LC_ALL=fr_FR.UTF-8
ENV LOCALE=fr_FR.UTF-8
ENV LC_ALL=fr_FR.UTF-8
ARG NODE_RELEASE=14
ARG PHP_RELEASE=8.0

EXPOSE 9000

COPY config/system/locale.gen /etc/locale.gen

RUN cd /tmp \
    && apt-get update \
    && apt-get -y --no-install-recommends install curl wget git sudo cron locales vim supervisor \
    && locale-gen $LOCALE && update-locale \
    && mkdir -p $APPDIR \
    && usermod -u 33 -d $APPDIR www-data && groupmod -g 33 www-data \
    && chown www-data:www-data $APPDIR \
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
	php-memcached php${PHP_RELEASE}-xml \
	php${PHP_RELEASE}-mysql \
	php${PHP_RELEASE}-sqlite3 \
	php${PHP_RELEASE}-intl \
	php-pgsql \
	php-redis \
	php-gd \
	php-mbstring \
	php-yaml \
	php-xml \
	php-curl \
	php-zip \
	php-ldap \
	php-json

# CLEAN
RUN apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# ADDITIONALS CONFIG
ADD config/system/alias.sh /etc/profile.d/alias.sh
RUN cat /etc/profile.d/alias.sh > /etc/bash.bashrc

# Adding supervisor configuration file to container
ADD config/system/service_script.conf /src/supervisor/service_script.conf

WORKDIR $APPDIR

# Initializing Redis server and Gunicorn server from supervisord
CMD ["supervisord","-nc","/src/supervisor/service_script.conf"]

