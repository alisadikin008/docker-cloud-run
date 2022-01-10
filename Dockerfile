FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
ENV APACHE_CONF_DIR=/etc/apache2 \
    PHP_CONF_DIR=/etc/php/8.0 \
    PHP_DATA_DIR=/var/lib/php

# Install Ruby
RUN apt-get -y update && apt-get install -y ruby-full
RUN ruby -v
RUN gem -v

# Install Utilities
RUN apt-get install -y curl unzip build-essential nano wget mcrypt
RUN apt-get -qq update && apt-get -qq -y install bzip2
RUN apt-get install -y chrpath libssl-dev libxft-dev
RUN apt-get install -y libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev

# Install ppa:ondrej/php PPA
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:ondrej/php
RUN apt-get update

# Install PHP 8
RUN apt-get update && apt-get install -y apache2
RUN apt-get install -y php-pear libapache2-mod-php8.0
RUN apt-get install -y php8.0-common php8.0-cli php8.0-fpm
RUN apt-get install -y php8.0-pdo-mysql php8.0-bz2 php8.0-zip php8.0-curl php8.0-gd php8.0-xml php8.0-dev php8.0-mbstring php8.0-bcmath php8.0-opcache curl
RUN php -v
RUN php -m

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# PHP Config
# Show PHP errors on development server.
RUN sed -i -e 's/^error_reporting\s*=.*/error_reporting = E_ALL/' /etc/php/8.0/apache2/php.ini
RUN sed -i -e 's/^display_errors\s*=.*/display_errors = On/' /etc/php/8.0/apache2/php.ini
RUN sed -i -e 's/^zlib.output_compression\s*=.*/zlib.output_compression = Off/' /etc/php/8.0/apache2/php.ini
RUN sed -i -e 's/^zpost_max_size\s*=.*/post_max_size = 32M/' /etc/php/8.0/apache2/php.ini
RUN sed -i -e 's/^upload_max_filesize\s*=.*/upload_max_filesize = 32M/' /etc/php/8.0/apache2/php.ini

# Apache Config
# Allow .htaccess with RewriteEngine.
RUN a2enmod rewrite
RUN rm ${APACHE_CONF_DIR}/sites-enabled/000-default.conf ${APACHE_CONF_DIR}/sites-available/000-default.conf
RUN ln -sf /dev/stdout /var/log/apache2/access.log
RUN ln -sf /dev/stderr /var/log/apache2/error.log
RUN mkdir -p /var/www/aplikasi
COPY ./src /var/www/aplikasi/
RUN chmod -R 777 /var/www/aplikasi/storage
RUN chown www-data:www-data ${PHP_DATA_DIR} -Rf

COPY ./configuration/apache2.conf ${APACHE_CONF_DIR}/apache2.conf
COPY ./configuration/app.conf ${APACHE_CONF_DIR}/sites-enabled/app.conf
COPY ./configuration/php.ini  ${PHP_CONF_DIR}/apache2/conf.d/custom.ini

WORKDIR /var/www/aplikasi/
RUN cd /var/www/aplikasi/
#RUN cp storage/env/.env.development .env
RUN composer install --ignore-platform-reqs
# Ports
EXPOSE 80

# Start Apache2 on image start.
CMD ["/usr/sbin/apache2ctl", "-DFOREGROUND"]