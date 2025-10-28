# Kafka Platform - Complete Deployment Guide

## Executive Summary

This guide provides step-by-step instructions to deploy the production-grade Kafka platform from zero to fully operational cluster.

## Prerequisites

### Required Tools

```bash
# Check versions
aws --version          # >= 2.0
kubectl version        # >= 1.27
terraform --version    # >= 1.5
helm version          # >= 3.12
kustomize version     # >= 5.0
```

### AWS Setup

```bash
# Configure AWS CLI
aws configure
# Provide: Access Key, Secret Key, Region (us-east-1), Output format (json)

# Verify access
aws sts get-caller-identity
```

### Required Permissions

```yaml
AWS Permissions Needed:
  - EC2: Full access (VPC, subnets, security groups)
  - EKS: Full access
  - IAM: Create roles and policies
  - EBS: Create and manage volumes
  - ELB: Create load balancers
  - Secrets Manager: Create and read secrets
```

## Deployment Steps

### Phase 1: Infrastructure (30 minutes)

**1.1 Clone Repository**
```bash
git clone <repo-url>
cd dev-sec-ops-training/kafka-platform
```

**1.2 Configure Terraform Backend**
```bash
# Create S3 bucket for state
aws s3 mb s3://kafka-platform-terraform-state-dev --region us-east-1

# Create DynamoDB table for locks
aws dynamodb create-table \
  --table-name kafka-platform-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

**1.3 Deploy Infrastructure**
```bash
cd infra/terraform/environments/dev

# Initialize Terraform
terraform init

# Review plan
terraform plan -out=tfplan

# Apply (creates VPC, EKS, networking)
terraform apply tfplan
```

**Expected Output:**
```
Apply complete! Resources: 45 added, 0 changed, 0 destroyed.

Outputs:
cluster_name = "dev-kafka-cluster"
configure_kubectl = "aws eks update-kubeconfig --region us-east-1 --name dev-kafka-cluster"
```

**1.4 Configure kubectl**
```bash
aws eks update-kubeconfig --name dev-kafka-cluster --region us-east-1

# Verify
kubectl get nodes
```

### Phase 2: Operators & Dependencies (15 minutes)

**2.1 Install Strimzi Operator**
```bash
cd ../../../..  # Back to kafka-platform root
make install-strimzi
```

**Wait for operator to be ready:**
```bash
kubectl wait --for=condition=ready pod \
  -l name=strimzi-cluster-operator \
  -n kafka \
  --timeout=300s
```

**2.2 Install External Secrets Operator**
```bash
make install-external-secrets
```

**2.3 Create AWS Secrets**
```bash
# Admin password
aws secretsmanager create-secret \
  --name kafka/admin/password \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1

# Connect password
aws secretsmanager create-secret \
  --name kafka/connect/password \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1
```

**2.4 Configure IAM for External Secrets**
```bash
# Create IAM policy (see docs/security-model.md)
# Attach to EKS service account
# Deploy secret store
kubectl apply -f k8s/external-secrets/external-secrets.yaml
```

### Phase 3: Kafka Deployment (20 minutes)

**3.1 Deploy Kafka Cluster**
```bash
make deploy-dev
```

**This will:**
- Create Kafka cluster (KRaft mode)
- Deploy 1 broker + 1 controller (dev config)
- Configure listeners (internal + external)
- Set up authentication (SASL SCRAM)
- Enable metrics (JMX exporter)

**3.2 Monitor Deployment**
```bash
# Watch pods starting
kubectl get pods -n kafka -w

# Check Kafka cluster status
kubectl get kafka dev-kafka -n kafka
```

**Wait for Ready status:**
```yaml
NAME        DESIRED KAFKA REPLICAS  DESIRED ZK REPLICAS  READY
dev-kafka   1                       0                    True
```

**3.3 Verify Brokers**
```bash
kubectl get pods -n kafka -l app.kubernetes.io/name=kafka

# Should show:
# dev-kafka-0   1/1   Running   0   5m
```

### Phase 4: Monitoring (10 minutes)

**4.1 Deploy Monitoring Stack**
```bash
make install-monitoring
```

**4.2 Access Grafana**
```bash
make port-forward-grafana

# Open browser: http://localhost:3000
# Default login: admin/admin
```

**4.3 Verify Dashboards**
- Navigate to Dashboards
- Open "Kafka Overview"
- Verify metrics are being collected

### Phase 5: Validation (15 minutes)

**5.1 Run Smoke Tests**
```bash
make smoke-test ENV=dev
```

**Expected output:**
```
======================================
Kafka Cluster Smoke Test - dev
======================================

[✓] Checking Kafka cluster status...
[✓] Verifying cluster readiness...
[✓] Checking broker pods...
[✓] Creating test topic: smoke-test-1234567890...
[✓] Producing test messages...
[✓] Consuming test messages...
[✓] Cleaning up test topic...
[✓] Checking for under-replicated partitions...
[✓] No under-replicated partitions found
[✓] Verifying metrics endpoint...
[✓] Metrics endpoint is responding

======================================
[✓] Smoke test completed successfully!
======================================
```

**5.2 Manual Testing**

**Create a topic:**
```bash
./scripts/admin/create-topic.sh --name orders --partitions 12
```

**List topics:**
```bash
./scripts/admin/create-topic.sh --list
```

**5.3 Test Producer/Consumer**

**Python producer:**
```bash
cd clients/python
pip install -r requirements.txt

# Update bootstrap server in code
export KAFKA_BOOTSTRAP="<external-bootstrap-server>"
python producer_example.py
```

**Python consumer:**
```bash
python consumer_example.py
```

### Phase 6: Security Configuration (Optional)

**6.1 Create Application Users**
```bash
# Producer user
kubectl apply -f - <<EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: app-producer
  namespace: kafka
  labels:
    strimzi.io/cluster: dev-kafka
spec:
  authentication:
    type: scram-sha-512
  authorization:
    type: simple
    acls:
      - resource:
          type: topic
          name: orders
        operation: Write
EOF
```

**6.2 Get User Credentials**
```bash
kubectl get secret app-producer -n kafka -o jsonpath='{.data.password}' | base64 -d
```

**6.3 Configure ACLs**
```bash
./scripts/admin/manage-acls.sh \
  --user app-producer \
  --topic orders \
  --operation WRITE
```

## Verification Checklist

After deployment, verify:

- [ ] All pods running: `kubectl get pods -n kafka`
- [ ] Kafka cluster ready: `kubectl get kafka -n kafka`
- [ ] No under-replicated partitions
- [ ] Metrics visible in Grafana
- [ ] Can create topics
- [ ] Can produce messages
- [ ] Can consume messages
- [ ] Monitoring alerts configured
- [ ] External access working (if configured)

## Common Issues & Solutions

### Issue: Pods stuck in Pending

**Cause:** Insufficient cluster resources

**Solution:**
```bash
# Check node capacity
kubectl describe nodes

# Scale node group if needed
# Edit terraform config and re-apply
```

### Issue: Kafka cluster not ready

**Cause:** Configuration error or resource limits

**Solution:**
```bash
# Check logs
kubectl logs -n kafka dev-kafka-0 -c kafka

# Check events
kubectl describe kafka dev-kafka -n kafka
```

### Issue: Can't access external endpoint

**Cause:** Security group or NLB not configured

**Solution:**
```bash
# Check service
kubectl get svc -n kafka

# Check load balancer
kubectl describe svc dev-kafka-kafka-external-bootstrap -n kafka
```

## Performance Tuning

For production deployments:

**1. Increase Resources:**
```yaml
# Edit k8s/strimzi/overlays/prod/kustomization.yaml
resources:
  requests:
    memory: 8Gi
    cpu: "2000m"
  limits:
    memory: 16Gi
    cpu: "4000m"
```

**2. Optimize Storage:**
```bash
# Use gp3 with higher IOPS
storage:
  type: persistent-claim
  size: 2Ti
  class: gp3
```

**3. Tune JVM:**
```yaml
jvmOptions:
  -Xms: 4096m
  -Xmx: 8192m
  -XX:
    +UseG1GC: true
    MaxGCPauseMillis: 20
```

## Next Steps

1. **Configure DR**: Deploy MirrorMaker2 for disaster recovery
2. **Add Monitoring Alerts**: Configure Alertmanager
3. **Deploy Applications**: Integrate your applications
4. **Load Testing**: Run performance tests
5. **Documentation**: Customize runbooks for your team

## Production Deployment

For production, use the prod overlay:

```bash
# Deploy prod infrastructure
cd infra/terraform/environments/prod
terraform apply

# Deploy prod Kafka
make deploy-prod
```

**Key differences:**
- 3 brokers across 3 AZs
- Larger instance types (m5.2xlarge)
- 2TB storage per broker
- Dedicated controllers
- Stricter resource limits

## Cleanup

To destroy the environment:

```bash
# Delete Kafka cluster
kubectl delete -k k8s/strimzi/overlays/dev

# Destroy infrastructure
cd infra/terraform/environments/dev
terraform destroy
```

## Support & Resources

- **Documentation**: `docs/` directory
- **Runbooks**: `docs/runbooks/`
- **FAQs**: `docs/faqs.md`
- **GitHub Issues**: Report problems
- **Slack**: #kafka-platform (if available)

---

**Deployment Time Summary:**
- Infrastructure: 30 minutes
- Operators: 15 minutes
- Kafka: 20 minutes
- Monitoring: 10 minutes
- Validation: 15 minutes
- **Total: ~90 minutes** (first time)
