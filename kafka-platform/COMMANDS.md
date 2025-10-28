# Exact Commands to Deploy Kafka Platform

This document provides the exact command sequences to deploy the Kafka platform to each environment.

## Prerequisites Setup (One-time)

```bash
# 1. Install required tools
brew install awscli kubectl terraform helm kustomize  # macOS
# OR
apt-get install awscli kubectl terraform helm  # Linux
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# 2. Configure AWS credentials
aws configure
# Enter your Access Key ID, Secret Access Key, Region (us-east-1), and Output format (json)

# 3. Create Terraform state backend (one-time per environment)
aws s3 mb s3://kafka-platform-terraform-state-dev --region us-east-1
aws s3 mb s3://kafka-platform-terraform-state-stage --region us-east-1
aws s3 mb s3://kafka-platform-terraform-state-prod --region us-east-1

aws dynamodb create-table \
  --table-name kafka-platform-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# 4. Clone repository
git clone https://github.com/Dhananjaiah/dev-sec-ops-training.git
cd dev-sec-ops-training/kafka-platform
```

## Development Environment

**Timeline: ~60 minutes**

```bash
# Step 1: Deploy infrastructure (20 min)
cd infra/terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Step 2: Configure kubectl (1 min)
aws eks update-kubeconfig --name dev-kafka-cluster --region us-east-1
kubectl get nodes  # Verify

# Step 3: Return to kafka-platform root
cd ../../../..

# Step 4: Install operators (5 min)
make install-strimzi
make install-external-secrets

# Step 5: Create secrets in AWS Secrets Manager (2 min)
aws secretsmanager create-secret \
  --name kafka/admin/password \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1

aws secretsmanager create-secret \
  --name kafka/connect/password \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1

# Step 6: Deploy Kafka cluster (20 min)
make deploy-dev

# Step 7: Wait for cluster to be ready
kubectl wait --for=condition=ready kafka dev-kafka -n kafka --timeout=600s

# Step 8: Install monitoring (5 min)
make install-monitoring

# Step 9: Run smoke tests (2 min)
make smoke-test ENV=dev

# Step 10: Access Grafana (optional)
make port-forward-grafana
# Open http://localhost:3000 (admin/admin)

# Step 11: Get Kafka endpoints
make show-endpoints ENV=dev
```

**Verification:**
```bash
kubectl get kafka -n kafka                    # Should show READY: True
kubectl get pods -n kafka                     # All pods Running
./scripts/admin/create-topic.sh --list       # List topics
```

## Stage Environment

**Timeline: ~75 minutes**

```bash
# Step 1: Deploy infrastructure (25 min)
cd infra/terraform/environments/stage
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Step 2: Configure kubectl (1 min)
aws eks update-kubeconfig --name stage-kafka-cluster --region us-east-1
kubectl get nodes

# Step 3: Return to kafka-platform root
cd ../../../..

# Step 4: Install operators (5 min)
make install-strimzi
make install-external-secrets

# Step 5: Create secrets (if not using shared secrets manager)
aws secretsmanager create-secret \
  --name kafka-stage/admin/password \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1

aws secretsmanager create-secret \
  --name kafka-stage/connect/password \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1

# Step 6: Deploy Kafka cluster (30 min - 3 brokers)
make deploy-stage

# Step 7: Wait for cluster
kubectl wait --for=condition=ready kafka stage-kafka -n kafka --timeout=900s

# Step 8: Install monitoring
make install-monitoring

# Step 9: Run smoke tests
make smoke-test ENV=stage

# Step 10: Performance test (optional)
./scripts/testing/perf-test.sh stage

# Step 11: Get endpoints
make show-endpoints ENV=stage
```

**Verification:**
```bash
kubectl get kafka stage-kafka -n kafka -o yaml | grep -A5 status
kubectl get pods -n kafka -l app.kubernetes.io/name=kafka  # 3 brokers
```

## Production Environment

**Timeline: ~90 minutes**
**⚠️ REQUIRES APPROVAL - Manual confirmation prompts will appear**

```bash
# Step 1: Deploy infrastructure (35 min)
cd infra/terraform/environments/prod
terraform init
terraform plan -out=tfplan

# REVIEW PLAN CAREFULLY BEFORE PROCEEDING
terraform apply tfplan
# Type 'yes' when prompted

# Step 2: Configure kubectl (1 min)
aws eks update-kubeconfig --name prod-kafka-cluster --region us-east-1
kubectl get nodes  # Should see 6+ nodes

# Step 3: Return to kafka-platform root
cd ../../../..

# Step 4: Install operators (5 min)
make install-strimzi
make install-external-secrets

# Step 5: Create production secrets (2 min)
# Use strong passwords for production!
aws secretsmanager create-secret \
  --name kafka-prod/admin/password \
  --secret-string "$(openssl rand -base64 48)" \
  --region us-east-1

aws secretsmanager create-secret \
  --name kafka-prod/connect/password \
  --secret-string "$(openssl rand -base64 48)" \
  --region us-east-1

aws secretsmanager create-secret \
  --name kafka-prod/schema-registry/credentials \
  --secret-string '{"sasl.jaas.config":"...","truststore.password":"..."}' \
  --region us-east-1

# Step 6: Deploy Kafka cluster (40 min - requires approval)
make deploy-prod
# Type 'yes' when prompted

# Step 7: Wait for cluster (may take longer)
kubectl wait --for=condition=ready kafka prod-kafka -n kafka --timeout=1800s

# Step 8: Install monitoring
make install-monitoring

# Step 9: Verify all components
kubectl get pods -n kafka           # All Running
kubectl get kafka -n kafka          # READY: True
kubectl get svc -n kafka            # Load balancers created

# Step 10: Run comprehensive tests
make smoke-test ENV=prod
./scripts/testing/perf-test.sh prod

# Step 11: Check monitoring
make port-forward-grafana
# Verify dashboards showing metrics

# Step 12: Document endpoints
make show-endpoints ENV=prod > prod-endpoints.txt

# Step 13: Configure external DNS (if using Route53)
# Get NLB DNS name
kubectl get svc prod-kafka-kafka-external-bootstrap -n kafka -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Create Route53 records (manual or via terraform)
# Example: kafka.example.com → NLB DNS
```

**Production Verification Checklist:**
```bash
# ✓ Infrastructure
kubectl get nodes                                      # 6+ nodes across 3 AZs
kubectl get pods -n kafka                              # All Running
kubectl get kafka prod-kafka -n kafka                  # READY: True

# ✓ Brokers
kubectl get pods -n kafka -l app.kubernetes.io/name=kafka  # 3 brokers Running

# ✓ Storage
kubectl get pvc -n kafka                               # 3 PVCs Bound

# ✓ No under-replicated partitions
kubectl exec -n kafka prod-kafka-0 -c kafka -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --describe --under-replicated-partitions

# ✓ Monitoring
kubectl get pods -n monitoring                         # Prometheus, Grafana Running

# ✓ External access
nslookup kafka.example.com                             # DNS resolves
echo | openssl s_client -connect kafka.example.com:9094 2>/dev/null | grep subject
```

## Quick Reference: Common Operations

### Create Topic
```bash
./scripts/admin/create-topic.sh --name orders --partitions 24
```

### List Topics
```bash
./scripts/admin/create-topic.sh --list
```

### Grant Producer Access
```bash
./scripts/admin/manage-acls.sh --user app-producer --topic orders --operation WRITE
```

### Grant Consumer Access
```bash
./scripts/admin/manage-acls.sh --user app-consumer --topic orders --group order-processors --operation READ
```

### Set Quota
```bash
./scripts/admin/set-quotas.sh --user app-producer --producer-byte-rate 10485760
```

### Performance Test
```bash
./scripts/testing/perf-test.sh <env>
```

### Chaos Drill
```bash
./scripts/testing/chaos-drill.sh --kill-random --env dev
```

### Access Grafana
```bash
make port-forward-grafana
# http://localhost:3000 (admin/admin)
```

### Get Cluster Info
```bash
make show-endpoints ENV=<env>
make health-check ENV=<env>
```

## Environment Comparison

| Feature | Dev | Stage | Prod |
|---------|-----|-------|------|
| Brokers | 1 | 3 | 3 |
| Controllers | 1 | 3 | 3 |
| Node Type | m5.xlarge | m5.xlarge | m5.2xlarge |
| Storage/Broker | 100 GB | 500 GB | 2 TB |
| Availability Zones | 1 | 3 | 3 |
| Replication Factor | 1 | 3 | 3 |
| Deployment Time | ~60 min | ~75 min | ~90 min |
| Monthly Cost | ~$300 | ~$800 | ~$1,500 |

## Cleanup Commands

### Dev Environment
```bash
make destroy-dev
# Type 'yes' when prompted
```

### Stage Environment
```bash
make destroy-stage
# Type 'yes' when prompted
```

### Production Environment
```bash
make destroy-prod
# Type 'DELETE PRODUCTION' when prompted (safety measure)
```

**⚠️ Warning:** Destroying environments will delete all data. Ensure you have backups!

## Troubleshooting Common Issues

### Terraform State Lock
```bash
# If terraform is locked
aws dynamodb delete-item \
  --table-name kafka-platform-terraform-locks \
  --key '{"LockID": {"S": "kafka-platform-terraform-state-<env>/terraform.tfstate"}}' \
  --region us-east-1
```

### Pods Not Starting
```bash
# Check events
kubectl describe pod <pod-name> -n kafka

# Check logs
kubectl logs <pod-name> -n kafka -c kafka

# Common fix: Insufficient resources
kubectl describe nodes | grep -A5 "Allocated resources"
```

### External Access Not Working
```bash
# Check service
kubectl get svc -n kafka | grep external

# Check load balancer
kubectl describe svc prod-kafka-kafka-external-bootstrap -n kafka

# Check security groups in AWS Console
```

## Support

- **Documentation**: See `/docs` directory
- **Runbooks**: See `/docs/runbooks`
- **FAQs**: See `/docs/faqs.md`
- **Issues**: Open GitHub issue

---

**Last Updated**: 2024
**Maintained By**: Platform Team
