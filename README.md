# apache2-php5

Apache 2.x + mod\_php 5.x

Based on debian:jessie.

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
* `APACHE_MAX_REQUEST_WORKERS` (32 by default)
* `APACHE_MAX_CONNECTIONS_PER_CHILD` (1024 by default)
* `APACHE_LOGLEVEL` ('error' by default)
* `APACHE_ERRORLOG` - a path for error log.
* `APACHE_CUSTOMLOG` - a path for custom (access) log.
* `PHP_MODS`
* `PHP_TIMEZONE` ('UTC' by default)
* `PHP_SMTP` - MTA SMTP IP-address/hostname
* `PHP_SMTP_FROM` - default `From` header for mail (example:
  'noreply@example.org')
* `PHP_MBSTRING_FUNC_OVERLOAD` - `mbstring.func_overload` (0 by default).
* `PHP_ALWAYS_POPULATE_RAW_POST_DATA` - `always_populate_raw_post_data` (0 by default).
* `PHP_NEWRELIC_LICENSE_KEY` - Newrelic agent license key (empty and disabled by default).
* `PHP_NEWRELIC_APPNAME` - Newrelic application name (empty by default).

## Required variables

Following variables must be defined to run the container:

* `PHP_SMTP`
* `PHP_SMTP_FROM`

## Redirect access and error log to stdout

Set following environment variables:

* `APACHE_CUSTOMLOG='"|/bin/cat" combined'`
* `APACHE_ERRORLOG='"|/bin/cat"'`

