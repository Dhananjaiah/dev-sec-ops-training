# Contributing to Kafka Platform

Thank you for your interest in contributing!

## Getting Started

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your changes
5. Submit a pull request

## Development Workflow

### Making Changes

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes
# ... edit files ...

# 3. Test changes
make validate-terraform
make validate-k8s
make lint

# 4. Commit
git add .
git commit -m "feat: add new feature"

# 5. Push and create PR
git push origin feature/my-feature
```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance

**Examples:**
```
feat(terraform): add support for GCP
fix(kafka): resolve under-replicated partitions
docs(runbooks): add disaster recovery guide
```

## Testing

### Local Testing

```bash
# Lint
make lint

# Validate Terraform
make validate-terraform

# Validate Kubernetes
make validate-k8s

# Test in dev environment
make bootstrap-dev
make deploy-dev
make smoke-test
```

### CI/CD

All PRs trigger automated checks:
- YAML linting
- Terraform validation
- Kubernetes manifest validation
- Shell script linting
- Security scanning

## Code Style

### Terraform

- Use 2-space indentation
- Run `terraform fmt`
- Add comments for complex logic
- Use meaningful variable names

### Kubernetes

- Follow Kubernetes best practices
- Use Kustomize for overlays
- Add resource limits
- Include health checks

### Shell Scripts

- Use `#!/bin/bash`
- Add `set -e` for error handling
- Include usage/help function
- Use shellcheck

## Documentation

- Update README.md for user-facing changes
- Add/update runbooks for operational procedures
- Document breaking changes
- Include examples

## Pull Request Process

1. **Description:** Clearly describe what and why
2. **Tests:** Include test results
3. **Documentation:** Update relevant docs
4. **Review:** Address review comments
5. **Approval:** Need 1 approval from maintainers

## Questions?

- Open a GitHub issue
- Ask in Slack #kafka-platform
- Email: platform-team@example.com
