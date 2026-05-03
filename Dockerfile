FROM php:8.3-apache

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        default-mysql-client \
        git \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        soap \
        zip \
    && a2enmod rewrite headers expires remoteip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY . /var/www/html
COPY docker/apache-vhost.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php-production.ini /usr/local/etc/php/conf.d/zz-moodle-production.ini
COPY docker/entrypoint.sh /usr/local/bin/moodle-entrypoint

RUN COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --classmap-authoritative --no-interaction --no-progress \
    && test -f /var/www/html/vendor/autoload.php \
    && test -f /var/www/html/vendor/composer/installed.php \
    && php -r "if (ini_get('zend.exception_ignore_args') !== '1') { fwrite(STDERR, 'zend.exception_ignore_args is not enabled'.PHP_EOL); exit(1); }" \
    && chmod +x /usr/local/bin/moodle-entrypoint \
    && mkdir -p /var/www/moodledata \
    && chown -R www-data:www-data /var/www/html /var/www/moodledata

ENV MOODLE_DATABASE_TYPE=mariadb \
    MOODLE_DATABASE_HOST=moodle-db \
    MOODLE_DATABASE_NAME=moodle \
    MOODLE_DATABASE_USER=moodle \
    MOODLE_DBPREFIX=mdl_ \
    MOODLE_WWWROOT=http://localhost \
    MOODLE_DATAROOT=/var/www/moodledata \
    MOODLE_REVERSE_PROXY=false \
    MOODLE_SSL_PROXY=true

EXPOSE 80

ENTRYPOINT ["moodle-entrypoint"]
CMD ["apache2-foreground"]
