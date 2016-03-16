# apache2-php5

Apache 2.x + mod\_php 5.x

Based on debian:stable.

## Building

Just run `make`.

## Volumes

* `/var/lib/php5/sessions` (tmpfs is recommended)
* `/tmp/apache2-coredumps` (optional)
* `/var/log/apache2`
* `/var/www`

## Exposed ports

* 8080/tcp

## Environment variables

* `CREATE_USER_UID`
* `CREATE_USER_GID`
* `CREATE_SYMLINKS` (for example: "/var/www/dir1>/var/dir1,/var/www/dir2>/var/dir2")
* `APACHE_COREDUMP`
* `APACHE_RUN_USER`
* `APACHE_RUN_GROUP`
* `APACHE_MODS`
* `APACHE_DOCUMENT_ROOT` (/var/www/html by default)
* `APACHE_SERVER_NAME` (hostname by default)
* `APACHE_ALLOW_OVERRIDE` ('None' by default)
* `APACHE_ALLOW_ENCODED_SLASHES` ('Off' by default)
* `PHP_MODS`
* `PHP_TIMEZONE` ('UTC' by default)
* `PHP_SMTP` - MTA SMTP IP-address/hostname
* `PHP_SMTP_FROM` - default `From` header for mail.
