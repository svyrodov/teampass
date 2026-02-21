# TeamPass Custom Docker Image

## Назначение

Этот Dockerfile создаёт кастомный образ TeamPass с исправленной проблемой прав доступа и свежей версией Alpine.

## Проблемы официального образа

В официальном образе `teampass/teampass:3.1.6.7`:
- **Nginx** работает от пользователя `nginx`
- **PHP-FPM** работает от пользователя `www-data`
- **Файлы** принадлежат `nginx:nginx`
- **Базовый образ**: `php:8.3-fpm-alpine3.19` (содержит уязвимости)

Это приводит к конфликту прав доступа — PHP-FPM не может записывать файлы в каталоги `sk/`, `files/`, `upload/`.

## Решение

1. **Исправляем пользователя PHP-FPM** с `www-data` на `nginx`
2. **Используем свежий Alpine 3.21** вместо 3.19 (минимум уязвимостей)
3. **Все файлы принадлежат `nginx`** — согласованность между компонентами

```dockerfile
FROM php:8.3-fpm-alpine3.21

# Установка зависимостей и копирование файлов из официального образа
COPY --from=teampass/teampass:3.1.6.7 /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=teampass/teampass:3.1.6.7 /var/www/html /var/www/html

# Исправление пользователя PHP-FPM
RUN sed -i 's/^user = .*/user = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^group = .*/group = nginx/' /usr/local/etc/php-fpm.d/www.conf
```

## Сборка образа

### Быстрая сборка

```bash
cd docker
./build.sh
```

### Ручная сборка

```bash
cd docker

# Сборка локального образа
docker build -t teampass-custom:3.1.6.7 .

# Сборка с указанием registry
docker build -t registry.example.com/teampass-custom:3.1.6.7 .
```

### Переменные окружения для сборки

| Переменная | Описание | Значение по умолчанию |
|------------|----------|----------------------|
| `DOCKER_IMAGE_NAME` | Имя образа | `teampass-custom` |
| `DOCKER_IMAGE_TAG` | Тег образа | `3.1.6.7-alpine3.21` |
| `DOCKER_REGISTRY` | Registry для push | (не указан) |
| `BASE_IMAGE` | Базовый образ | `php:8.3-fpm-alpine3.21` |

Пример:
```bash
DOCKER_REGISTRY=registry.example.com \
DOCKER_IMAGE_NAME=teampass \
DOCKER_IMAGE_TAG=3.1.6.7 \
./build.sh
```

## Проверка

### Проверка пользователя PHP-FPM

```bash
docker run --rm teampass-custom:3.1.6.7 \
  grep -E "^user =|^group =" /usr/local/etc/php-fpm.d/www.conf
```

Ожидаемый вывод:
```
user = nginx
group = nginx
```

### Проверка прав доступа

```bash
docker run --rm teampass-custom:3.1.6.7 \
  ls -la /var/www/html/ | grep -E "sk|files|upload"
```

Ожидаемый вывод:
```
drwx------    2 nginx    nginx      4096 Feb 21 03:00 sk
drwxr-xr-x    2 nginx    nginx      4096 Feb 21 03:00 files
drwxr-xr-x    2 nginx    nginx      4096 Feb 21 03:00 upload
```

### Проверка процессов

```bash
docker run --rm teampass-custom:3.1.6.7 \
  ps aux | grep -E "nginx|php-fpm"
```

Ожидаемый вывод:
```
nginx    php-fpm: master process (/usr/local/etc/php-fpm.conf)
nginx    php-fpm: pool www
nginx    php-fpm: pool www
nginx    nginx: worker process
```

## Использование с Helm chart

Обновите `values.yaml`:

```yaml
image:
  repository: teampass-custom
  tag: "3.1.6.7"
```

Или используйте `values-example.yaml` / `values-production.yaml` — они уже настроены на кастомный образ.

## Push в registry

```bash
# Docker Hub
docker tag teampass-custom:3.1.6.7 username/teampass-custom:3.1.6.7
docker push username/teampass-custom:3.1.6.7

# Private registry
docker tag teampass-custom:3.1.6.7 registry.example.com/teampass-custom:3.1.6.7
docker push registry.example.com/teampass-custom:3.1.6.7
```

## Отличия от официального образа

| Компонент | Официальный образ | Кастомный образ |
|-----------|-------------------|-----------------|
| PHP-FPM user | `www-data` | `nginx` ✅ |
| PHP-FPM group | `www-data` | `nginx` ✅ |
| Файлы владелец | `nginx` | `nginx` |
| Nginx worker | `nginx` | `nginx` |
| Cron задачи | `nginx` | `nginx` |

## Версионирование

- Используйте тот же тег, что и базовый образ (например, `3.1.6.7`)
- Для production рекомендуется использовать SHA256 хеш коммита

## Безопасность

Кастомный образ не вносит изменений в безопасность:
- Сохраняются все оригинальные настройки безопасности
- Изменяется только пользователь PHP-FPM
- Нет дополнительных пакетов или зависимостей

## Troubleshooting

### Ошибка сборки "base image not found"

```bash
# Убедитесь, что базовый образ доступен
docker pull teampass/teampass:3.1.6.7
```

### PHP-FPM не запускается

Проверьте, что пользователь `nginx` существует:

```bash
docker run --rm teampass-custom:3.1.6.7 id nginx
```

Ожидаемый вывод:
```
uid=82(nginx) gid=82(nginx) groups=82(nginx)
```

## Лицензия

Наследует лицензию оригинального образа TeamPass (AGPL-3.0).
