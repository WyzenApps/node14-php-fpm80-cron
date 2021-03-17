# node-php-fpm80-cron

Image: NODE 14, PHP-FPM 8.0, CRONTAB

## PHP-FPM
Port 9000

## CRON
To use cron, you must configure the crontab by owner.

You can update the file whan you want, this file use an autoreload

### Create file
Each file must have the owner UID and the crontab GID and a chmod 600.

```shell
# Example for www-data
sudo touch www-data
sudo chown www-data:crontab www-data
sudo chmod 600 www-data

```

### Config file
Use the same configuration of `crontab -e`:
```shell
# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h dom mon dow   command

```

### Mount file
Mount the file like a docker volumes like this:
```yaml
volumes:
      - ./config/system/crontabs/www-data:/var/spool/cron/crontabs/www-data
```

