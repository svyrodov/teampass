# ============================================
# TeamPass Custom Docker Image
# ============================================
# Исправляет проблему с правами доступа:
# PHP-FPM и Nginx работают под одним пользователем (nginx)
# 
# Используется свежий образ PHP 8.3 с Alpine 3.21
# (минимальное количество уязвимостей на 2026 г.)
# ============================================

# Используем кастомный базовый образ с PHP 8.3 и Alpine 3.21
# Вместо устаревшего php:8.3-fpm-alpine3.19 с уязвимостями
FROM php:8.3-fpm-alpine3.21

# Устанавливаем зависимости, необходимые для TeamPass
# и совместимые с Alpine 3.21
RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
    curl \
    git \
    zip \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libwebp-dev \
    icu-libs \
    oniguruma-dev \
    libxml2-dev \
    sqlite-dev \
    ldap-dev \
    zlib-dev \
    openldap-dev \
    gmp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        curl \
        gd \
        gmp \
        iconv \
        ldap \
        mbstring \
        mysqli \
        pdo_mysql \
        soap \
        xml \
        zip \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

# Копируем конфигурацию Nginx
COPY --from=teampass/teampass:3.1.6.7 /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=teampass/teampass:3.1.6.7 /etc/nginx/http.d/default.conf /etc/nginx/http.d/default.conf

# Копируем конфигурацию PHP-FPM
COPY --from=teampass/teampass:3.1.6.7 /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf

# Переключаем PHP-FPM на пользователя nginx
# Это согласует PHP-FPM с Nginx worker и файлами (владелец nginx)
RUN sed -i 's/^user = .*/user = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^group = .*/group = nginx/' /usr/local/etc/php-fpm.d/www.conf

# Копируем приложение TeamPass из официального образа
COPY --from=teampass/teampass:3.1.6.7 /var/www/html /var/www/html

# Копируем supervisord и скрипты инициализации
COPY --from=teampass/teampass:3.1.6.7 /etc/supervisor.d/ /etc/supervisor.d/
COPY --from=teampass/teampass:3.1.6.7 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Настраиваем права доступа
# Все файлы принадлежат nginx (и PHP-FPM и Nginx работают под nginx)
RUN chown -R nginx:nginx /var/www/html && \
    chmod 700 /var/www/html/sk && \
    chmod 755 /var/www/html/files && \
    chmod 755 /var/www/html/upload && \
    chown -R nginx:nginx /var/www/html/includes/libraries/csrfp/log && \
    chown -R nginx:nginx /var/lib/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /run/nginx && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Настраиваем cron для задач планировщика
RUN echo "* * * * * php /var/www/html/sources/scheduler.php > /dev/null 2>&1" | crontab -u nginx -

# Открываем порт 80 для HTTP
EXPOSE 80

# Точка входа
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Команда по умолчанию
CMD ["supervisord", "-c", "/etc/supervisord.conf"]

# Метка с версией
LABEL org.opencontainers.image.title="TeamPass (Custom)"
LABEL org.opencontainers.image.description="TeamPass with fixed PHP-FPM user (nginx) on Alpine 3.21"
LABEL org.opencontainers.image.source="https://github.com/nilsteampassnet/TeamPass"
LABEL org.opencontainers.image.vendor="Custom build"
LABEL org.opencontainers.image.version="3.1.6.7"
LABEL org.opencontainers.image.base="php:8.3-fpm-alpine3.21"
