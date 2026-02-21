# TeamPass Helm Chart

Helm chart для развёртывания **TeamPass** — менеджера паролей для команд — в Kubernetes.

## Обзор

Этот Helm chart развёртывает:
- **TeamPass Application** — PHP-приложение для управления паролями с поддержкой масштабирования (2–10 реплик)
- **MariaDB** — база данных (встроенная или внешняя)
- **Ingress** — nginx ingress с TLS termination
- **HPA** — автоматическое масштабирование по CPU/памяти
- **PVC** — постоянное хранилище для salt keys, файлов и загрузок

### Кастомный Docker-образ

**Важно:** Этот chart использует **кастомный Docker-образ** (`teampass-custom`), который исправляет критическую проблему прав доступа в официальном образе TeamPass:

| Компонент | Официальный образ | Кастомный образ |
|-----------|-------------------|-----------------|
| PHP-FPM пользователь | `www-data` | `nginx` ✅ |
| PHP-FPM группа | `www-data` | `nginx` ✅ |
| Nginx worker | `nginx` | `nginx` |
| Владелец файлов | `nginx` | `nginx` |

Кастомный образ обеспечивает работу PHP-FPM и Nginx под одним пользователем (`nginx`), предотвращая ошибки "path not writable".

**Сборка кастомного образа:**
```bash
cd docker
./build.sh
# Или вручную:
docker build -t teampass-custom:latest-alpine3.21 -f Dockerfile .

# Загрузка в GitHub Container Registry:
docker tag teampass-custom:latest-alpine3.21 ghcr.io/your-username/teampass-custom:latest-alpine3.21
docker push ghcr.io/your-username/teampass-custom:latest-alpine3.21
```

См. `docker/README.md` для подробностей.

## Требования

- Kubernetes 1.21+
- Helm 3.10+
- PV provisioner (для постоянного хранения)

## Установка

### Добавление репозитория (если опубликован)

```bash
helm repo add teampass https://charts.example.com
helm repo update
```

### Локальная установка

```bash
# Установка с значениями по умолчанию
helm install teampass ./teampass

# Установка с кастомными значениями
helm install teampass ./teampass -f values-custom.yaml

# Установка в определённый namespace
helm install teampass ./teampass -n teampass --create-namespace
```

### Примеры установки

**Базовая установка (разработка):**
```bash
helm install teampass ./teampass --namespace teampass --create-namespace
```

**Продакшен установка:**
```bash
helm install teampass ./teampass \
  --namespace teampass \
  --create-namespace \
  -f values-production.yaml
```

**С внешней базой данных:**
```bash
helm install teampass ./teampass \
  --set mariadb.enabled=false \
  --set externalDatabase.enabled=true \
  --set externalDatabase.host=mysql.example.com \
  --set externalDatabase.password=SecurePassword
```

## Конфигурация

Смотрите `values.yaml` для всех доступных опций.

### Основные параметры

| Параметр | Описание | Значение по умолчанию |
|----------|----------|----------------------|
| `image.repository` | Репозиторий образа TeamPass | `teampass-custom` |
| `image.tag` | Тег образа | `3.1.5.2` |
| `service.type` | Тип сервиса | `ClusterIP` |
| `ingress.enabled` | Включить Ingress | `true` |
| `ingress.className` | Ingress класс | `nginx` |
| `mariadb.enabled` | Включить встроенную MariaDB | `true` |
| `teampass.installMode` | Режим установки (manual/auto) | `auto` |
| `autoscaling.enabled` | Включить HPA | `true` |
| `autoscaling.minReplicas` | Минимум реплик | `2` |
| `autoscaling.maxReplicas` | Максимум реплик | `10` |
| `resources.requests.memory` | Запрос памяти | `512Mi` |
| `resources.limits.memory` | Лимит памяти | `1Gi` |

**Примечание:** Кастомный образ `teampass-custom` исправляет права доступа PHP-FPM, запуская его от пользователя `nginx` вместо `www-data`. См. `docker/README.md`.

### Параметры базы данных

**Встроенная MariaDB:**
```yaml
mariadb:
  enabled: true
  architecture: standalone
  auth:
    database: teampass
    username: teampass
    password: ""  # Авто-генерация
    rootPassword: ""  # Авто-генерация
  primary:
    replicaCount: 1
    persistence:
      size: 20Gi
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "1000m"
    startupProbe:
      enabled: true
      initialDelaySeconds: 30
    livenessProbe:
      enabled: true
      initialDelaySeconds: 120
    readinessProbe:
      enabled: true
      initialDelaySeconds: 30
```

**Внешняя база данных:**
```yaml
mariadb:
  enabled: false

externalDatabase:
  enabled: true
  host: mysql.example.com
  port: 3306
  database: teampass
  user: teampass
  password: SecurePassword
  prefix: teampass_
```

### Параметры TeamPass

```yaml
teampass:
  installMode: auto  # или manual
  adminEmail: admin@example.com
  adminPassword: SecurePassword
  url: https://teampass.example.com
  php:
    memoryLimit: 512M
    uploadMaxFilesize: 100M
    maxExecutionTime: 120
  dbPrefix: teampass_
```

### Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

### Resources

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Persistent Storage

```yaml
persistence:
  sk:
    enabled: true
    storageClass: ""
    size: 1Gi
  files:
    enabled: true
    storageClass: ""
    size: 10Gi
  upload:
    enabled: true
    storageClass: ""
    size: 10Gi
```

### Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "120"
  hosts:
    - host: teampass.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: teampass-tls
      hosts:
        - teampass.example.com
```

### Pod Disruption Budget

```yaml
pdb:
  enabled: true
  minAvailable: 1
```

### Health Checks

```yaml
healthCheck:
  enabled: true
  path: /health
  initialDelaySeconds: 60
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3
```

## Проверка установки

```bash
# Проверка статуса релиза
helm status teampass

# Проверка подов
kubectl get pods -n teampass

# Проверка сервисов
kubectl get svc -n teampass

# Просмотр логов
kubectl logs -n teampass -l app.kubernetes.io/name=teampass -f
```

## Запуск тестов

```bash
# Запуск тестов подключения
helm test teampass
```

## Обновление

```bash
# Обновление релиза
helm upgrade teampass ./teampass -f values-custom.yaml

# Обновление с просмотром изменений
helm upgrade teampass ./teampass -f values-custom.yaml --dry-run --debug

# Откат к предыдущей версии
helm rollback teampass 1
```

## Удаление

```bash
# Удаление релиза
helm uninstall teampass

# Удаление с PVC (осторожно: данные будут удалены!)
helm uninstall teampass
kubectl pvc delete -n teampass -l app.kubernetes.io/instance=teampass
```

## Доступ к приложению

### Через port-forward (разработка)

```bash
kubectl port-forward -n teampass svc/teampass 8080:80
```

Откройте `http://localhost:8080` в браузере.

### Через Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: teampass.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Через LoadBalancer

```yaml
service:
  type: LoadBalancer
```

```bash
export SERVICE_IP=$(kubectl get svc -n teampass teampass -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://$SERVICE_IP"
```

## Безопасность

### Рекомендации для продакшена

1. **Измените пароли по умолчанию** в `values.yaml` или используйте внешние Secrets
2. **Включите HTTPS/TLS** через Ingress (включено по умолчанию в `values-example.yaml`)
3. **Используйте Secrets** для чувствительных данных
4. **Включите NetworkPolicy** для ограничения трафика
5. **Настройте PodSecurityContext** для ограничения прав
6. **Регулярно делайте бэкапы** PVC
7. **Настройте мониторинг** за состоянием подов и базы данных
8. **Используйте SHA256 теги** образов для воспроизводимости развёртываний

### Пример безопасной конфигурации

```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  runAsNonRoot: true
  runAsUser: 1000

podSecurityContext:
  fsGroup: 1000
  runAsNonRoot: true

networkPolicy:
  enabled: true

resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

## Мониторинг и диагностика

### Health Checks

```yaml
healthCheck:
  enabled: true
  path: /health
  initialDelaySeconds: 60
  periodSeconds: 30
```

### Просмотр событий

```bash
kubectl get events -n teampass --sort-by='.lastTimestamp'
```

### Проверка здоровья подов

```bash
kubectl describe pod -n teampass -l app.kubernetes.io/name=teampass
```

## Multi-Environment Configuration

### Development (разработка)

Минимальная конфигурация для локальной разработки:

```bash
helm install teampass ./teampass -n teampass --create-namespace
```

### Staging (тестирование)

Конфигурация с Ingress, TLS и автоскейлингом:

```bash
helm install teampass ./teampass \
  -f values-example.yaml \
  -n teampass \
  --create-namespace
```

**Особенности конфигурации:**
- Ingress с nginx и TLS
- Autoscaling (2–10 реплик)
- Resource limits (512Mi–1Gi память, 250m–1000m CPU)
- MariaDB с кастомными probe'ами и 20Gi хранилищем
- PVC: sk (1Gi), files (10Gi), upload (10Gi)
- Auto-installation режим
- PDB с minAvailable: 1

### Production (продакшен)

Полностью настроенная конфигурация для продакшена:

```bash
helm install teampass ./teampass \
  -f values-production.yaml \
  -n teampass \
  --create-namespace
```

## Структура chart

```
teampass/
├── Chart.yaml              # Метаданные chart
├── values.yaml             # Значения по умолчанию
├── values-example.yaml     # Пример конфигурации
├── values-production.yaml  # Продакшен конфигурация
├── .helmignore             # Игнорируемые файлы
├── templates/
│   ├── _helpers.tpl        # Вспомогательные шаблоны
│   ├── deployment.yaml     # Deployment приложения
│   ├── service.yaml        # Service
│   ├── ingress.yaml        # Ingress
│   ├── configmap.yaml      # ConfigMap
│   ├── secret.yaml         # Secrets
│   ├── pvc.yaml            # PersistentVolumeClaims
│   ├── serviceaccount.yaml # ServiceAccount
│   ├── hpa.yaml            # HorizontalPodAutoscaler
│   ├── pdb.yaml            # PodDisruptionBudget
│   ├── networkpolicy.yaml  # NetworkPolicy
│   ├── NOTES.txt           # Пост-установочные заметки
│   └── tests/
│       └── test-connection.yaml  # Тест подключения
```

## Устранение неполадок

### Pod не запускается

```bash
# Проверка статуса подов
kubectl get pods -n teampass

# Проверка логов
kubectl logs -n teampass teampass-xxxxx

# Проверка событий
kubectl describe pod -n teampass teampass-xxxxx
```

### MariaDB не запускается

**Проблема:** Liveness probe fails с "Access denied"

**Решение:** Увеличьте `initialDelaySeconds` для liveness probe:

```yaml
mariadb:
  primary:
    livenessProbe:
      initialDelaySeconds: 120
    readinessProbe:
      initialDelaySeconds: 30
    startupProbe:
      initialDelaySeconds: 30
      failureThreshold: 30
```

**Проблема:** Exit code 137 (OOM или сигнал)

**Решение:** Отключите FIPS mode для OpenSSL:

```yaml
mariadb:
  primary:
    fips:
      openssl: "off"
```

### Init container ждёт базу данных

```bash
# Проверка логов MariaDB
kubectl logs -n teampass teampass-mariadb-0

# Проверка доступности БД
kubectl exec -n teampass teampass-mariadb-0 -- mysqladmin ping -u root
```

### Ошибки подключения к базе данных

```bash
# Проверка секретов
kubectl get secret -n teampass teampass-mariadb -o yaml

# Проверка подключения к БД
kubectl exec -n teampass teampass-xxxxx -- env | grep DB_
```

### Проблемы с PVC

```bash
# Проверка PVC
kubectl get pvc -n teampass

# Описание PVC
kubectl describe pvc -n teampass teampass-sk

# Проверка storage class
kubectl get storageclass
```

### HPA не масштабирует

```bash
# Проверка HPA
kubectl get hpa -n teampass

# Проверка метрик
kubectl top pods -n teampass
```

## Кастомный Docker-образ

### Почему кастомный образ?

В официальном образе `teampass/teampass`:
- **Nginx** работает от `nginx`
- **PHP-FPM** работает от `www-data`
- **Файлы** принадлежат `nginx:nginx`

Это вызывает ошибки прав доступа — PHP-FPM не может писать в каталоги `sk/`, `files/`, `upload/`.

### Решение

Используем кастомный образ на базе `php:8.3-fpm-alpine3.21` (свежий, без уязвимостей):

```dockerfile
FROM php:8.3-fpm-alpine3.21

# Копирование файлов из официального образа TeamPass
COPY --from=teampass/teampass:latest /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=teampass/teampass:latest /var/www/html /var/www/html

# Исправление пользователя PHP-FPM
RUN sed -i 's/^user = .*/user = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^group = .*/group = nginx/' /usr/local/etc/php-fpm.d/www.conf
```

### Сборка образа

```bash
cd docker
./build.sh

# Или вручную:
docker build -t teampass-custom:latest-alpine3.21 -f Dockerfile .

# Загрузка в GitHub Container Registry:
docker tag teampass-custom:latest-alpine3.21 ghcr.io/your-username/teampass-custom:latest-alpine3.21
docker push ghcr.io/your-username/teampass-custom:latest-alpine3.21
```

### Проверка

```bash
# Проверка пользователя PHP-FPM
docker run --rm teampass-custom:latest-alpine3.21 \
  grep -E "^user =|^group =" /usr/local/etc/php-fpm.d/www.conf

# Ожидаемый вывод:
# user = nginx
# group = nginx

# Проверка версии Alpine
docker run --rm teampass-custom:latest-alpine3.21 cat /etc/alpine-release

# Сканирование на уязвимости (требуется trivy)
trivy image teampass-custom:latest-alpine3.21
```

См. `docker/README.md` для подробностей.

## Лицензия

TeamPass распространяется под лицензией AGPL-3.0.

## Поддержка

- Документация TeamPass: https://teampass.net/
- GitHub: https://github.com/teampass/teampass
- Helm Charts: https://helm.sh/
