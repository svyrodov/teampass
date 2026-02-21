FROM php:8.3-fpm-alpine3.21

LABEL maintainer="you@example.com"

# Versions
ENV TEAMPASS_VERSION=latest
ENV TEAMPASS_DIR=/var/www/html

# Install packages
RUN apk add --no-cache \
    nginx \
    bash \
    curl \
    git \
    unzip \
    icu-dev \
    oniguruma-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    mariadb-client \
    supervisor

# PHP extensions
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        mysqli \
        intl \
        zip \
        gd \
        opcache

# Download TeamPass
WORKDIR /tmp

RUN curl -L https://github.com/nilsteampassnet/TeamPass/archive/refs/heads/master.zip \
    -o teampass.zip \
    && unzip teampass.zip \
    && mv TeamPass-master/* ${TEAMPASS_DIR} \
    && rm -rf teampass.zip TeamPass-master

# Required directories
RUN mkdir -p \
    ${TEAMPASS_DIR}/sk \
    ${TEAMPASS_DIR}/files \
    ${TEAMPASS_DIR}/upload

# Permissions
RUN chown -R www-data:www-data ${TEAMPASS_DIR}

# Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Supervisor config
COPY supervisord.conf /etc/supervisord.conf

# PHP config
COPY php.ini /usr/local/etc/php/php.ini

EXPOSE 8080

CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]