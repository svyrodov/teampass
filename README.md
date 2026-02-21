# TeamPass Docker Deployment

[![TeamPass Version](https://img.shields.io/badge/teampass-3.1.6.7-blue)](https://teampass.net/)
[![Docker Compose](https://img.shields.io/badge/docker--compose-v3.8-blue)](https://docs.docker.com/compose/)
[![MariaDB](https://img.shields.io/badge/mariadb-12.2.2-blue)](https://mariadb.org/)
[![Helm](https://img.shields.io/badge/helm-v3-blue)](https://helm.sh/)

Комплексное решение для развёртывания **TeamPass** — менеджера паролей для командной работы — с использованием Docker Compose и Helm Chart для Kubernetes.

## 📋 Оглавление

- [О проекте](#о-проекте)
- [Архитектура](#архитектура)
- [Быстрый старт](#быстрый-старт)
- [Конфигурация](#конфигурация)
- [Helm Chart](#helm-chart)
- [Безопасность](#безопасность)
- [Устранение неполадок](#устранение-неполадок)
- [Структура проекта](#структура-проекта)

---

## 📦 О проекте

**TeamPass** — это веб-ориентированный менеджер паролей, предназначенный для совместного использования в команде. Этот проект предоставляет:

- **Docker Compose** конфигурацию для локального развёртывания
- **Helm Chart** для развёртывания в Kubernetes
- Автоматизированную установку с предконфигурированными параметрами
- Поддержку SSL/TLS через nginx-proxy

### Основные возможности

- 🔐 Безопасное хранение паролей
- 👥 Управление доступом на основе ролей
- 📁 Организация паролей по папкам и тегам
- 🔑 Шифрование данных с использованием ключей соли (salt keys)
- 📊 Аудит и логирование действий
- 🔄 Резервное копирование базы данных

---

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                     TeamPass Deployment                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────┐     ┌─────────────────┐                │
│  │   TeamPass      │────▶│    MariaDB      │                │
│  │   (PHP/App)     │     │    (Database)   │                │
│  │   Port: 8080    │     │    Port: 3306   │                │
│  └─────────────────┘     └─────────────────┘                │
│         │                        │                          │
│         ▼                        ▼                          │
│    [teampass-network]      [teampass-db volume]             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Компоненты

| Сервис | Образ | Назначение |
|--------|-------|------------|
| `teampass` | `teampass/teampass:3.1.6.7` | Основное приложение |
| `db` | `mariadb:12.2.2` | Сервер базы данных |

### Тома данных

| Том | Путь монтирования | Назначение |
|-----|-------------------|------------|
| `teampass-sk` | `/var/www/html/sk` | Ключи соли для шифрования |
| `teampass-files` | `/var/www/html/files` | Файлы |
| `teampass-upload` | `/var/www/html/upload` | Загруженные файлы |
| `teampass-db` | `/var/lib/mysql` | База данных |

---

## 🚀 Быстрый старт

### Требования

- Docker Engine 20.10+
- Docker Compose v2.0+
- 1 GB свободного места на диске
- 512 MB оперативной памяти

### Установка

1. **Клонируйте репозиторий:**
   ```bash
   git clone <repository-url>
   cd TeamPass
   ```

2. **Создайте файл окружения:**
   ```bash
   cp .env.example .env
   ```

3. **Настройте переменные окружения:**
   
   Отредактируйте `.env` и установите безопасные пароли:
   ```bash
   # Обязательные параметры
   DB_PASSWORD=YourSecureDatabasePassword
   MARIADB_ROOT_PASSWORD=YourSecureRootPassword
   
   # Опционально: для автоматической установки
   INSTALL_MODE=auto
   ADMIN_PWD=YourAdminPassword
   ```

   > 💡 **Совет:** Сгенерируйте надёжные пароли:
   > ```bash
   > openssl rand -base64 32
   > ```

4. **Запустите контейнеры:**
   ```bash
   docker compose up -d
   ```

5. **Откройте TeamPass:**
   
   Перейдите по адресу `http://localhost:8080` в браузере.

### Режимы установки

#### Ручная установка (по умолчанию)

```bash
INSTALL_MODE=manual
```

Завершите установку через веб-интерфейс по адресу `http://localhost:8080`.

#### Автоматическая установка

```bash
INSTALL_MODE=auto
ADMIN_EMAIL=admin@teampass.local
ADMIN_PWD=YourSecurePassword
```

Установка выполнится автоматически при первом запуске.

---

## ⚙️ Конфигурация

### Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `TEAMPASS_VERSION` | Версия TeamPass | `3.1.6.7` |
| `TEAMPASS_PORT` | Порт для доступа | `8080` |
| `TEAMPASS_URL` | Публичный URL | `http://localhost` |
| `DB_NAME` | Имя базы данных | `teampass` |
| `DB_USER` | Пользователь БД | `teampass` |
| `DB_PASSWORD` | Пароль БД | *требуется* |
| `DB_PREFIX` | Префикс таблиц | `teampass_` |
| `MARIADB_ROOT_PASSWORD` | Root-пароль MariaDB | *требуется* |
| `INSTALL_MODE` | Режим установки | `manual` |
| `ADMIN_EMAIL` | Email администратора | `admin@teampass.local` |
| `ADMIN_PWD` | Пароль администратора | *пусто* |
| `PHP_MEMORY_LIMIT` | Лимит памяти PHP | `512M` |
| `PHP_UPLOAD_MAX_FILESIZE` | Макс. размер загрузки | `100M` |
| `PHP_MAX_EXECUTION_TIME` | Макс. время выполнения | `120` |

### SSL/TLS конфигурация

Для включения HTTPS раскомментируйте в `.env`:

```bash
VIRTUAL_HOST=teampass.example.com
LETSENCRYPT_HOST=teampass.example.com
LETSENCRYPT_EMAIL=admin@example.com
CERT_NAME=teampass.example.com
```

---

## ☸️ Helm Chart

Развёртывание TeamPass в Kubernetes с помощью Helm.

### Требования

- Kubernetes 1.21+
- Helm 3.0+
- StorageClass с поддержкой динамического выделения

### Установка

#### Базовая установка (development)

```bash
helm install teampass ./helm-chart/teampass \
  --namespace teampass \
  --create-namespace
```

#### Production-установка

```bash
helm install teampass ./helm-chart/teampass \
  --namespace teampass \
  --create-namespace \
  -f helm-chart/teampass/values-production.yaml
```

#### С внешним MySQL/MariaDB

```bash
helm install teampass ./helm-chart/teampass \
  --namespace teampass \
  --create-namespace \
  --set mariadb.enabled=false \
  --set externalDatabase.enabled=true \
  --set externalDatabase.host=mysql.example.com \
  --set externalDatabase.password=your-password
```

### Конфигурация Helm

| Параметр | Описание | По умолчанию |
|----------|----------|--------------|
| `image.tag` | Версия TeamPass | `3.1.6.7` |
| `service.type` | Тип сервиса | `ClusterIP` |
| `ingress.enabled` | Включить Ingress | `false` |
| `mariadb.enabled` | Развернуть MariaDB | `true` |
| `teampass.installMode` | Режим установки | `manual` |
| `autoscaling.enabled` | Включить HPA | `false` |
| `resources.requests.memory` | Запрос памяти | `256Mi` |
| `resources.limits.memory` | Лимит памяти | `512M` |

### Управление релизом

```bash
# Обновление релиза
helm upgrade teampass ./helm-chart/teampass -n teampass

# Просмотр статуса
helm status teampass -n teampass

# Удаление
helm uninstall teampass -n teampass

# Проверка шаблонов
helm template teampass ./helm-chart/teampass -n teampass
```

Подробная документация: [`helm-chart/teampass/README.md`](helm-chart/teampass/README.md)

---

## 🔒 Безопасность

### Рекомендации

1. **Смените пароли по умолчанию** перед развёртыванием в production
2. **Используйте HTTPS** — настройте SSL/TLS сертификаты
3. **Ограничьте доступ к сети** — контейнеры используют изолированную сеть
4. **Регулярно создавайте резервные копии** томов `teampass-db` и `teampass-sk`
5. **Обновляйте образы** до последних стабильных версий

### Резервное копирование

```bash
# Экспорт базы данных
docker compose exec db mysqldump -u teampass -p teampass > backup.sql

# Копирование томов
docker run --rm -v teampass-sk:/data -v $(pwd):/backup alpine tar czf /backup/sk-backup.tar.gz /data
docker run --rm -v teampass-files:/data -v $(pwd):/backup alpine tar czf /backup/files-backup.tar.gz /data
```

---

## 🔧 Устранение неполадок

### Распространённые проблемы

| Проблема | Решение |
|----------|---------|
| Контейнер не запускается | Проверьте `.env` на наличие всех обязательных переменных |
| Ошибка подключения к БД | Убедитесь, что `DB_PASSWORD` совпадает с `MARIADB_PASSWORD` |
| Ошибки прав доступа | Проверьте владельца томов: `chown -R www-data:www-data` |
| Превышено время ожидания | Увеличьте `PHP_MAX_EXECUTION_TIME` в `.env` |

### Просмотр логов

```bash
# Все логи
docker compose logs

# Лог приложения
docker compose logs teampass

# Лог базы данных
docker compose logs db

# В реальном времени
docker compose logs -f
```

### Доступ к контейнерам

```bash
# В контейнер приложения
docker compose exec teampass bash

# В контейнер базы данных
docker compose exec db bash

# MySQL CLI
docker compose exec db mysql -u teampass -p
```

### Полный сброс

> ⚠️ **Внимание:** Удалит все данные!

```bash
docker compose down -v
docker compose up -d
```

---

## 📁 Структура проекта

```
TeamPass/
├── docker-compose.yml       # Основная конфигурация Docker Compose
├── .env.example             # Шаблон переменных окружения
├── .env                     # Активные переменные (не коммитить)
├── README.md                # Эта документация
├── QWEN.md                  # Дополнительная документация
├── helm-chart/              # Helm Chart для Kubernetes
│   └── teampass/
│       ├── Chart.yaml       # Метаданные чарта
│       ├── values.yaml      # Значения по умолчанию
│       ├── values-example.yaml
│       ├── values-production.yaml
│       ├── README.md        # Документация Helm
│       ├── .helmignore
│       ├── charts/          # Зависимости чарта
│       └── templates/       # Kubernetes манифесты
└── docker/
    └── mariadb/
        └── custom.cnf       # Кастомная конфигурация MariaDB
```

---

## 📚 Дополнительные ресурсы

- [Официальный сайт TeamPass](https://teampass.net/)
- [Документация TeamPass](https://github.com/teampass/teampass)
- [Docker Compose документация](https://docs.docker.com/compose/)
- [Helm документация](https://helm.sh/docs/)

---

## 📄 Лицензия

TeamPass распространяется под лицензией GPL v3. Данный Docker-проект предоставляется «как есть» без каких-либо гарантий.
