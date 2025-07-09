# Database Operator Helm Chart

<div align="center">
  <img src="https://img.shields.io/badge/Kubernetes-1.19+-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes 1.19+"/>
  <img src="https://img.shields.io/badge/Helm-3.0+-0F1689?style=for-the-badge&logo=helm&logoColor=white" alt="Helm 3.0+"/>
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="MIT License"/>
</div>

<p align="center">
  <strong>A universal Helm chart for database operations including schema management, backups, and maintenance tasks</strong>
</p>

<p align="center">
  Supports PostgreSQL, TimescaleDB, MySQL, ArangoDB, MongoDB, and more!
</p>

## 🚀 Features

<table>
  <tr>
    <td width="33%">
      <h3 align="center">🗄️ Multi-Database Support</h3>
      <ul>
        <li>PostgreSQL & TimescaleDB</li>
        <li>MySQL & MariaDB</li>
        <li>ArangoDB & MongoDB</li>
        <li>Public Docker images</li>
      </ul>
    </td>
    <td width="33%">
      <h3 align="center">🔧 Schema Management</h3>
      <ul>
        <li>Liquibase integration</li>
        <li>Flyway support</li>
        <li>Custom migration scripts</li>
        <li>ConfigMap-based schemas</li>
      </ul>
    </td>
    <td width="33%">
      <h3 align="center">🔒 Enterprise Ready</h3>
      <ul>
        <li>Automated backups</li>
        <li>Security best practices</li>
        <li>RBAC integration</li>
        <li>GitOps compatible</li>
      </ul>
    </td>
  </tr>
</table>

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Database Support](#-database-support)
- [Examples](#-examples)
- [Security](#-security)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🏁 Quick Start

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Existing database instances

### Basic Installation

```bash
# Install directly from GitHub
helm install my-db-operator https://github.com/selvarajmurugesan90/database-operator/archive/refs/heads/main.tar.gz

# Or clone and install locally
git clone https://github.com/selvarajmurugesan90/database-operator.git
cd database-operator
helm install my-db-operator . -f values.yaml
```

### Enable PostgreSQL Operations

```yaml
# values.yaml
schemaJobs:
  enabled: true
  postgresql:
    enabled: true

backupJobs:
  enabled: true
  postgresql:
    enabled: true
    schedule: "0 2 * * *"

persistentVolumeClaims:
  backup-storage:
    enabled: true
    storage: 100Gi
```

## 🔧 Installation

### Method 1: Direct from GitHub

```bash
# Install directly from GitHub repository
helm install database-operator \
  https://github.com/selvarajmurugesan90/database-operator/archive/refs/heads/main.tar.gz \
  --namespace database-ops \
  --create-namespace \
  -f values.yaml
```

### Method 2: From Source

```bash
git clone https://github.com/selvarajmurugesan90/database-operator.git
cd database-operator
helm install database-operator . \
  --namespace database-ops \
  --create-namespace \
  -f values.yaml
```

### Method 3: ArgoCD (GitOps)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: database-operator
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/selvarajmurugesan90/database-operator
    targetRevision: HEAD
    path: .
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: database-ops
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## ⚙️ Configuration

The chart is highly configurable through the `values.yaml` file. Here are the main configuration sections:

### Database Configuration

```yaml
databases:
  postgresql:
    enabled: true
    host: postgresql-primary
    port: 5432
    database: myapp
    ssl: false
    schemaTool: liquibase
  
  mysql:
    enabled: true
    host: mysql-primary
    port: 3306
    database: myapp
    ssl: false
    schemaTool: liquibase
  
  mongodb:
    enabled: true
    host: mongodb-primary
    port: 27017
    database: myapp
    ssl: false
    schemaTool: custom
```

### Schema Management

```yaml
schemaJobs:
  enabled: true
  postgresql:
    enabled: true
    image:
      repository: liquibase/liquibase
      tag: "4.25"
    changelogFile: "db/changelog/db.changelog-master.xml"
    command: ["liquibase"]
    args:
      - "update"
      - "--url=jdbc:postgresql://$(DB_HOST):$(DB_PORT)/$(DB_NAME)"
      - "--username=$(DB_USER)"
      - "--password=$(DB_PASSWORD)"
      - "--changelog-file=$(CHANGELOG_FILE)"
```

### Backup Configuration

```yaml
backupJobs:
  enabled: true
  postgresql:
    enabled: true
    schedule: "0 2 * * *"  # Daily at 2 AM
    image:
      repository: postgres
      tag: "15-alpine"
    command: ["/bin/bash"]
    args:
      - -c
      - |
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME -F c -f /backup/postgresql_${DB_NAME}_${TIMESTAMP}.dump
        find /backup -name "postgresql_${DB_NAME}_*.dump" -type f -mtime +7 -delete
```

### Security Configuration

```yaml
serviceAccount:
  create: true
  annotations: {}

rbac:
  create: true

podSecurityContext:
  enabled: true
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

containerSecurityContext:
  enabled: true
  capabilities:
    drop: ["ALL"]
  allowPrivilegeEscalation: false
  runAsNonRoot: true
```

## 🗄️ Database Support

### PostgreSQL / TimescaleDB

- **Schema Management**: Liquibase, Flyway, or custom scripts
- **Backup**: pg_dump with compression
- **Maintenance**: VACUUM, ANALYZE, and compression (TimescaleDB)
- **Monitoring**: Connection stats, query performance

### MySQL / MariaDB

- **Schema Management**: Liquibase, Flyway, or custom scripts
- **Backup**: mysqldump with consistency options
- **Maintenance**: OPTIMIZE TABLE, index rebuilding
- **Monitoring**: Connection stats, slow query analysis

### MongoDB

- **Schema Management**: Custom scripts for collections and indexes
- **Backup**: mongodump with compression
- **Maintenance**: Index optimization, collection compaction
- **Monitoring**: Database stats, collection metrics

### ArangoDB

- **Schema Management**: Custom scripts for collections and graphs
- **Backup**: arangodump with compression
- **Maintenance**: Collection compaction, index optimization
- **Monitoring**: Database stats, query performance

## 🐳 Container Images

This chart uses public Docker images by default:

### Default Images
- **PostgreSQL/TimescaleDB**: `postgres:15-alpine`
- **MySQL**: `mysql:8.0`
- **MongoDB**: `mongo:7.0`
- **ArangoDB**: `arangodb/arangodb:3.11.5`
- **Liquibase**: `liquibase/liquibase:4.25`
- **Flyway**: `flyway/flyway:10.1`

### Custom Images
You can build custom images with pre-packaged schema files:

```dockerfile
# Example: Custom Liquibase image with schema files
FROM liquibase/liquibase:4.25
COPY db/changelog/ /liquibase/changelog/
```

```yaml
# Use custom image in values.yaml
schemaJobs:
  postgresql:
    image:
      repository: your-registry/custom-liquibase
      tag: "1.0.0"
```

### Schema Files via ConfigMaps
Alternatively, mount schema files using ConfigMaps:

```yaml
configMaps:
  database-scripts:
    enabled: true
    data:
      schema.sql: |
        CREATE TABLE users (
          id SERIAL PRIMARY KEY,
          name VARCHAR(100)
        );
```

## 📚 Examples

### PostgreSQL Example

```yaml
# Enable PostgreSQL operations
schemaJobs:
  enabled: true
  postgresql:
    enabled: true
    changelogFile: "db/changelog/postgresql.changelog-master.xml"

backupJobs:
  enabled: true
  postgresql:
    enabled: true
    schedule: "0 2 * * *"

maintenanceJobs:
  enabled: true
  postgresql:
    vacuum:
      enabled: true
      schedule: "0 3 * * 0"  # Weekly

secrets:
  database-credentials:
    data:
      POSTGRES_USERNAME: "YWRtaW4="  # admin
      POSTGRES_PASSWORD: "cGFzc3dvcmQ="  # password
```

### Multi-Database Example

```yaml
# Configure multiple databases
databases:
  postgresql:
    enabled: true
    host: postgresql-primary
    port: 5432
    database: myapp
  
  timescaledb:
    enabled: true
    host: timescaledb-primary
    port: 5432
    database: tsdb
  
  mongodb:
    enabled: true
    host: mongodb-primary
    port: 27017
    database: documents

# Enable operations for all databases
schemaJobs:
  enabled: true
  postgresql:
    enabled: true
  timescaledb:
    enabled: true

backupJobs:
  enabled: true
  postgresql:
    enabled: true
    schedule: "0 2 * * *"
  timescaledb:
    enabled: true
    schedule: "0 3 * * *"
  mongodb:
    enabled: true
    schedule: "0 4 * * *"
```

See the [examples](./examples/) directory for complete configuration examples for each database type.

## 🔒 Security

### Credentials Management

#### Option 1: Kubernetes Secrets

```yaml
secrets:
  database-credentials:
    create: true
    type: Opaque
    data:
      POSTGRES_USERNAME: "YWRtaW4="  # base64 encoded
      POSTGRES_PASSWORD: "cGFzc3dvcmQ="  # base64 encoded
```

#### Option 2: SealedSecrets (GitOps)

```yaml
secrets:
  database-credentials:
    create: false

sealedSecrets:
  database-credentials:
    enabled: true
    encryptedData:
      POSTGRES_USERNAME: "AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx..."
      POSTGRES_PASSWORD: "AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx..."
```

### Security Best Practices

- **Non-root containers**: All containers run as non-root user
- **Dropped capabilities**: All Linux capabilities are dropped
- **Read-only filesystem**: Where possible, containers use read-only filesystems
- **Network policies**: Implement network policies to restrict database access
- **RBAC**: Principle of least privilege for service accounts

## 📊 Monitoring

### Prometheus Integration

```yaml
# Add Prometheus annotations
jobs:
  postgresql-schema:
    podAnnotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "9187"
```

### Grafana Dashboards

The chart includes example Grafana dashboards for:
- Job execution metrics
- Database backup status
- Schema migration history
- Database performance metrics

### Alerting

Example AlertManager rules:
```yaml
groups:
- name: database-operator
  rules:
  - alert: DatabaseBackupFailed
    expr: kube_job_status_failed{job_name=~".*-backup-.*"} > 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Database backup job failed"
```

## 🛠️ Troubleshooting

### Common Issues

#### Job Failures

**Symptoms**: Job status shows as failed
```bash
# Check job logs
kubectl logs job/database-operator-postgresql-schema -n database-ops

# Check job status
kubectl describe job/database-operator-postgresql-schema -n database-ops
```

**Solutions**:
- Verify database connectivity
- Check credentials in secrets
- Validate schema files syntax
- Ensure proper RBAC permissions

#### Storage Issues

**Symptoms**: PVCs in Pending state
```bash
# Check PVC status
kubectl get pvc -n database-ops
kubectl describe pvc backup-storage -n database-ops
```

**Solutions**:
- Verify storage class exists
- Check available storage in cluster
- Ensure storage provisioner is working

#### Network Connectivity

**Symptoms**: Cannot connect to database
```bash
# Test connectivity from pod
kubectl run test-pod --image=postgres:15-alpine -it --rm -- psql -h postgresql-primary -U admin
```

**Solutions**:
- Check network policies
- Verify service discovery
- Ensure database is accessible from cluster

### Debug Commands

```bash
# Get all resources
kubectl get all -l app.kubernetes.io/name=database-operator -n database-ops

# Check recent events
kubectl get events --sort-by=.metadata.creationTimestamp -n database-ops

# Validate Helm chart
helm lint .
helm template . --debug

# Test chart installation
helm install test-release . --dry-run --debug
```

## 📈 Performance Tuning

### Resource Optimization

```yaml
# Optimize resource requests and limits
schemaJobs:
  defaults:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi

backupJobs:
  defaults:
    resources:
      requests:
        cpu: 200m
        memory: 256Mi
      limits:
        cpu: 1000m
        memory: 1Gi
```

### Concurrent Operations

```yaml
# Control job concurrency
backupJobs:
  defaults:
    concurrencyPolicy: Forbid  # Prevent overlapping backups
    backoffLimit: 3
    ttlSecondsAfterFinished: 86400
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/selvarajmurugesan90/database-operator.git
cd database-operator

# Install development dependencies
helm dependency update

# Run tests
helm test .

# Lint the chart
helm lint .
```

### Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Liquibase](https://www.liquibase.org/) for database schema management
- [Flyway](https://flywaydb.org/) for database migrations
- [Kubernetes](https://kubernetes.io/) for container orchestration
- [Helm](https://helm.sh/) for package management

## 📞 Support

- **Documentation**: [README.md](https://github.com/selvarajmurugesan90/database-operator/blob/main/README.md)
- **Email**: selvarajmurugesan90@gmail.com

## 🗺️ Roadmap

- [ ] Support for Redis operations
- [ ] Cassandra integration
- [ ] Automated disaster recovery
- [ ] Advanced monitoring dashboards
- [ ] Multi-cluster support
- [ ] Operator pattern implementation

---

<p align="center">
  <strong>⭐ Star us on GitHub — it helps!</strong>
</p>

<p align="center">
  Made with ❤️ by Selvaraj Murugesan
</p>