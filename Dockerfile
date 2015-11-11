FROM debian:stable

RUN \
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y -q update \
    && apt-get -y -q --no-install-recommends install \
        apache2-mpm-prefork \
        apache2 \
        php5-cli \
        php5 \
        curl \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm /var/log/dpkg.log \
    && rm /var/www/html/index.html \
    && curl -#L http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o /tmp/ioncube.tar.gz \
    && tar xzf /tmp/ioncube.tar.gz -C /tmp/ \
    && install -m 0644 \
        /tmp/ioncube/ioncube_loader_lin_$(php -r 'printf("%s.%s", PHP_MAJOR_VERSION, PHP_MINOR_VERSION);').so \
        $(php -r 'printf("%s", PHP_EXTENSION_DIR);')/ioncube_loader.so \
    && rm -rf /tmp/ioncube \
    && rm /tmp/ioncube.tar.gz \
    && echo "; configuration for php ionCube loader module\n; priority=00\nzend_extension=ioncube_loader.so" > /etc/php5/mods-available/ioncube_loader.ini \
    && curl -#L https://github.com/kelseyhightower/confd/releases/download/v0.10.0/confd-0.10.0-linux-amd64 -o /usr/local/bin/confd \
    && chmod 755 /usr/local/bin/confd \
    && mkdir -p /etc/confd/conf.d \
    && mkdir -p /etc/confd/templates \
    && touch /etc/confd/confd.toml

RUN \
    rm /etc/php5/apache2/conf.d/* \
    && rm /etc/php5/cli/conf.d/* \
    && php5enmod -s ALL opcache \
    && rm /etc/apache2/conf-enabled/* \
    && rm /etc/apache2/mods-enabled/* \
    && a2enmod mpm_prefork rewrite php5 env dir auth_basic authn_file authz_user authz_host

EXPOSE 8080

VOLUME ["/var/www", "/var/log/apache2", "/var/lib/php5/sessions"]

ENV LANG=C
ENV APACHE_LOCK_DIR         /var/lock/apache2
ENV APACHE_RUN_DIR          /var/run/apache2
ENV APACHE_PID_FILE         ${APACHE_RUN_DIR}/apache2.pid
ENV APACHE_LOG_DIR          /var/log/apache2
ENV APACHE_ULIMIT_MAX_FILES 'ulimit -n 65536'
ENV APACHE_RUN_USER         www-data
ENV APACHE_RUN_GROUP        www-data
ENV PHP_TIMEZONE            UTC

COPY confd/php.cli.toml /etc/confd/conf.d/
COPY confd/templates/php.cli.ini.tmpl /etc/confd/templates/
COPY confd/php.apache2.toml /etc/confd/conf.d/
COPY confd/templates/php.apache2.ini.tmpl /etc/confd/templates/
COPY confd/apache2.toml /etc/confd/conf.d/
COPY confd/templates/apache2.conf.tmpl /etc/confd/templates/
RUN /usr/local/bin/confd -onetime -backend env

COPY ports.conf /etc/apache2/ports.conf
COPY apache2-mods/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

COPY apache2-mods/remoteip.conf /etc/apache2/mods-available/remoteip.conf
RUN a2enmod remoteip

COPY index.php /var/www/html/index.php

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2"]
