# Contributing to Database Operator

Thank you for your interest in contributing to the Database Operator Helm chart! This document provides guidelines and information for contributors.

## 🤝 Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/). By participating, you are expected to uphold this code.

## 🚀 Getting Started

### Prerequisites

- **Kubernetes cluster** (1.19+) for testing
- **Helm** (3.0+)
- **kubectl** configured with access to a cluster
- **Git** for version control

### Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/database-operator.git
   cd database-operator
   ```
3. **Add the original repository** as upstream:
   ```bash
   git remote add upstream https://github.com/selvarajmurugesan90/database-operator.git
   ```

## 📝 Development Process

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

Use descriptive branch names:
- `feature/add-redis-support`
- `fix/backup-job-timeout`
- `docs/improve-examples`

### 2. Make Your Changes

- Follow the existing code style and patterns
- Update documentation as needed
- Add or update tests
- Ensure your changes work with multiple database types

### 3. Test Your Changes

```bash
# Lint the chart
helm lint .

# Test template rendering
helm template . --debug

# Test with example values
helm template . -f examples/postgresql-example.yaml

# Dry run installation
helm install test-release . --dry-run --debug
```

### 4. Update Documentation

- Update the README.md if adding new features
- Add examples for new database types
- Update configuration documentation

### 5. Commit Your Changes

Use conventional commit messages:
```bash
git commit -m "feat: add Redis backup support"
git commit -m "fix: resolve MySQL schema job timeout"
git commit -m "docs: improve PostgreSQL example"
```

### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub.

## 📋 Pull Request Guidelines

### Before Submitting

- [ ] Code follows the project's style guidelines
- [ ] Tests pass locally
- [ ] Documentation has been updated
- [ ] Examples have been added/updated if applicable
- [ ] Commit messages are clear and descriptive

### Pull Request Description

Please include:
1. **Description** of the changes
2. **Motivation** for the changes
3. **Testing** performed
4. **Breaking changes** (if any)
5. **Related issues** (if any)

### Example Pull Request Template

```markdown
## Description
Brief description of the changes made.

## Motivation
Why were these changes necessary?

## Changes Made
- [ ] Added support for Redis operations
- [ ] Updated documentation
- [ ] Added examples

## Testing
- [ ] Tested with PostgreSQL
- [ ] Tested with MySQL
- [ ] Tested with MongoDB
- [ ] Tested backup functionality
- [ ] Tested schema management

## Breaking Changes
List any breaking changes and migration instructions.

## Related Issues
Closes #123
```

## 🧪 Testing

### Unit Testing

```bash
# Run chart linting
helm lint .

# Template validation
helm template . --debug --validate

# Test with different values
helm template . -f examples/postgresql-example.yaml --validate
helm template . -f examples/mysql-example.yaml --validate
```

### Integration Testing

```bash
# Install on test cluster
helm install test-db-operator . -f examples/postgresql-example.yaml

# Verify installation
kubectl get all -l app.kubernetes.io/name=database-operator

# Test functionality
kubectl logs job/database-operator-postgresql-schema

# Clean up
helm uninstall test-db-operator
```

## 📚 Documentation

### Types of Documentation

1. **Code Comments**: Document complex logic
2. **README.md**: Main documentation
3. **Examples**: Practical usage examples
4. **Chart Values**: Document all configuration options

### Documentation Style

- Use clear, concise language
- Include code examples
- Provide practical use cases
- Keep examples up to date

## 🛠️ Chart Development Guidelines

### Values File Structure

```yaml
# Group related configurations
databases:
  postgresql:
    enabled: false
    # database-specific config

# Use consistent naming
schemaJobs:
  enabled: false
  defaults:
    # shared defaults
  postgresql:
    # database-specific overrides
```

### Template Best Practices

1. **Use helpers** for repeated logic
2. **Validate input** in templates
3. **Support multiple databases** in the same template
4. **Follow Kubernetes naming conventions**
5. **Use labels consistently**

### Security Considerations

- Never hardcode credentials
- Use security contexts
- Follow principle of least privilege
- Support SealedSecrets for GitOps

## 🐛 Bug Reports

### Before Submitting

1. **Check existing issues** to avoid duplicates
2. **Test with latest version**
3. **Gather relevant information**

### Bug Report Template

```markdown
## Bug Description
Clear description of the bug.

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen.

## Actual Behavior
What actually happened.

## Environment
- Kubernetes version:
- Helm version:
- Chart version:
- Database type:

## Additional Context
Any additional information, logs, or screenshots.
```

## 💡 Feature Requests

### Before Submitting

1. **Check existing feature requests**
2. **Consider the scope** and complexity
3. **Think about backward compatibility**

### Feature Request Template

```markdown
## Feature Description
Clear description of the proposed feature.

## Motivation
Why is this feature needed?

## Proposed Solution
How should this feature work?

## Alternatives Considered
Other approaches you've considered.

## Additional Context
Any additional information or examples.
```

## 🏷️ Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: Add functionality (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Steps

1. Update version in `Chart.yaml`
2. Update `CHANGELOG.md`
3. Create release notes
4. Tag the release
5. Update Helm repository

## 📋 Coding Standards

### YAML Style

```yaml
# Use 2-space indentation
apiVersion: v2
name: database-operator

# Use consistent naming
nameOverride: ""
fullnameOverride: ""

# Group related configurations
databases:
  postgresql:
    enabled: false
    host: postgresql
    port: 5432
```

### Template Style

```yaml
{{- if .Values.schemaJobs.enabled }}
{{- range $dbType, $config := .Values.schemaJobs }}
{{- if and (ne $dbType "enabled") (ne $dbType "defaults") $config.enabled }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "database-operator.fullname" $ }}-{{ $dbType }}-schema
{{- end }}
{{- end }}
{{- end }}
```

## 🤝 Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and discussions
- **Slack**: Real-time chat (if available)

### Getting Help

1. **Check documentation** first
2. **Search existing issues**
3. **Ask in discussions**
4. **Create an issue** if needed

## 📝 License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors are recognized in:
- **README.md**: Major contributors
- **CHANGELOG.md**: Per-release contributions
- **GitHub contributors**: Automatic recognition

---

Thank you for contributing to the Database Operator! Your contributions help make database management in Kubernetes easier for everyone. 🎉