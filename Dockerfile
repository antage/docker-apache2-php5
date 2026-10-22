# apache2-php5: Apache 2.4 (prefork) + mod_php 5.6, Debian jessie.
#
# Stage build-php56 rebuilds php5 5.6.40+dfsg-0+deb8u12 from the official Debian
# jessie source with the security/ patches applied on top of the official
# debian patch series (see security/README.md). The debs keep Debian's own
# version, so in the final stage they replace the stock php5 core in place and
# all stock php5-* extension packages (PECL: imagick, memcache, mongo, redis,
# apcu, xdebug, json) keep working against the rebuilt core.

# === builder: patched php5 debs from the official debian source ===
# PHP 5.6 from the official debian source (php5 5.6.40+dfsg-0+deb8u12, Debian jessie)
# + CVE-2026-109618/CVE-2026-109619 patches (see security/README.md).
FROM registry.gitlab.com/manageservers/docker-debian/base/jessie:master AS build-php56
ENV DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list; \
    echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie main" > /etc/apt/sources.list; \
    echo "deb [check-valid-until=no] http://archive.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        apache2-bin apache2-dev autoconf automake bison build-essential chrpath debhelper dh-systemd \
        dpkg-dev flex firebird-dev freetds-dev libapparmor-dev libapr1-dev libbz2-dev \
        libc-client2007e-dev libcurl4-openssl-dev libdb-dev libedit-dev libenchant-dev \
        libevent-dev libexpat1-dev libfreetype6-dev libgcrypt11-dev libgd2-xpm-dev \
        libglib2.0-dev libgmp3-dev libicu-dev libjpeg62-turbo-dev libkrb5-dev libldap2-dev \
        libmagic-dev libmcrypt-dev libmhash-dev libmysqlclient-dev libonig-dev libpam0g-dev \
        libpcre3-dev libpng12-dev libpq-dev libpspell-dev libqdbm-dev librecode-dev \
        libsasl2-dev libsnmp-dev libsqlite3-dev libssl-dev libsystemd-dev libtidy-dev \
        libtool libvpx-dev libwrap0-dev libxpm-dev libxml2-dev libxmltok1-dev libxslt1-dev \
        re2c systemtap-sdt-dev unixodbc-dev zlib1g-dev; \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*; \
    apt-get clean; rm -rf /var/lib/apt/lists/*
COPY security/CVE-2026-109618-109619-php56.patch /tmp/CVE-2026-109618-109619.patch
RUN set -eux; \
    mkdir -p /src; cd /src; \
    curl -fsS -O http://archive.debian.org/debian-security/pool/updates/main/p/php5/php5_5.6.40+dfsg-0+deb8u12.dsc; \
    curl -fsS -O http://archive.debian.org/debian-security/pool/updates/main/p/php5/php5_5.6.40+dfsg.orig.tar.gz; \
    curl -fsS -O http://archive.debian.org/debian-security/pool/updates/main/p/php5/php5_5.6.40+dfsg-0+deb8u12.debian.tar.xz; \
    echo "57771203be7b7f8485bcf4e134e2ffffcd93574780d3f9c68a49b79a73c4382e  php5_5.6.40+dfsg-0+deb8u12.dsc" | sha256sum -c -; \
    echo "1ffdf771591b6afdff5c3b2b22febe6043f92bc67bb6f8e4629183127819345d  php5_5.6.40+dfsg.orig.tar.gz" | sha256sum -c -; \
    echo "4ad44b74eb76b077c3f44b81266cc5b1cb47d138b0af70c1a2b57afbce02aafa  php5_5.6.40+dfsg-0+deb8u12.debian.tar.xz" | sha256sum -c -; \
    dpkg-source -x php5_5.6.40+dfsg-0+deb8u12.dsc; \
    cd php5-5.6.40+dfsg; \
    sed -i 's/PHP_EXTRA_VERSION=""/PHP_EXTRA_VERSION="-0+deb8u12+manageservers"/' configure.in; \
    cp /tmp/CVE-2026-109618-109619.patch debian/patches/; \
    echo "CVE-2026-109618-109619.patch" >> debian/patches/series; \
    patch -p1 --forward < debian/patches/CVE-2026-109618-109619.patch; \
    if ! DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -d -us -uc -b -j"$(nproc)" > /src/build.log 2>&1; then \
        echo "=== dpkg-buildpackage failed, errors from /src/build.log: ==="; \
        grep -n -m5 -B10 -A20 -e "error:" -e "\*\*\*" /src/build.log | head -c 131072 || true; \
        echo "=== tail: ==="; \
        tail -n 1000 /src/build.log; \
        false; \
    fi; \
    rm -f /src/build.log; \
    cd /src; \
    mkdir -p /out; \
    mv *.deb /out/; \
    rm -rf /src

# === final: the stock jessie apache2+mod_php5 image, patched php5 core ===
FROM registry.gitlab.com/manageservers/docker-debian/base/jessie:master
ENV DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list; \
    echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie main" > /etc/apt/sources.list; \
    echo "deb [check-valid-until=no] http://archive.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl; \
    echo "deb http://archive.deb-multimedia.org jessie main non-free" > /etc/apt/sources.list.d/deb-multimedia.list; \
    echo "deb [check-valid-until=no] https://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list; \
    curl -fsS https://download.newrelic.com/548C16BF.gpg -o /etc/apt/trusted.gpg.d/newrelic.gpg; \
    apt-get update -o Acquire::AllowInsecureRepositories=true; \
    apt-get install -y --no-install-recommends -o Acquire::AllowInsecureRepositories=true deb-multimedia-keyring; \
    apt-get update -o Acquire::AllowInsecureRepositories=true; \
    apt-get install -y --no-install-recommends -o Acquire::AllowInsecureRepositories=true \
        curl \
        ca-certificates \
        imagemagick \
        msmtp-mta \
        apache2-mpm-prefork \
        apache2 \
        apache2-dbg \
        libapr1-dbg \
        libaprutil1-dbg \
        php5-cli \
        php5-mysql \
        php5-gd \
        php5-imagick \
        php5-mcrypt \
        php5-curl \
        php5-memcache \
        php5-xsl \
        php5-xdebug \
        php5-intl \
        php5-xmlrpc \
        php5-apcu \
        php5-mongo \
        php5-redis \
        php5 \
        php5-dev \
        php-pear \
        php5-dbg \
        gdb \
        ffmpeg \
        ghostscript \
        wget \
        pngquant \
        jpegoptim \
        optipng \
        newrelic-php5 \
        git; \
    rm /var/www/html/index.html; \
    rmdir /var/www/html
# Rebuilt (patched) php5 debs, same version as the stock ones installed above.
# Order matters for dpkg -i: php5-common first, then the packages that depend on it.
# php5-json (dependency of php5-cli/mod) and the PECL extensions stay stock:
# they are not affected by these CVEs.
COPY --from=build-php56 \
    /out/php5-common_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/libapache2-mod-php5_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php5-cli_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php-pear_5.6.40+dfsg-0+deb8u12_all.deb \
    /out/php5_5.6.40+dfsg-0+deb8u12_all.deb \
    /out/php5-dev_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php5-dbg_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php5-mysql_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php5-gd_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php5-mcrypt_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php5-curl_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php5-xsl_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php5-intl_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /out/php5-xmlrpc_5.6.40+dfsg-0+deb8u12_amd64.deb \
    /debs/
RUN set -eux; \
    dpkg -i \
        /debs/php5-common_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/libapache2-mod-php5_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php5-cli_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php-pear_5.6.40+dfsg-0+deb8u12_all.deb \
        /debs/php5_5.6.40+dfsg-0+deb8u12_all.deb \
        /debs/php5-dev_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php5-dbg_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php5-mysql_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php5-gd_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php5-mcrypt_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php5-curl_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php5-xsl_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php5-intl_5.6.40+dfsg-0+deb8u12_amd64.deb \
        /debs/php5-xmlrpc_5.6.40+dfsg-0+deb8u12_amd64.deb; \
    apt-get -y -f install -o Acquire::AllowInsecureRepositories=true; \
    apt-get clean; \
    rm -rf /debs /var/cache/apt/archives/* /var/lib/apt/lists/* /var/log/dpkg.log
RUN \
    curl -#L http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o /tmp/ioncube.tar.gz \
    && tar xzf /tmp/ioncube.tar.gz -C /tmp/ \
    && install -m 0644 \
        /tmp/ioncube/ioncube_loader_lin_$(php -r 'printf("%s.%s", PHP_MAJOR_VERSION, PHP_MINOR_VERSION);').so \
        $(php -r 'printf("%s", PHP_EXTENSION_DIR);')/ioncube_loader.so \
    && rm -rf /tmp/ioncube \
    && rm /tmp/ioncube.tar.gz \
    && echo "; configuration for php ionCube loader module\n; priority=00\nzend_extension=ioncube_loader.so" > /etc/php5/mods-available/ioncube_loader.ini \
    && curl -#L https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64 -o /usr/local/bin/confd \
    && chmod 755 /usr/local/bin/confd \
    && mkdir -p /etc/confd/conf.d \
    && mkdir -p /etc/confd/templates \
    && touch /etc/confd/confd.toml \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64" \
    && chmod +x /usr/local/bin/gosu \
    && curl -o /usr/local/bin/composer https://getcomposer.org/download/1.8.5/composer.phar \
    && chown root:root /usr/local/bin/composer \
    && chmod 0755 /usr/local/bin/composer
RUN \
    sed -i -E 's/^mozilla\/DST_Root_CA_X3\.crt$/!\0/' /etc/ca-certificates.conf \
    && update-ca-certificates
RUN \
    rm /etc/php5/apache2/conf.d/* \
    && rm /etc/php5/cli/conf.d/* \
    && php5enmod -s ALL opcache \
    && rm /etc/apache2/conf-enabled/* \
    && rm /etc/apache2/mods-enabled/* \
    && a2enmod mpm_prefork rewrite php5 env dir auth_basic authn_file authz_user authz_host access_compat \
    && rm /etc/apache2/sites-enabled/000-default.conf \
    && rm -f /var/run/newrelic-daemon.pid
COPY Rediska-0.5.10.tgz /tmp/Rediska-0.5.10.tar.gz
RUN pear install /tmp/Rediska-0.5.10.tar.gz \
    && rm /tmp/Rediska-0.5.10.tar.gz

EXPOSE 8080

ENV LANG=C
ENV APACHE_LOCK_DIR         /var/lock/apache2
ENV APACHE_RUN_DIR          /var/run/apache2
ENV APACHE_PID_FILE         ${APACHE_RUN_DIR}/apache2.pid
ENV APACHE_LOG_DIR          /var/log/apache2
ENV APACHE_RUN_USER         www-data
ENV APACHE_RUN_GROUP        www-data
ENV APACHE_MAX_REQUEST_WORKERS 32
ENV APACHE_MAX_CONNECTIONS_PER_CHILD 1024
ENV APACHE_ALLOW_OVERRIDE   None
ENV APACHE_ALLOW_ENCODED_SLASHES Off
ENV APACHE_ERRORLOG         ""
ENV APACHE_CUSTOMLOG        ""
ENV APACHE_LOGLEVEL         error
ENV PHP_TIMEZONE            UTC
ENV PHP_MBSTRING_FUNC_OVERLOAD 0
ENV PHP_ALWAYS_POPULATE_RAW_POST_DATA 0
ENV PHP_MEMORY_LIMIT        "1024M"
ENV PHP_SESSION_GC_MAXLIFETIME  86400
ENV PHP_NEWRELIC_LICENSE_KEY    ""
ENV PHP_NEWRELIC_APPNAME        ""
ENV PHP_NEWRELIC_FRAMEWORK      "no_framework"
ENV PHP_NEWRELIC_PORT           "/run/newrelic/newrelic.sock"

COPY apache2-coredumps.conf /etc/security/limits.d/apache2-coredumps.conf
RUN mkdir /tmp/apache2-coredumps && chown ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /tmp/apache2-coredumps && chmod 700 /tmp/apache2-coredumps
COPY coredump.conf /etc/apache2/conf-available/coredump.conf
COPY .gdbinit /root/.gdbinit

COPY opcache_bitrix.blacklist /etc/php5/opcache_bitrix.blacklist

COPY confd/php.cli.toml /etc/confd/conf.d/
COPY confd/templates/php.cli.ini.tmpl /etc/confd/templates/
COPY confd/php.apache2.toml /etc/confd/conf.d/
COPY confd/templates/php.apache2.ini.tmpl /etc/confd/templates/
COPY confd/apache2.toml /etc/confd/conf.d/
COPY confd/templates/apache2.conf.tmpl /etc/confd/templates/
COPY confd/mpm_prefork.toml /etc/confd/conf.d/
COPY confd/templates/mpm_prefork.conf.tmpl /etc/confd/templates/
COPY confd/newrelic.toml /etc/confd/conf.d/
COPY confd/templates/newrelic.ini.tmpl /etc/confd/templates/
RUN /usr/local/bin/confd -onetime -backend env
COPY confd/msmtprc.toml /etc/confd/conf.d/
COPY confd/templates/msmtprc.tmpl /etc/confd/templates/

COPY ports.conf /etc/apache2/ports.conf

COPY apache2-mods/php5.conf /etc/apache2/mods-available/php5.conf
COPY apache2-mods/mime.conf /etc/apache2/mods-available/mime.conf
COPY apache2-mods/alias.conf /etc/apache2/mods-available/alias.conf
COPY apache2-mods/autoindex.conf /etc/apache2/mods-available/autoindex.conf

COPY apache2-mods/remoteip.conf /etc/apache2/mods-available/remoteip.conf
RUN a2enmod remoteip

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2"]
