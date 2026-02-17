# TeamPass Docker Deployment

## Project Overview

This directory contains a Docker Compose configuration for deploying **TeamPass** — a collaborative password manager designed for teams. The setup uses:

- **TeamPass Application** (v3.1.5.2) — PHP-based password manager
- **MariaDB** (v11.2) — Database backend
- **Docker Compose** (v3.8) — Container orchestration

### Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   TeamPass      │────▶│    MariaDB      │
│   (PHP/App)     │     │    (Database)   │
│   Port: 8080    │     │    Port: 3306   │
└─────────────────┘     └─────────────────┘
       │                        │
       ▼                        ▼
  [teampass-network]      [teampass-db volume]
```

### Key Components

| Service | Image | Purpose |
|---------|-------|---------|
| `teampass` | `teampass/teampass:latest` | Main application container |
| `db` | `mariadb:11.2` | Database server |

### Volumes

| Volume | Mount Path | Purpose |
|--------|------------|---------|
| `teampass-sk` | `/var/www/html/sk` | Salt keys (encryption) |
| `teampass-files` | `/var/www/html/files` | Stored files |
| `teampass-upload` | `/var/www/html/upload` | Upload directory |
| `teampass-db` | `/var/lib/mysql` | Database persistence |

## Building and Running

### Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+

### Initial Setup

1. **Create environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Configure environment variables:**
   Edit `.env` and set secure passwords:
   - `DB_PASSWORD` — Database user password
   - `MARIADB_ROOT_PASSWORD` — MariaDB root password
   - `ADMIN_PWD` — Admin password (if using auto-install)

3. **Start the services:**
   ```bash
   docker compose up -d
   ```

4. **Access TeamPass:**
   Open `http://localhost:8080` in your browser.

### Common Commands

| Command | Description |
|---------|-------------|
| `docker compose up -d` | Start services in detached mode |
| `docker compose down` | Stop and remove containers |
| `docker compose logs -f` | Follow logs |
| `docker compose ps` | Show running containers |
| `docker compose restart` | Restart all services |
| `docker compose exec teampass bash` | Enter application container |
| `docker compose exec db bash` | Enter database container |

### Installation Modes

**Manual Installation (default):**
```bash
INSTALL_MODE=manual
```
Complete setup via web browser at `http://localhost:8080`.

**Automated Installation:**
```bash
INSTALL_MODE=auto
ADMIN_EMAIL=admin@teampass.local
ADMIN_PWD=YourSecurePassword
```

## Development Conventions

### Environment Variables

- Use `.env` for local configuration (never commit)
- Reference `.env.example` as template
- Generate secure passwords: `openssl rand -base64 32`

### Security Best Practices

1. **Change default passwords** in `.env` before deployment
2. **Use HTTPS** in production (configure via SSL section in `.env.example`)
3. **Restrict network access** — containers use isolated `teampass-network`
4. **Regular backups** — backup `teampass-db` and `teampass-sk` volumes

### Health Checks

- **TeamPass:** HTTP check on `/health` endpoint (30s interval)
- **MariaDB:** Innodb connection check (10s interval)

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Container won't start | Check `.env` for required variables |
| Database connection failed | Verify `DB_PASSWORD` matches `MARIADB_PASSWORD` |
| Permission errors | Ensure volumes have correct ownership |

### Logs

```bash
# View all logs
docker compose logs

# View specific service
docker compose logs teampass
docker compose logs db
```

### Reset Installation

```bash
docker compose down -v  # Remove volumes (WARNING: deletes all data)
docker compose up -d
```

## File Structure

```
TeamPass/
├── docker-compose.yml    # Main Docker Compose configuration
├── .env.example          # Environment template
├── .env                  # Active environment (gitignored)
├── helm-chart/           # Helm chart for Kubernetes
│   └── teampass/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-example.yaml
│       ├── values-production.yaml
│       ├── README.md
│       ├── .helmignore
│       ├── charts/           # Chart dependencies
│       └── templates/        # Kubernetes manifests
└── QWEN.md               # This documentation
```

## Helm Chart

### Quick Start

```bash
# Install with defaults (development)
helm install teampass ./helm-chart/teampass --namespace teampass --create-namespace

# Install with production values
helm install teampass ./helm-chart/teampass \
  --namespace teampass \
  --create-namespace \
  -f helm-chart/teampass/values-production.yaml

# Install with external database
helm install teampass ./helm-chart/teampass \
  --set mariadb.enabled=false \
  --set externalDatabase.enabled=true \
  --set externalDatabase.host=mysql.example.com
```

### Configuration Files

| File | Purpose |
|------|---------|
| `values.yaml` | Default configuration |
| `values-example.yaml` | Example configuration with common settings |
| `values-production.yaml` | Production-ready configuration with HA |

### Key Helm Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.tag` | TeamPass version | `3.1.5.2` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `ingress.enabled` | Enable Ingress | `false` |
| `mariadb.enabled` | Deploy MariaDB | `true` |
| `teampass.installMode` | Installation mode | `manual` |
| `autoscaling.enabled` | Enable HPA | `false` |

See `helm-chart/teampass/README.md` for complete documentation.
