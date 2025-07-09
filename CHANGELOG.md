# Changelog

All notable changes to the Database Operator Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-XX

### Added
- **Universal Database Support**: Complete refactor to support multiple database types
  - PostgreSQL with Liquibase schema management
  - TimescaleDB with time-series specific operations
  - MySQL with automated backups and maintenance
  - ArangoDB with custom script support
  - MongoDB with document database operations
- **Flexible Schema Management**: Support for Liquibase, Flyway, and custom scripts
- **Automated Backup System**: Configurable backup schedules with retention policies
- **Maintenance Operations**: Database-specific maintenance jobs (VACUUM, OPTIMIZE, etc.)
- **Security Best Practices**: RBAC, security contexts, SealedSecrets support
- **GitOps Ready**: Complete ArgoCD compatibility with SealedSecrets
- **Professional Documentation**: Comprehensive README, contributing guidelines, examples
- **Example Configurations**: Complete examples for each database type
- **Multi-Database Support**: Single deployment managing multiple database types
- **Custom Operations**: Extensible framework for custom database operations

### Changed
- **Chart Name**: Renamed from legacy name to `database-operator` for universal usage
- **Values Structure**: Completely redesigned for multi-database support
- **Configuration Model**: Database-specific configurations with shared defaults
- **Security Model**: Enhanced security contexts and RBAC permissions
- **Documentation**: Professional open-source documentation with examples

### Removed
- **Organization-specific configurations**: Removed hardcoded organization-specific settings
- **Legacy job definitions**: Replaced with flexible, configurable job system

### Migration Guide
To migrate from v1.x to v2.0:

1. **Update values.yaml structure**:
   ```yaml
   # Old structure (v1.x)
   jobs:
     timescaledb-schema-update:
       enabled: true
   
   # New structure (v2.0)
   schemaJobs:
     enabled: true
     postgresql:  # TimescaleDB uses PostgreSQL jobs
       enabled: true
   ```

2. **Update secret names**:
   ```yaml
   # Old structure
   secrets:
     db-credentials:
       create: true
   
   # New structure
   secrets:
     database-credentials:
       create: true
   ```

3. **Update database configurations**:
   ```yaml
   # New database configuration section
   databases:
     postgresql:
       enabled: true
       host: postgresql-primary
       port: 5432
       database: myapp
   ```

## [1.0.9] - Previous Release
### Added
- Initial release of Database Operator Helm chart
- Support for TimescaleDB, MySQL, and ArangoDB schema management
- Scheduled database operations with CronJobs
- Basic backup and maintenance functionality

---

**Note**: Version 2.0.0 represents a major refactor for universal database support. Please review the migration guide when upgrading from v1.x.