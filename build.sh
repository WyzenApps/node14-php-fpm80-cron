#!/bin/sh

TAG=${1:-"node14-php-fpm80-cron"}

docker build -f Dockerfile --tag ${TAG}:latest .

