# TeamPass Helm Chart

## Project Overview

This directory contains a **Helm chart** for deploying **TeamPass** — a collaborative password manager for teams — on Kubernetes. The chart provides a complete deployment configuration with support for high availability, security hardening, and multi-environment setups.

### Custom Docker Image

**Important:** This chart uses a **custom Docker image** (`teampass-custom`) that fixes a critical permissions issue in the official TeamPass image:

| Component | Official Image | Custom Image |
|-----------|---------------|--------------|
| PHP-FPM user | `www-data` | `nginx` ✅ |
| PHP-FPM group | `www-data` | `nginx` ✅ |
| Nginx worker | `nginx` | `nginx` |
| Files owner | `nginx` | `nginx` |

The custom image ensures PHP-FPM and Nginx run under the same user (`nginx`), preventing "path not writable" errors.

**Build the custom image:**
```bash
cd teampass/docker
./build.sh
# Or manually:
docker build -t teampass-custom:3.1.6.7 -f Dockerfile .
```

See `docker/README.md` for details.

### Architecture

```
                    ┌─────────────────────────────────────┐
                    │         Kubernetes Cluster          │
                    │                                     │
┌──────────────┐    │  ┌─────────────────────────────┐   │
│   Users      │───▶│  │     TeamPass Deployment     │   │
│              │    │  │  ┌─────────┐ ┌─────────┐   │   │
│  (Browser)   │    │  │  │  Pod 1  │ │  Pod 2  │   │   │
│  (HTTPS)     │    │  │  │  :80    │ │  :80    │   │   │
└──────────────┘    │  │  └────┬────┘ └────┬────┘   │   │
        │           │  │       │           │        │   │
        ▼           │  │       └─────┬─────┘        │   │
┌──────────────┐    │  │             ▼              │   │
│   Ingress    │    │  │  ┌─────────────────────┐  │   │
│   (nginx)    │───▶│  │  │     Service:80      │  │   │
│   TLS Termination│  │  └──────────┬──────────┘  │   │
└──────────────┘    │  │             │             │   │
                    │  │    ┌────────┴────────┐   │   │
                    │  │    ▼                 ▼   │   │
                    │  │  ┌──────┐      ┌──────────┐│   │
                    │  │  │ PVC  │      │ MariaDB  ││   │
                    │  │  │ sk/  │      │ Stateful ││   │
                    │  │  │files/│      │  Set     ││   │
                    │  │  │upload│      │          ││   │
                    │  │  └──────┘      └──────────┘│   │
                    │  └─────────────────────────────┘   │
                    └─────────────────────────────────────┘
```

### Key Components

| Component | Description |
|-----------|-------------|
| **Deployment** | TeamPass PHP application with configurable replicas (2–10 with HPA) |
| **Service** | ClusterIP for internal traffic routing |
| **Ingress** | nginx ingress with TLS termination |
| **MariaDB** | Bitnami MariaDB subchart (embedded or external DB) |
| **PVCs** | Persistent storage for salt keys (1Gi), files (10Gi), and uploads (10Gi) |
| **ConfigMap** | Environment configuration for the application |
| **Secrets** | Database credentials and admin password |
| **HPA** | Horizontal Pod Autoscaler (2–10 replicas, 80% CPU/memory) |
| **PDB** | Pod Disruption Budget (minAvailable: 1) |
| **NetworkPolicy** | Optional network isolation rules |

### Chart Structure

```
teampass/
├── Chart.yaml              # Chart metadata and dependencies
├── Chart.lock              # Locked dependency versions
├── values.yaml             # Default configuration values
├── values-example.yaml     # Example configuration for staging
├── values-production.yaml  # Production-ready configuration
├── .helmignore             # Files to exclude from chart package
├── README.md               # User documentation
├── charts/                 # Chart dependencies (packed)
│   └── mariadb-25.0.0.tgz
└── templates/              # Kubernetes manifest templates
    ├── _helpers.tpl        # Template helper functions
    ├── deployment.yaml     # Main application deployment
    ├── service.yaml        # Service definition
    ├── ingress.yaml        # Ingress configuration
    ├── configmap.yaml      # ConfigMap with env vars
    ├── secret.yaml         # Secrets for credentials
    ├── pvc.yaml            # PersistentVolumeClaims
    ├── serviceaccount.yaml # ServiceAccount
    ├── hpa.yaml            # HorizontalPodAutoscaler
    ├── pdb.yaml            # PodDisruptionBudget
    ├── networkpolicy.yaml  # NetworkPolicy
    └── NOTES.txt           # Post-installation notes
```

## Building and Running

### Prerequisites

- **Kubernetes** 1.21+
- **Helm** 3.10+
- **PV Provisioner** (for persistent storage)

### Installation Commands

**Install with defaults (development):**
```bash
helm install teampass ./teampass --namespace teampass --create-namespace
```

**Install with example values (staging):**
```bash
helm install teampass ./teampass \
  --namespace teampass \
  --create-namespace \
  -f values-example.yaml
```

**Install with production values:**
```bash
helm install teampass ./teampass \
  --namespace teampass \
  --create-namespace \
  -f values-production.yaml
```

**Install with external database:**
```bash
helm install teampass ./teampass \
  --set mariadb.enabled=false \
  --set externalDatabase.enabled=true \
  --set externalDatabase.host=mysql.example.com \
  --set externalDatabase.password=SecurePassword
```

### Common Operations

| Command | Description |
|---------|-------------|
| `helm status teampass` | Check release status |
| `helm list -n teampass` | List releases in namespace |
| `helm upgrade teampass ./teampass -f values.yaml` | Upgrade release |
| `helm rollback teampass 1` | Rollback to revision 1 |
| `helm uninstall teampass` | Uninstall release |
| `helm test teampass` | Run post-installation tests |
| `helm template teampass ./teampass` | Render templates locally |
| `helm lint ./teampass` | Validate chart syntax |

### Accessing the Application

**Via port-forward (development):**
```bash
kubectl port-forward -n teampass svc/teampass 8080:80
# Open http://localhost:8080
```

**Via LoadBalancer:**
```bash
export SERVICE_IP=$(kubectl get svc -n teampass teampass -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://$SERVICE_IP"
```

**Via Ingress:**
```bash
# Configure ingress in values.yaml
# Access at https://teampass.example.com
```

## Configuration Reference

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Docker image repository (use `teampass-custom` for fixed permissions) | `teampass-custom` |
| `image.tag` | Image tag (use SHA256 for production) | `3.1.6.7` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Registry pull secrets | `[]` |

**Note:** The custom image `teampass-custom` fixes PHP-FPM permissions by running as `nginx` user instead of `www-data`. See `docker/README.md` for build instructions.

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `80` |
| `service.annotations` | Service annotations | `{}` |

### Resources Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.requests.memory` | Memory request | `512Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.limits.memory` | Memory limit | `1Gi` |
| `resources.limits.cpu` | CPU limit | `1000m` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class | `nginx` |
| `ingress.annotations` | Ingress annotations | `{proxy-body-size: "100m", proxy-read-timeout: "120"}` |
| `ingress.hosts` | Host routing rules | `[teampass.example.com]` |
| `ingress.tls` | TLS configuration | `[teampass-tls]` |

### Database Configuration

**Embedded MariaDB:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `mariadb.enabled` | Deploy MariaDB | `true` |
| `mariadb.architecture` | `standalone` or `replication` | `standalone` |
| `mariadb.auth.database` | Database name | `teampass` |
| `mariadb.auth.username` | Database user | `teampass` |
| `mariadb.primary.persistence.size` | DB storage size | `20Gi` |
| `mariadb.primary.replicaCount` | Number of replicas | `1` |
| `mariadb.primary.startupProbe.initialDelaySeconds` | Startup probe delay | `30` |
| `mariadb.primary.livenessProbe.initialDelaySeconds` | Liveness probe delay | `120` |
| `mariadb.primary.readinessProbe.initialDelaySeconds` | Readiness probe delay | `30` |
| `mariadb.primary.resources.requests.memory` | Memory request | `512Mi` |
| `mariadb.primary.resources.limits.memory` | Memory limit | `1Gi` |
| `mariadb.primary.fips.openssl` | OpenSSL FIPS mode | `off` |

**External Database:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `externalDatabase.enabled` | Use external DB | `false` |
| `externalDatabase.host` | Database host | `""` |
| `externalDatabase.port` | Database port | `3306` |
| `externalDatabase.database` | Database name | `teampass` |
| `externalDatabase.user` | Database user | `teampass` |
| `externalDatabase.password` | Database password | `""` |

### TeamPass Application

| Parameter | Description | Default |
|-----------|-------------|---------|
| `teampass.installMode` | `manual` or `auto` | `auto` |
| `teampass.adminEmail` | Admin email | `admin@example.com` |
| `teampass.adminPassword` | Admin password | `ChangeMeToSecurePassword123!` |
| `teampass.url` | Application URL | `https://teampass.box72.ru` |
| `teampass.php.memoryLimit` | PHP memory limit | `512M` |
| `teampass.php.uploadMaxFilesize` | Max upload size | `100M` |
| `teampass.php.maxExecutionTime` | Max execution time | `120` |
| `teampass.dbPrefix` | Database table prefix | `teampass_` |

### Persistent Storage

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.sk.enabled` | Enable salt keys storage | `true` |
| `persistence.sk.size` | Salt keys storage size | `1Gi` |
| `persistence.files.enabled` | Enable files storage | `true` |
| `persistence.files.size` | Files storage size | `10Gi` |
| `persistence.upload.enabled` | Enable upload storage | `true` |
| `persistence.upload.size` | Upload storage size | `10Gi` |
| `persistence.*.storageClass` | Storage class ("" = default) | `""` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | CPU target | `80` |
| `autoscaling.targetMemoryUtilizationPercentage` | Memory target | `80` |

### Health Checks

| Parameter | Description | Default |
|-----------|-------------|---------|
| `healthCheck.enabled` | Enable health checks | `true` |
| `healthCheck.path` | Health endpoint | `/health` |
| `healthCheck.initialDelaySeconds` | Initial delay | `60` |
| `healthCheck.periodSeconds` | Check interval | `30` |
| `healthCheck.timeoutSeconds` | Timeout | `10` |
| `healthCheck.failureThreshold` | Failure threshold | `3` |

### Network Policy

| Parameter | Description | Default |
|-----------|-------------|---------|
| `networkPolicy.enabled` | Enable network isolation | `false` |

### Pod Disruption Budget

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pdb.enabled` | Enable PDB | `true` |
| `pdb.minAvailable` | Minimum available pods | `1` |

## Development Conventions

### Values File Hierarchy

1. **`values.yaml`** — Base defaults (development)
2. **`values-example.yaml`** — Staging configuration with Ingress, TLS, HPA
3. **`values-production.yaml`** — Production hardening
4. **Custom values files** — Environment-specific overrides

### Example Configuration (values-example.yaml)

The `values-example.yaml` file provides a ready-to-use staging configuration:

```yaml
# Key features:
# - Ingress with nginx and TLS
# - Autoscaling (2-10 replicas)
# - Resource limits (512Mi-1Gi memory, 250m-1000m CPU)
# - MariaDB with custom probes and 20Gi storage
# - Persistent storage: sk (1Gi), files (10Gi), upload (10Gi)
# - Auto-installation mode with secure admin password
# - PDB with minAvailable: 1
```

### Security Best Practices

1. **Use SHA256 image tags** for reproducible deployments
2. **Enable NetworkPolicy** for network isolation
3. **Configure PodSecurityContext** for least privilege
4. **Use TLS/HTTPS** via Ingress in production
5. **Enable PDB** for high availability
6. **Set resource limits** to prevent resource exhaustion
7. **Use external secrets** management for sensitive data

### Production Checklist

- [ ] Change default passwords
- [ ] Enable TLS/HTTPS (configure Ingress with TLS)
- [ ] Configure NetworkPolicy
- [ ] Set resource limits (requests: 512Mi/250m, limits: 1Gi/1000m)
- [ ] Enable autoscaling (min: 2, max: 10)
- [ ] Configure PDB (minAvailable: 1)
- [ ] Enable security contexts
- [ ] Set up monitoring/alerting
- [ ] Configure backups for PVCs
- [ ] Configure MariaDB probes (startup: 30s, liveness: 120s, readiness: 30s)
- [ ] Increase storage for files/uploads (10Gi each)

### Template Helpers

The `_helpers.tpl` file provides reusable template functions:

| Helper | Description |
|--------|-------------|
| `teampass.name` | Chart name |
| `teampass.fullname` | Full release name |
| `teampass.chart` | Chart name and version |
| `teampass.labels` | Common labels |
| `teampass.selectorLabels` | Selector labels |
| `teampass.serviceAccountName` | ServiceAccount name |
| `teampass.databaseHost` | Database host (embedded or external) |
| `teampass.databasePort` | Database port |
| `teampass.databaseName` | Database name |
| `teampass.databaseUser` | Database user |
| `teampass.databasePassword` | Database password |
| `teampass.ingress.apiVersion` | Correct Ingress API version |
| `teampass.deployment.apiVersion` | Deployment API version |
| `teampass.pdb.apiVersion` | PDB API version |

## Troubleshooting

### MariaDB Liveness Probe Fails with "Access Denied"

**Problem:** MariaDB liveness probe fails with `Access denied for user 'root'@'localhost'`.

**Cause:** Bitnami MariaDB chart uses password files for health checks. When passwords are auto-generated, the probe may fail during initial startup.

**Solution:** Increase `initialDelaySeconds` for liveness probe to allow MariaDB to fully initialize:

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

### MariaDB Crashes with Exit Code 137

**Problem:** MariaDB container crashes with exit code 137 (OOM or signal).

**Cause:** OpenSSL FIPS mode can cause crashes in some Kubernetes environments (e.g., Yandex Cloud).

**Solution:** Disable FIPS mode:

```yaml
mariadb:
  primary:
    fips:
      openssl: "off"
```

### Init Container Waits Indefinitely for Database

**Problem:** TeamPass init container `wait-for-db` waits indefinitely.

**Cause:** MariaDB is still initializing or network policy blocks connections.

**Solution:**
1. Check MariaDB logs: `kubectl logs -n teampass teampass-mariadb-0`
2. Verify MariaDB is listening: `kubectl exec -n teampass teampass-mariadb-0 -- ps aux | grep mariadbd`
3. Check network policies: `kubectl get networkpolicy -n teampass`

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n teampass

# Describe pod for events
kubectl describe pod -n teampass teampass-xxxxx

# Check logs
kubectl logs -n teampass teampass-xxxxx
```

### PVC Issues

```bash
# Check PVC status
kubectl get pvc -n teampass

# Describe PVC
kubectl describe pvc -n teampass teampass-sk

# Check storage class
kubectl get storageclass
```

## Testing

```bash
# Run chart lint
helm lint ./teampass

# Template rendering test
helm template teampass ./teampass

# Dry-run installation
helm install teampass ./teampass --dry-run --debug

# Run post-installation tests
helm test teampass -n teampass
```

## File Structure Summary

| File | Purpose |
|------|---------|
| `Chart.yaml` | Chart metadata, version, dependencies |
| `values.yaml` | Default configuration values |
| `values-example.yaml` | Example staging configuration |
| `values-production.yaml` | Production-hardened configuration |
| `.helmignore` | Files excluded from chart package |
| `templates/deployment.yaml` | Main application deployment |
| `templates/service.yaml` | Kubernetes Service |
| `templates/ingress.yaml` | Ingress resource |
| `templates/configmap.yaml` | ConfigMap with environment variables |
| `templates/secret.yaml` | Secrets for credentials |
| `templates/pvc.yaml` | PersistentVolumeClaims |
| `templates/hpa.yaml` | HorizontalPodAutoscaler |
| `templates/pdb.yaml` | PodDisruptionBudget |
| `templates/networkpolicy.yaml` | NetworkPolicy |
| `templates/serviceaccount.yaml` | ServiceAccount |
| `templates/_helpers.tpl` | Template helper functions |
| `templates/NOTES.txt` | Post-installation information |
| `templates/tests/test-connection.yaml` | Connection test |
