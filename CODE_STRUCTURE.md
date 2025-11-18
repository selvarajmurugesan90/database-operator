# Code Structure Documentation

## Overview

This document provides a detailed explanation of the codebase structure, file organization, and how different components work together in the Database Operator Helm chart.

## File Organization

### Root Directory

```
database-operator/
├── Chart.yaml               # Helm chart metadata and versioning
├── values.yaml             # Default configuration values (main config file)
├── values-example.yaml     # Example configuration with sample values
├── LICENSE                 # MIT license
├── README.md              # Main user documentation
├── ARCHITECTURE.md        # Architecture and design documentation
├── CODE_STRUCTURE.md      # This file - code organization guide
├── CONTRIBUTING.md        # Contribution guidelines
├── DEPLOYMENT.md          # Deployment guide and instructions
├── CHANGELOG.md           # Version history and changes
├── templates/             # Kubernetes resource templates (Helm templates)
└── examples/              # Example configurations per database type
```

## Core Configuration Files

### Chart.yaml

**Purpose**: Defines Helm chart metadata and dependencies

**Key Fields**:
- `name`: Chart name (database-operator)
- `version`: Chart version (follows semver)
- `appVersion`: Application version
- `description`: Short description of the chart
- `keywords`: Search keywords for chart repositories
- `maintainers`: Contact information for maintainers

**Usage**: Referenced by Helm during installation and registry publishing

### values.yaml

**Purpose**: Primary configuration file containing all default values

**Structure** (586 lines):

```yaml
# Global Settings (lines 1-46)
- nameOverride, fullnameOverride
- timezone
- imagePullSecrets
- Security contexts (pod and container level)
- Service account configuration
- RBAC rules

# Database Configurations (lines 48-200+)
- databases:
  - postgresql: Connection params, schema tool, backup, maintenance
  - timescaledb: TimescaleDB-specific settings
  - mysql: MySQL/MariaDB settings
  - mongodb: MongoDB settings
  - arangodb: ArangoDB settings

# Schema Management Jobs (lines 200-300+)
- jobs: One-time schema migration jobs
  - Per-database job definitions
  - Image, command, args configuration
  - Resource limits and requests

# Scheduled Operations (lines 300-450+)
- cronJobs: Scheduled backup and maintenance jobs
  - Per-database cronjob definitions
  - Schedule expressions
  - Retention policies

# Resource Definitions (lines 450-586)
- secrets: Database credentials
- sealedSecrets: Encrypted secrets for GitOps
- configMaps: Schema files and scripts
- persistentVolumeClaims: Storage for backups
- storageClasses: Custom storage classes
```

**Configuration Philosophy**:
- Organized by operational concern (databases, jobs, cronjobs, etc.)
- Database-specific sections for each supported database type
- Defaults set to `enabled: false` for safety
- All sensitive data externalized to secrets

## Templates Directory

### _helpers.tpl

**Purpose**: Reusable template functions and macros

**Length**: 100+ lines

**Key Functions**:

```go
{{- define "database-operator.name" -}}
// Returns the chart name, with optional override
// Used in: All resource metadata
```

```go
{{- define "database-operator.fullname" -}}
// Returns the full resource name (release-name-chart-name)
// Truncated to 63 characters for Kubernetes naming requirements
// Used in: All resource names
```

```go
{{- define "database-operator.chart" -}}
// Returns chart name and version (e.g., database-operator-2.0.0)
// Used in: Chart version labels
```

```go
{{- define "database-operator.labels" -}}
// Returns standard Kubernetes labels:
// - helm.sh/chart
// - app.kubernetes.io/name
// - app.kubernetes.io/instance
// - app.kubernetes.io/version
// - app.kubernetes.io/managed-by
// Used in: All resource metadata
```

```go
{{- define "database-operator.selectorLabels" -}}
// Returns minimal labels for pod selectors
// Used in: Service selectors, pod selectors
```

```go
{{- define "database-operator.serviceAccountName" -}}
// Returns the service account name (created or custom)
// Used in: Pod specs requiring service account
```

**Pattern**: All helper functions follow Helm naming conventions with namespace prefix

### job.yaml

**Purpose**: Creates Kubernetes Job resources for one-time operations

**Length**: 100+ lines

**Template Logic Flow**:

```
1. Check if .Values.jobs is defined
   ↓
2. Iterate over each job in .Values.jobs
   ↓
3. For each job where enabled: true
   ↓
4. Generate Job resource with:
   - Metadata (name, labels, annotations)
   - Pod template spec
   - Container spec (image, command, args)
   - Security contexts
   - Resource limits
   - Environment variables
   - Volume mounts
   ↓
5. Apply backoffLimit and TTL settings
```

**Key Features**:
- **Dynamic naming**: Supports generateName for unique jobs
- **Version labeling**: Adds version label when generateName is true
- **Security**: Applies pod and container security contexts
- **Flexibility**: Supports envFrom (secrets/configmaps) and env (inline vars)
- **Storage**: Supports volume mounts for scripts and data

**Example Job Structure**:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-operator-postgresql-schema
  labels: { ... }
spec:
  template:
    spec:
      serviceAccountName: database-operator
      securityContext: { ... }
      containers:
      - name: postgresql-schema
        image: liquibase/liquibase:4.25
        command: ["liquibase"]
        args: ["update", "--url=...", ...]
        envFrom:
        - secretRef:
            name: database-credentials
  backoffLimit: 3
```

### cronjob.yaml

**Purpose**: Creates Kubernetes CronJob resources for scheduled operations

**Length**: 120+ lines

**Template Logic Flow**:

```
1. Check if .Values.cronJobs is defined
   ↓
2. Iterate over each cronjob in .Values.cronJobs
   ↓
3. For each cronjob where enabled: true
   ↓
4. Generate CronJob resource with:
   - Metadata (name, labels, annotations)
   - Schedule configuration
   - Job template (inherits all job.yaml features)
   - Concurrency policy
   - History limits
   ↓
5. Configure timezone and deadline settings
```

**Key Features**:
- **Scheduling**: Cron expression with timezone support
- **Concurrency control**: Forbid, Allow, or Replace concurrent runs
- **History management**: Configurable success/failed job history limits
- **Deadline**: startingDeadlineSeconds for delayed executions
- **Suspension**: Can pause without deletion
- **Inherits all job.yaml features**: Security, resources, volumes, etc.

**Example CronJob Structure**:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-operator-postgresql-backup
  labels: { ... }
spec:
  schedule: "0 2 * * *"
  timeZone: "UTC"
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgresql-backup
            image: postgres:15-alpine
            command: ["/bin/bash"]
            args: ["-c", "pg_dump ..."]
```

### secret.yaml

**Purpose**: Creates Kubernetes Secret resources for sensitive data

**Length**: ~30 lines

**Template Logic**:

```
1. Check if .Values.secrets is defined
   ↓
2. Iterate over each secret in .Values.secrets
   ↓
3. For each secret where create: true
   ↓
4. Generate Secret resource with:
   - Type (Opaque, TLS, etc.)
   - Data (base64-encoded values)
   - Labels and annotations
```

**Key Features**:
- **Conditional creation**: Only creates if `create: true`
- **Type support**: Supports all Kubernetes secret types
- **Base64 encoding**: Data must be pre-encoded in values.yaml

**Example Secret Structure**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
type: Opaque
data:
  POSTGRES_USERNAME: YWRtaW4=  # admin
  POSTGRES_PASSWORD: cGFzc3dvcmQ=  # password
```

### sealedsecret.yaml

**Purpose**: Creates SealedSecret resources for GitOps workflows

**Length**: ~30 lines

**Template Logic**:

```
1. Check if .Values.sealedSecrets is defined
   ↓
2. Iterate over each sealed secret
   ↓
3. For each sealed secret where enabled: true
   ↓
4. Generate SealedSecret resource with:
   - Encrypted data
   - Template for resulting Secret
   - Labels and annotations
```

**Key Features**:
- **GitOps safe**: Encrypted data can be committed to version control
- **Controller integration**: Requires SealedSecrets controller in cluster
- **Same interface**: Becomes regular Secret after decryption

**Example SealedSecret Structure**:
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: database-credentials
spec:
  encryptedData:
    POSTGRES_USERNAME: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQ...
    POSTGRES_PASSWORD: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQ...
```

### configmap.yaml

**Purpose**: Creates ConfigMap resources for non-sensitive configuration

**Length**: ~25 lines

**Template Logic**:

```
1. Check if .Values.configMaps is defined
   ↓
2. Iterate over each configmap
   ↓
3. For each configmap where enabled: true
   ↓
4. Generate ConfigMap resource with:
   - Data (text files, scripts, config files)
   - Binary data (optional)
   - Labels and annotations
```

**Key Features**:
- **Multiple entries**: Each ConfigMap can contain multiple files
- **Binary support**: Supports binaryData field for non-text content
- **Volume mounting**: Can be mounted as files or environment variables

**Example ConfigMap Structure**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: database-scripts
data:
  schema.sql: |
    CREATE TABLE users (
      id SERIAL PRIMARY KEY,
      username VARCHAR(100)
    );
  migration.sql: |
    ALTER TABLE users ADD COLUMN email VARCHAR(255);
```

### pvc.yaml

**Purpose**: Creates PersistentVolumeClaim resources for storage

**Length**: ~30 lines

**Template Logic**:

```
1. Check if .Values.persistentVolumeClaims is defined
   ↓
2. Iterate over each PVC
   ↓
3. For each PVC where enabled: true
   ↓
4. Generate PVC resource with:
   - Storage class
   - Access modes
   - Storage size
   - Labels and annotations
```

**Key Features**:
- **Dynamic provisioning**: Uses storage classes for automatic provisioning
- **Access modes**: ReadWriteOnce, ReadOnlyMany, ReadWriteMany
- **Size specification**: Configurable storage capacity

**Example PVC Structure**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 100Gi
```

### storageclass.yaml

**Purpose**: Creates StorageClass resources for custom storage configuration

**Length**: ~30 lines

**Template Logic**:

```
1. Check if .Values.storageClasses is defined
   ↓
2. Iterate over each storage class
   ↓
3. For each storage class where enabled: true
   ↓
4. Generate StorageClass resource with:
   - Provisioner
   - Parameters
   - Reclaim policy
   - Volume binding mode
```

**Key Features**:
- **Custom provisioners**: Supports any Kubernetes storage provisioner
- **Parameters**: Provisioner-specific configuration
- **Reclaim policies**: Delete or Retain
- **Binding modes**: Immediate or WaitForFirstConsumer

### serviceaccount.yaml

**Purpose**: Creates ServiceAccount resources for pod identity

**Length**: ~20 lines

**Template Logic**:

```
1. Check if .Values.serviceAccount.create is true
   ↓
2. Generate ServiceAccount resource with:
   - Name (custom or generated)
   - Annotations (for workload identity)
   - Labels
```

**Key Features**:
- **Conditional creation**: Only creates if `create: true`
- **Custom naming**: Supports custom name override
- **Annotations**: Support for cloud provider workload identity

### rbac.yaml

**Purpose**: Creates RBAC resources (Role/ClusterRole and bindings)

**Length**: ~40 lines

**Template Logic**:

```
1. Check if .Values.rbac.create is true
   ↓
2. Determine scope (Role vs ClusterRole)
   ↓
3. Generate RBAC resources with:
   - Role/ClusterRole with rules
   - RoleBinding/ClusterRoleBinding
   - Service account reference
```

**Key Features**:
- **Scope control**: Namespace or cluster-scoped permissions
- **Rule configuration**: Configurable API groups, resources, verbs
- **Least privilege**: Default rules are minimal

**Example RBAC Structure**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: database-operator
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

## Examples Directory

### Purpose
Provides complete, working configuration examples for each database type.

### Files

1. **postgresql-example.yaml**
   - PostgreSQL schema management with Liquibase
   - Daily backups with pg_dump
   - Weekly VACUUM and daily ANALYZE

2. **timescaledb-example.yaml**
   - TimescaleDB hypertable management
   - Compression policy setup
   - Data retention configuration

3. **mysql-example.yaml**
   - MySQL schema management with Flyway
   - mysqldump backups
   - Table optimization

4. **mongodb-example.yaml**
   - MongoDB collection management
   - mongodump backups
   - Index optimization

5. **arangodb-example.yaml**
   - ArangoDB graph database operations
   - arangodump backups
   - Collection compaction

6. **multi-database-example.yaml**
   - Demonstrates managing multiple databases simultaneously
   - Shows how to configure different databases in one chart

### Usage Pattern

```bash
# Use an example as a starting point
helm install my-db-operator . -f examples/postgresql-example.yaml

# Customize by overriding specific values
helm install my-db-operator . \
  -f examples/postgresql-example.yaml \
  --set schemaJobs.postgresql.image.tag=4.26
```

## Template Rendering Process

### Helm Template Rendering Flow

```
1. Load Chart.yaml and values.yaml
   ↓
2. Merge user-provided values (via -f or --set)
   ↓
3. Process templates in alphabetical order
   ↓
4. For each template:
   a. Parse template syntax
   b. Execute template functions
   c. Evaluate conditionals (if/range)
   d. Substitute values
   e. Apply helper functions
   ↓
5. Generate Kubernetes YAML manifests
   ↓
6. Validate generated YAML
   ↓
7. Apply to cluster (if not dry-run)
```

### Example: Job Template Processing

Given this configuration:
```yaml
jobs:
  postgresql-schema:
    enabled: true
    image:
      repository: liquibase/liquibase
      tag: "4.25"
    command: ["liquibase"]
    args: ["update"]
```

Template processing:
```go
{{- if .Values.jobs }}  // TRUE - jobs is defined
{{- range $name, $job := .Values.jobs }}  // Iterate: $name="postgresql-schema"
{{- if $job.enabled }}  // TRUE - enabled is true

apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "database-operator.fullname" $ }}-{{ $name }}
  // Evaluates to: "database-operator-postgresql-schema"
  
  labels:
    {{- include "database-operator.labels" $ | nindent 4 }}
    // Inserts standard labels with 4-space indent
    
spec:
  template:
    spec:
      containers:
        - name: {{ $name }}  // "postgresql-schema"
          image: "{{ $job.image.repository }}:{{ $job.image.tag | default "1.0.0" }}"
          // Evaluates to: "liquibase/liquibase:4.25"
          
          command:
            {{- toYaml $job.command | nindent 12 }}
            // Converts to YAML with 12-space indent
```

## Configuration Patterns

### Pattern 1: Per-Database Configuration

Each database type has its own section:

```yaml
databases:
  postgresql:
    enabled: true
    host: postgresql-primary
    # ... postgres-specific config
    
  mysql:
    enabled: true
    host: mysql-primary
    # ... mysql-specific config
```

### Pattern 2: Operation-Based Configuration

Operations are organized by type:

```yaml
# One-time operations
jobs:
  postgresql-schema:
    # ... job config
    
# Scheduled operations
cronJobs:
  postgresql-backup:
    # ... cronjob config
```

### Pattern 3: Shared Defaults with Overrides

Defaults can be defined and overridden:

```yaml
# Global defaults
podSecurityContext:
  runAsUser: 1000
  
# Job-specific override
jobs:
  special-job:
    securityContext:
      runAsUser: 2000  # Overrides global default
```

## Testing and Validation

### Local Testing Commands

```bash
# Validate chart structure
helm lint .

# Test template rendering
helm template my-release .

# Test with specific values
helm template my-release . -f examples/postgresql-example.yaml

# Dry-run installation
helm install my-release . --dry-run --debug

# Validate generated YAML
helm template my-release . | kubectl apply --dry-run=client -f -
```

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
- name: Lint Helm Chart
  run: helm lint .
  
- name: Test Template Rendering
  run: |
    helm template test-release . -f examples/postgresql-example.yaml
    helm template test-release . -f examples/mysql-example.yaml
```

## Modification Guide

### Adding a New Database Type

1. **Add database configuration** in values.yaml:
```yaml
databases:
  cassandra:
    enabled: false
    type: cassandra
    host: cassandra
    port: 9042
    keyspace: myapp
```

2. **Define schema job** in values.yaml:
```yaml
jobs:
  cassandra-schema:
    enabled: false
    image:
      repository: cassandra
      tag: "4.0"
    command: ["/bin/bash"]
    args: ["-c", "cqlsh -f /scripts/schema.cql"]
```

3. **Define backup cronjob** in values.yaml:
```yaml
cronJobs:
  cassandra-backup:
    enabled: false
    schedule: "0 2 * * *"
    image:
      repository: cassandra
      tag: "4.0"
    command: ["/bin/bash"]
    args: ["-c", "nodetool snapshot"]
```

4. **Create example** in examples/cassandra-example.yaml

5. **Update documentation** in README.md

No template modifications needed!

### Adding a New Template

If you need a new resource type:

1. Create new file in `templates/` (e.g., `networkpolicy.yaml`)
2. Follow existing template patterns
3. Use helper functions for consistency
4. Add corresponding section in values.yaml
5. Document in this file and README.md

## Code Style Guidelines

### YAML Formatting
- 2-space indentation
- No trailing whitespace
- Comments above configuration blocks
- Group related configurations

### Template Style
- Use `{{- ... }}` to trim whitespace
- Use `{{ include "helper" . }}` for reusable logic
- Use `{{ $var := .Value }}` for local variables
- Use `{{- with .Value }}` for nil-safe access
- Use `{{- toYaml . | nindent N }}` for YAML blocks

### Naming Conventions
- Resources: `{{ release-name }}-{{ resource-type }}`
- Labels: Follow Kubernetes recommended labels
- Variables: Use descriptive names ($dbType, $job, $cronJob)

## Troubleshooting Development Issues

### Template Syntax Errors

```bash
# Render template to see error
helm template my-release . --debug

# Common issues:
# - Unclosed braces {{ }}
# - Missing end statements {{- end }}
# - Incorrect variable scope (use $ for root context)
```

### Value Access Errors

```bash
# Print all values
helm template my-release . --debug | grep -A 100 "COMPUTED VALUES"

# Common issues:
# - Nil pointer: use {{- if .Value }} or {{- with .Value }}
# - Wrong path: .Values.jobs vs .Values.job
# - Scope issues: use $ for root context in range loops
```

### YAML Indentation Issues

```bash
# Use nindent for consistent indentation
{{- toYaml .Values.labels | nindent 4 }}

# Not: {{ .Values.labels | indent 4 }} (loses first line indent)
```

---

This document serves as a comprehensive guide to understanding and modifying the Database Operator Helm chart codebase.
