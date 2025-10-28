# Kafka Platform Overview

This directory contains a complete, production-grade Apache Kafka installation and administration toolkit for the DevSecOps training project.

## 🎯 Purpose

Demonstrate enterprise-grade infrastructure-as-code, security practices, observability, and operational excellence through a real-world Kafka platform implementation.

## 📂 What's Included

```
kafka-platform/
├── README.md                 # Comprehensive platform documentation
├── Makefile                  # 30+ operational commands
├── infra/terraform/          # AWS infrastructure (VPC, EKS, IAM)
├── k8s/strimzi/             # Kafka cluster configs (KRaft mode)
├── k8s/monitoring/          # Prometheus & Grafana
├── k8s/external-secrets/    # Secret management
├── scripts/                 # Admin & testing tools
├── clients/                 # Java & Python examples
├── observability/           # Dashboards & alerts
├── docs/                    # Runbooks & guides
└── .github/workflows/       # CI/CD pipelines
```

## 🚀 Quick Start

```bash
cd kafka-platform

# 1. Review architecture and configuration
cat README.md

# 2. Deploy to development
make bootstrap-dev
make deploy-dev

# 3. Run smoke tests
make smoke-test

# 4. Access Grafana dashboards
make port-forward-grafana
```

## 🎓 Learning Objectives

### Infrastructure as Code (IaC)
- **Terraform**: Multi-environment AWS infrastructure
- **Kustomize**: Environment-specific Kubernetes overlays
- **GitOps**: Declarative infrastructure management

### Security
- **mTLS**: Encrypted communication
- **SASL SCRAM**: Authentication
- **ACLs**: Authorization
- **External Secrets**: Secure credential management
- **Network Policies**: Traffic control

### Observability
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **Alertmanager**: Alert routing
- **JMX Exporter**: Kafka metrics

### High Availability
- **KRaft Mode**: No ZooKeeper dependency
- **Multi-AZ**: Cross-zone deployment
- **Replication**: RF=3 with min.isr=2
- **MirrorMaker2**: Disaster recovery

### CI/CD
- **GitHub Actions**: Automated pipelines
- **Linting**: YAML, Terraform, Shell
- **Security Scanning**: Trivy, Checkov
- **Terraform Plans**: PR comments

### Operations
- **Admin Scripts**: Topic, ACL, quota management
- **Testing**: Smoke, performance, chaos engineering
- **Runbooks**: DR, upgrades, troubleshooting
- **Monitoring**: SLOs, alerts, dashboards

## 📚 Key Concepts Demonstrated

### 1. KRaft Architecture
Modern Kafka without ZooKeeper:
- Faster controller failover
- Simpler operations
- Better scalability

### 2. Production Best Practices
```yaml
Replication Factor: 3
min.insync.replicas: 2
unclean.leader.election: false
Idempotent producers: enabled
Exactly-once semantics: supported
```

### 3. Capacity Planning
- Storage calculations
- Throughput sizing
- Partition planning
- Resource allocation

### 4. Security in Depth
- Network isolation (VPC, security groups)
- Encryption (TLS/mTLS)
- Authentication (SASL SCRAM)
- Authorization (ACLs)
- Secret management (External Secrets Operator)

### 5. Observability Stack
- Real-time metrics (Prometheus)
- Dashboards (Grafana)
- Alerting (critical, warning, info)
- SLOs and SLIs

## 🎯 Use Cases

This platform demonstrates solutions for:

✅ **High-throughput event streaming**
✅ **Microservices communication**
✅ **Real-time data pipelines**
✅ **Change data capture (CDC)**
✅ **Log aggregation**
✅ **Event sourcing**

## 🔧 Technologies

| Category | Technology |
|----------|-----------|
| Container Orchestration | Kubernetes (EKS) |
| Kafka Operator | Strimzi |
| Infrastructure | Terraform |
| Cloud Provider | AWS |
| Monitoring | Prometheus, Grafana |
| Secret Management | External Secrets Operator |
| CI/CD | GitHub Actions |
| Languages | Java, Python, Bash |

## 📖 Documentation

- **[Main README](README.md)**: Architecture, deployment, operations
- **[Capacity Planning](docs/capacity-planning.md)**: Sizing guide
- **[Upgrade Strategy](docs/upgrade-strategy.md)**: Rolling upgrades
- **[Security Model](docs/security-model.md)**: Security architecture
- **[SLOs](docs/slos/kafka-slos.md)**: Service level objectives
- **[FAQs](docs/faqs.md)**: Common questions
- **[DR Runbook](docs/runbooks/disaster-recovery.md)**: Disaster recovery

## 🎓 Training Value

This Kafka platform serves as a comprehensive example for:

### DevOps Engineers
- Infrastructure automation
- Configuration management
- Deployment strategies
- Monitoring setup

### Security Engineers
- Encryption implementation
- Authentication mechanisms
- Authorization policies
- Secret management

### SRE/Operations
- Capacity planning
- Performance tuning
- Incident response
- Disaster recovery

### Developers
- Client integration (Java, Python)
- Best practices (idempotence, EOS)
- Performance optimization
- Error handling

## 🚀 Next Steps

1. **Explore the codebase**: Review terraform, k8s manifests, scripts
2. **Deploy locally**: Use kind/minikube for local testing
3. **Run tests**: Execute smoke tests, performance tests
4. **Customize**: Adapt for your use case
5. **Contribute**: Submit improvements via PRs

## 📞 Support

- **Documentation**: See [docs/](docs/) directory
- **Issues**: Open a GitHub issue
- **Questions**: Check [FAQs](docs/faqs.md)

## 📄 License

Apache License 2.0 - See [../LICENSE](../LICENSE)

---

**Built with ❤️ for DevSecOps training and education**
