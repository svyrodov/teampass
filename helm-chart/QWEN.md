# TeamPass Helm Chart

## Project Overview

This directory contains a **Helm chart** for deploying **TeamPass** — a collaborative password manager for teams — on Kubernetes. The chart provides a complete, production-ready deployment configuration with support for high availability, security hardening, and multi-environment setups.

### Architecture

```
                    ┌─────────────────────────────────────┐
                    │         Kubernetes Cluster          │
                    │                                     │
┌──────────────┐    │  ┌─────────────────────────────┐   │
│   Users      │───▶│  │     TeamPass Deployment     │   │
│              │    │  │  ┌─────────┐ ┌─────────┐   │   │
│  (Browser)   │    │  │  │  Pod 1  │ │  Pod 2  │   │   │
└──────────────┘    │  │  │  :80    │ │  :80    │   │   │
                    │  │  └────┬────┘ └────┬────┘   │   │
                    │  │       │           │        │   │
                    │  │       └─────┬─────┘        │   │
                    │  │             ▼              │   │
                    │  │  ┌─────────────────────┐  │   │
                    │  │  │     Service:80      │  │   │
                    │  │  └──────────┬──────────┘  │   │
                    │  │             │             │   │
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
| **Deployment** | TeamPass PHP application with configurable replicas |
| **Service** | ClusterIP/NodePort/LoadBalancer for traffic routing |
| **Ingress** | Optional ingress with TLS support |
| **MariaDB** | Bitnami MariaDB subchart (embedded or external DB) |
| **PVCs** | Persistent storage for salt keys, files, and uploads |
| **ConfigMap** | Environment configuration for the application |
| **Secrets** | Database credentials and admin password |
| **HPA** | Horizontal Pod Autoscaler for scaling |
| **PDB** | Pod Disruption Budget for high availability |
| **NetworkPolicy** | Network isolation rules |

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

**Add Helm repository (if published):**
```bash
helm repo add teampass https://charts.example.com
helm repo update
```

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
  --set externalDatabase.port=3306 \
  --set externalDatabase.database=teampass \
  --set externalDatabase.user=teampass \
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
| `image.repository` | Docker image repository | `teampass/teampass` |
| `image.tag` | Image tag (SHA256 recommended) | `sha256:6afa42c...` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Registry pull secrets | `[]` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `80` |
| `service.annotations` | Service annotations | `{}` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class | `nginx` |
| `ingress.hosts` | Host routing rules | `[teampass.local]` |
| `ingress.tls` | TLS configuration | `[]` |

### Database Configuration

**Embedded MariaDB:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `mariadb.enabled` | Deploy MariaDB | `true` |
| `mariadb.architecture` | `standalone` or `replication` | `standalone` |
| `mariadb.auth.database` | Database name | `teampass` |
| `mariadb.auth.username` | Database user | `teampass` |
| `mariadb.primary.persistence.size` | DB storage size | `10Gi` |

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
| `teampass.installMode` | `manual` or `auto` | `manual` |
| `teampass.adminEmail` | Admin email | `admin@teampass.local` |
| `teampass.adminPassword` | Admin password | `""` (auto-generated) |
| `teampass.url` | Application URL | `http://localhost` |
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
| `persistence.files.size` | Files storage size | `5Gi` |
| `persistence.upload.enabled` | Enable upload storage | `true` |
| `persistence.upload.size` | Upload storage size | `5Gi` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `5` |
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

## Development Conventions

### Values File Hierarchy

1. **`values.yaml`** — Base defaults (development)
2. **`values-example.yaml`** — Staging/example configuration
3. **`values-production.yaml`** — Production hardening
4. **Custom values files** — Environment-specific overrides

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
- [ ] Enable TLS/HTTPS
- [ ] Configure NetworkPolicy
- [ ] Set resource limits
- [ ] Enable autoscaling
- [ ] Configure PDB
- [ ] Enable security contexts
- [ ] Set up monitoring/alerting
- [ ] Configure backups for PVCs

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

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n teampass

# Describe pod for events
kubectl describe pod -n teampass teampass-xxxxx

# Check logs
kubectl logs -n teampass teampass-xxxxx
```

### Database Connection Issues

```bash
# Check MariaDB pod
kubectl get pods -n teampass -l app.kubernetes.io/name=mariadb

# Check database secret
kubectl get secret -n teampass teampass-mariadb -o jsonpath='{.data.mariadb-password}' | base64 -d

# Verify environment variables
kubectl exec -n teampass teampass-xxxxx -- env | grep DB_
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

### Ingress Issues

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl get ingress -n teampass

# Describe ingress
kubectl describe ingress -n teampass teampass
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
