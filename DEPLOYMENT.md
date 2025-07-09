# Database Operator Deployment Guide

This guide explains how to deploy the Database Operator Helm chart directly from GitHub.

## 🚀 Quick Deployment

### Method 1: Direct GitHub Installation

```bash
# Install directly from GitHub main branch
helm install database-operator \
  https://github.com/selvarajmurugesan90/database-operator/archive/refs/heads/main.tar.gz \
  --namespace database-ops \
  --create-namespace
```

### Method 2: Clone and Install

```bash
# Clone the repository
git clone https://github.com/selvarajmurugesan90/database-operator.git
cd database-operator

# Install with custom values
helm install database-operator . \
  --namespace database-ops \
  --create-namespace \
  -f values.yaml
```

### Method 3: Specific Version/Tag

```bash
# Install a specific version (replace v2.0.0 with desired tag)
helm install database-operator \
  https://github.com/selvarajmurugesan90/database-operator/archive/refs/tags/v2.0.0.tar.gz \
  --namespace database-ops \
  --create-namespace
```

## 📝 Configuration

### Basic PostgreSQL Setup

Create a `my-values.yaml` file:

```yaml
# Enable PostgreSQL operations
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

secrets:
  database-credentials:
    create: true
    data:
      POSTGRES_USERNAME: "YWRtaW4="  # admin (base64)
      POSTGRES_PASSWORD: "cGFzc3dvcmQ="  # password (base64)
```

Then deploy:

```bash
helm install database-operator \
  https://github.com/selvarajmurugesan90/database-operator/archive/refs/heads/main.tar.gz \
  --namespace database-ops \
  --create-namespace \
  -f my-values.yaml
```

## 🔧 ArgoCD Deployment

Create an ArgoCD Application:

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
        - values-example.yaml
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

## 📊 Verification

After deployment, verify the installation:

```bash
# Check all resources
kubectl get all -n database-ops

# Check specific resources
kubectl get jobs,cronjobs,secrets,pvc -n database-ops

# View logs
kubectl logs -l app.kubernetes.io/name=database-operator -n database-ops
```

## 🔄 Updates

### Update to Latest Version

```bash
# Update from GitHub
helm upgrade database-operator \
  https://github.com/selvarajmurugesan90/database-operator/archive/refs/heads/main.tar.gz \
  --namespace database-ops \
  -f my-values.yaml
```

### Update with Local Changes

```bash
# Pull latest changes
git pull origin main

# Upgrade with local chart
helm upgrade database-operator . \
  --namespace database-ops \
  -f my-values.yaml
```

## 🗑️ Uninstallation

```bash
# Remove the Helm release
helm uninstall database-operator -n database-ops

# Optionally, remove PVCs (careful - this deletes data!)
kubectl delete pvc -l app.kubernetes.io/name=database-operator -n database-ops

# Remove namespace
kubectl delete namespace database-ops
```

## 🛠️ Troubleshooting

### Common Issues

1. **Image Pull Errors**:
   ```bash
   # Check image availability
   docker pull postgres:15-alpine
   docker pull liquibase/liquibase:4.25
   ```

2. **Permission Issues**:
   ```bash
   # Check RBAC
   kubectl auth can-i create jobs --as=system:serviceaccount:database-ops:database-operator
   ```

3. **Storage Issues**:
   ```bash
   # Check storage classes
   kubectl get storageclass
   
   # Check PVC status
   kubectl get pvc -n database-ops
   ```

### Debug Commands

```bash
# Validate chart before installation
helm template database-operator . --debug

# Check deployment status
helm status database-operator -n database-ops

# Get deployment history
helm history database-operator -n database-ops
```

## 📚 Examples

The repository includes comprehensive examples in the `examples/` directory:

- `postgresql-example.yaml` - PostgreSQL setup
- `mysql-example.yaml` - MySQL configuration
- `mongodb-example.yaml` - MongoDB operations
- `arangodb-example.yaml` - ArangoDB setup
- `timescaledb-example.yaml` - TimescaleDB with time-series features
- `multi-database-example.yaml` - Multiple databases in one deployment

Use these as starting points for your configuration:

```bash
helm install database-operator \
  https://github.com/selvarajmurugesan90/database-operator/archive/refs/heads/main.tar.gz \
  --namespace database-ops \
  --create-namespace \
  -f examples/postgresql-example.yaml
```