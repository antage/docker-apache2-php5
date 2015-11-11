#!/bin/sh
set -e

if [ "$1" = 'apache2' ]; then
    export APACHE_SERVER_NAME="${APACHE_SERVER_NAME:-$(hostname)}"
    export APACHE_DOCUMENT_ROOT="${APACHE_DOCUMENT_ROOT:-/var/www/html}"

    export PHP_TIMEZONE="${PHP_TIMEZONE:-UTC}"

    for mod in $APACHE_MODS; do
        a2enmod -q $mod
    done

    for mod in $PHP_MODS; do
        echo "Enabling PHP 5.x module '$mod'."
        php5enmod -s ALL $mod
    done

    echo "Updating apache/php configuration files."
    /usr/local/bin/confd -onetime -backend env

    echo "Starting Apache 2.x in foreground."
    exec /usr/sbin/apache2 -D FOREGROUND
fi

exec "$@"
