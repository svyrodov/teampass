# TeamPass Helm Chart

Helm chart для развёртывания **TeamPass** — менеджера паролей для команд — в Kubernetes.

## Обзор

Этот Helm chart развёртывает:
- **TeamPass Application** — PHP-приложение для управления паролями
- **MariaDB** — база данных (встроенная или внешняя)

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
| `image.repository` | Репозиторий образа TeamPass | `teampass/teampass` |
| `image.tag` | Тег образа | `3.1.5.2` |
| `service.type` | Тип сервиса | `ClusterIP` |
| `ingress.enabled` | Включить Ingress | `false` |
| `mariadb.enabled` | Включить встроенную MariaDB | `true` |
| `teampass.installMode` | Режим установки (manual/auto) | `manual` |

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
    persistence:
      size: 10Gi
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
    size: 5Gi
  upload:
    enabled: true
    storageClass: ""
    size: 5Gi
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

1. **Измените пароли по умолчанию** в `values.yaml`
2. **Включите HTTPS/TLS** через Ingress
3. **Используйте Secrets** для чувствительных данных
4. **Включите NetworkPolicy** для ограничения трафика
5. **Настройте PodSecurityContext** для ограничения прав
6. **Регулярно делайте бэкапы** PVC

### Пример безопасной конфигурации

```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  runAsNonRoot: true
  runAsUser: 1000

networkPolicy:
  enabled: true

podSecurityContext:
  fsGroup: 1000
  runAsNonRoot: true
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

### Development

```bash
helm install teampass ./teampass -f values.yaml
```

### Staging

```bash
helm install teampass ./teampass -f values-example.yaml
```

### Production

```bash
helm install teampass ./teampass -f values-production.yaml
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
# Проверка логов
kubectl logs -n teampass teampass-xxxxx

# Проверка событий
kubectl describe pod -n teampass teampass-xxxxx
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
```

## Лицензия

TeamPass распространяется под лицензией AGPL-3.0.

## Поддержка

- Документация TeamPass: https://teampass.net/
- GitHub: https://github.com/teampass/teampass
- Helm Charts: https://helm.sh/
