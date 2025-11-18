# Architecture Overview

## Introduction

The Database Operator is a universal Helm chart designed to manage database operations in Kubernetes. It provides a flexible, reusable framework for schema management, automated backups, and maintenance tasks across multiple database types.

## Core Design Principles

### 1. **Universal Template Pattern**
The chart uses a single set of Kubernetes templates that can be configured for multiple database types (PostgreSQL, MySQL, MongoDB, ArangoDB, TimescaleDB). This approach:
- Reduces code duplication
- Ensures consistent behavior across database types
- Simplifies maintenance and updates
- Provides a unified configuration interface

### 2. **Dynamic Resource Generation**
Templates use Helm's range functionality to dynamically generate Kubernetes resources based on values configuration:
- Jobs are created by iterating over `.Values.jobs`
- CronJobs are created by iterating over `.Values.cronJobs`
- Secrets, ConfigMaps, and PVCs follow the same pattern
- Each iteration creates an independent Kubernetes resource

### 3. **Separation of Concerns**
The architecture separates different operational concerns:
- **Schema Management**: One-time or on-demand schema migrations
- **Backup Operations**: Scheduled database backups with retention policies
- **Maintenance Tasks**: Periodic optimization and cleanup operations
- **Custom Operations**: User-defined scripts and tasks

## Directory Structure

```
database-operator/
├── Chart.yaml                 # Helm chart metadata
├── values.yaml               # Default configuration values
├── values-example.yaml       # Example configuration
├── templates/                # Kubernetes resource templates
│   ├── _helpers.tpl         # Template helper functions
│   ├── job.yaml             # Job resource template
│   ├── cronjob.yaml         # CronJob resource template
│   ├── secret.yaml          # Secret resource template
│   ├── sealedsecret.yaml    # SealedSecret resource template
│   ├── configmap.yaml       # ConfigMap resource template
│   ├── pvc.yaml             # PersistentVolumeClaim template
│   ├── storageclass.yaml    # StorageClass template
│   ├── serviceaccount.yaml  # ServiceAccount template
│   └── rbac.yaml            # RBAC resources template
├── examples/                 # Example configurations per database
└── CONTRIBUTING.md          # Contribution guidelines
```

## Component Architecture

### Template Layer

#### _helpers.tpl
Contains reusable template functions that generate common Kubernetes object metadata:
- **database-operator.name**: Generates the chart name
- **database-operator.fullname**: Generates the full resource name
- **database-operator.chart**: Generates chart name and version string
- **database-operator.labels**: Generates standard Kubernetes labels
- **database-operator.selectorLabels**: Generates selector labels for resources
- **database-operator.serviceAccountName**: Determines the service account name

#### job.yaml
Creates Kubernetes Job resources for one-time operations:
- **Purpose**: Schema migrations, one-time scripts, data imports
- **Input**: `.Values.jobs` map where each key becomes a Job
- **Features**: 
  - Configurable restart policies
  - Security contexts (pod and container level)
  - Resource limits and requests
  - Volume mounts for scripts and data
  - Environment variable injection from secrets/configmaps

#### cronjob.yaml
Creates Kubernetes CronJob resources for scheduled operations:
- **Purpose**: Automated backups, periodic maintenance, scheduled reports
- **Input**: `.Values.cronJobs` map where each key becomes a CronJob
- **Features**:
  - Flexible scheduling with cron expressions
  - Timezone support
  - Concurrency policies (Allow, Forbid, Replace)
  - Job history limits
  - Suspension capability
  - All features from job.yaml template

#### secret.yaml / sealedsecret.yaml
Manages credentials and sensitive configuration:
- **secret.yaml**: Creates standard Kubernetes Secrets
- **sealedsecret.yaml**: Creates SealedSecrets for GitOps workflows
- **Purpose**: Database credentials, API keys, certificates
- **Features**:
  - Base64 encoding for standard secrets
  - Encrypted data for sealed secrets
  - Type specification (Opaque, TLS, etc.)

#### configmap.yaml
Stores non-sensitive configuration data:
- **Purpose**: Schema files, scripts, configuration files
- **Features**:
  - Multiple data entries per ConfigMap
  - Binary data support
  - Can be mounted as files or environment variables

#### pvc.yaml
Creates PersistentVolumeClaims for data storage:
- **Purpose**: Backup storage, temporary data, shared volumes
- **Features**:
  - Dynamic storage class selection
  - Access mode configuration
  - Storage size specification
  - Volume mode (Filesystem or Block)

#### serviceaccount.yaml / rbac.yaml
Manages security and access control:
- **ServiceAccount**: Creates identity for pods
- **RBAC**: Creates Role/ClusterRole and RoleBinding/ClusterRoleBinding
- **Purpose**: Principle of least privilege access
- **Features**:
  - Configurable permissions
  - Namespace or cluster scope
  - Annotation support (for workload identity)

## Data Flow

### Schema Management Flow
```
values.yaml (jobs config)
    ↓
job.yaml template processes config
    ↓
Kubernetes Job created
    ↓
Pod executes schema migration
    ↓
Connects to database using credentials from Secret
    ↓
Applies schema changes (Liquibase/Flyway/custom)
    ↓
Job completes (Success/Failure)
```

### Backup Flow
```
values.yaml (cronJobs config)
    ↓
cronjob.yaml template processes config
    ↓
Kubernetes CronJob created
    ↓
At scheduled time, Job pod created
    ↓
Pod executes backup command (pg_dump/mysqldump/mongodump)
    ↓
Backup written to PersistentVolume
    ↓
Old backups cleaned up based on retention policy
    ↓
Job completes and is retained per history limit
```

## Configuration Strategy

### Three-Layer Configuration Model

#### 1. Global Defaults (values.yaml)
- Chart-wide settings (timezone, security contexts)
- Default resource limits
- Common RBAC rules
- Shared image pull secrets

#### 2. Database-Specific Configuration (values.yaml: databases)
- Connection parameters (host, port, database name)
- Database type and version
- SSL/TLS settings
- Tool selection (liquibase vs flyway)

#### 3. Operation-Specific Configuration (values.yaml: jobs/cronJobs)
- Job/CronJob definitions
- Image and command specification
- Schedule (for CronJobs)
- Resource requirements
- Volume mounts and environment variables

### Configuration Precedence
Job/CronJob specific settings override database defaults, which override global defaults:
```
Global Defaults < Database Config < Job/CronJob Config
```

## Security Architecture

### Defense in Depth Approach

#### 1. Container Security
- Non-root user execution (runAsNonRoot: true)
- Dropped Linux capabilities (drop: ["ALL"])
- No privilege escalation (allowPrivilegeEscalation: false)
- Read-only root filesystem where possible

#### 2. RBAC and Service Accounts
- Dedicated service account per deployment
- Minimal required permissions
- Namespace-scoped by default
- Optional cluster-scoped roles for advanced use cases

#### 3. Secret Management
- Support for native Kubernetes Secrets
- Integration with SealedSecrets for GitOps
- Separation of credentials from configuration
- No default credentials in values.yaml

#### 4. Network Security
- Database credentials never exposed in logs
- Support for SSL/TLS connections
- Compatible with NetworkPolicies (users must configure separately)

## Extension Points

### Adding Support for New Databases

The architecture makes it easy to add new database types:

1. **Add database configuration** in values.yaml under `databases:` section
2. **Define jobs** for schema management in `jobs:` section
3. **Define cronjobs** for backups/maintenance in `cronJobs:` section
4. **Create example** file in `examples/` directory
5. **Update documentation** in README.md

No template changes are required - existing templates handle the new configuration automatically.

### Custom Operations

Users can define custom operations without modifying the chart:

```yaml
jobs:
  custom-data-import:
    enabled: true
    image:
      repository: mycompany/custom-importer
      tag: "1.0.0"
    command: ["/bin/sh"]
    args: ["-c", "python import_data.py"]
    envFrom:
      - secretRef:
          name: database-credentials
    volumeMounts:
      - name: data
        mountPath: /data
```

## Resource Lifecycle

### Job Lifecycle
1. **Creation**: Helm install/upgrade creates Job resource
2. **Execution**: Kubernetes scheduler creates pod
3. **Completion**: Pod runs to completion (success/failure)
4. **Retention**: Job retained per backoffLimit
5. **Cleanup**: Manual deletion or TTL-based cleanup (ttlSecondsAfterFinished)

### CronJob Lifecycle
1. **Creation**: Helm install/upgrade creates CronJob resource
2. **Scheduling**: CronJob controller monitors schedule
3. **Job Creation**: At scheduled time, creates Job from template
4. **Execution**: Job executes as described above
5. **History Management**: Old Jobs cleaned up per successfulJobsHistoryLimit/failedJobsHistoryLimit
6. **Suspension**: CronJob can be suspended without deletion

## Monitoring and Observability

### Built-in Observability Features

#### Job Status Tracking
- Kubernetes Job status shows success/failure
- Completion time and duration
- Pod logs available via kubectl logs

#### Annotations for Prometheus
Jobs and CronJobs can include annotations for Prometheus scraping:
```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9187"
```

#### Events
Kubernetes events provide information about:
- Job creation and completion
- Pod scheduling issues
- Volume mount failures
- Image pull problems

### Integration Points

#### Metrics Export
Jobs can include sidecar containers for metrics export:
- postgres_exporter for PostgreSQL metrics
- mysqld_exporter for MySQL metrics
- mongodb_exporter for MongoDB metrics

#### Log Aggregation
Jobs write to stdout/stderr, integrating with:
- Kubernetes logging infrastructure
- FluentD/Fluent Bit
- Elasticsearch/Loki

## Performance Considerations

### Resource Optimization

#### CPU and Memory
- Schema jobs: typically low CPU, moderate memory
- Backup jobs: moderate CPU, memory depends on database size
- Maintenance jobs: variable based on operation type

#### Storage
- Backup PVCs should be sized for retention policy
- Use separate PVCs for different backup jobs
- Consider storage class performance characteristics

### Concurrency Control

#### Job Parallelism
Jobs run sequentially by default (parallelism: 1)

#### CronJob Concurrency
CronJobs use concurrencyPolicy to prevent overlapping executions:
- **Forbid**: Prevents concurrent runs (recommended for backups)
- **Allow**: Allows concurrent runs (useful for read-only operations)
- **Replace**: Cancels existing run and starts new one

## Failure Handling

### Retry Logic

#### Job Retries
- Controlled by `backoffLimit` (default: 3)
- Exponential backoff between retries
- Final failure after exceeding limit

#### Pod Restarts
- Controlled by `restartPolicy` (default: OnFailure)
- Options: OnFailure, Never
- Always is not supported for Jobs

### Error Recovery

#### Debugging Failed Jobs
1. Check job status: `kubectl describe job <name>`
2. View pod logs: `kubectl logs job/<name>`
3. Check events: `kubectl get events`
4. Verify secrets and configmaps exist
5. Test database connectivity

#### Common Failure Scenarios
- **Image pull failures**: Verify image exists and pull secrets
- **Permission errors**: Check RBAC and service account
- **Connection timeouts**: Verify database host and network policies
- **Schema errors**: Validate SQL/migration files
- **Disk full**: Check PVC capacity and limits

## Upgrade Strategy

### Helm Chart Upgrades

#### Safe Upgrade Process
1. **Backup** current values.yaml
2. **Review** changelog for breaking changes
3. **Test** in non-production environment
4. **Upgrade** with `helm upgrade` command
5. **Verify** resources are updated correctly
6. **Rollback** if issues occur: `helm rollback`

#### Handling Breaking Changes
- Major version changes may require configuration updates
- Review migration guide in CHANGELOG.md
- Test in development before production upgrade
- Consider blue-green deployment for critical systems

## Best Practices

### Configuration Management
1. **Version control** all values.yaml files
2. **Use GitOps** for production deployments (ArgoCD, FluxCD)
3. **Separate** sensitive data using SealedSecrets or external secret managers
4. **Document** custom configurations in comments

### Security Hardening
1. **Enable** all security contexts
2. **Use** dedicated service accounts with minimal permissions
3. **Rotate** database credentials regularly
4. **Audit** RBAC permissions periodically
5. **Enable** network policies to restrict pod communication

### Operational Excellence
1. **Monitor** job success rates and duration
2. **Alert** on backup failures
3. **Test** restore procedures regularly
4. **Document** runbook for common issues
5. **Automate** repetitive tasks where possible

### Testing Strategy
1. **Validate** chart with `helm lint`
2. **Test** template rendering with `helm template`
3. **Dry-run** installations before production
4. **Verify** in staging environment
5. **Monitor** first production deployment closely

## Troubleshooting Guide

### Quick Diagnostics

```bash
# Check all resources
kubectl get all -l app.kubernetes.io/name=database-operator

# View job logs
kubectl logs job/<job-name>

# Describe job for events
kubectl describe job/<job-name>

# Check secrets exist
kubectl get secrets

# Test database connectivity
kubectl run test-pod --rm -it --image=postgres:15-alpine -- psql -h <host> -U <user>
```

### Common Issues and Solutions

See README.md Troubleshooting section for detailed solutions.

## Future Enhancements

### Roadmap Items
- Operator pattern implementation with custom CRDs
- Automated disaster recovery procedures
- Multi-cluster backup replication
- Advanced monitoring dashboards
- Support for additional database types (Cassandra, Redis, etc.)
- Database health checks and automated remediation

---

This architecture is designed to be simple, extensible, and production-ready while maintaining flexibility for diverse database operation needs.
