# Security Model

## Overview

The Kafka platform implements defense-in-depth security with multiple layers of protection.

## Security Layers

### 1. Network Security

**VPC Isolation:**
```yaml
Private Subnets: Kafka brokers run in private subnets
Public Subnets: Only load balancers exposed
NAT Gateways: Outbound internet access for updates
```

**Security Groups:**
```yaml
Broker-to-Broker: Port 9092 (internal only)
Client-to-Broker: Port 9094 (via NLB)
Metrics: Port 9404 (Prometheus scraping)
SSH: Disabled
```

**Network Policies:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kafka-network-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: kafka
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: kafka
      ports:
        - protocol: TCP
          port: 9092
```

### 2. Encryption

**TLS/mTLS:**
```yaml
All traffic encrypted:
  - Broker-to-broker: mTLS
  - Client-to-broker: TLS + SASL
  - External access: NLB with TLS termination

Certificate management:
  - Strimzi generates cluster CA
  - Auto-rotation every 90 days
  - Clients use trusted CA certificates
```

**Configuration:**
```yaml
listeners:
  - name: plain
    port: 9092
    tls: true
  - name: external
    port: 9094
    tls: true
    
ssl.protocol: TLSv1.3
ssl.enabled.protocols: TLSv1.3,TLSv1.2
ssl.cipher.suites: TLS_AES_256_GCM_SHA384,TLS_AES_128_GCM_SHA256
```

### 3. Authentication

**SASL SCRAM-SHA-512:**
```yaml
authentication:
  type: scram-sha-512
  
Users stored in:
  - Kubernetes secrets (encrypted at rest)
  - AWS Secrets Manager (via External Secrets Operator)
```

**User Creation:**
```bash
# Create user
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: app-producer
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
```

**Client Configuration:**
```properties
security.protocol=SASL_SSL
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required \
  username="app-producer" \
  password="secure-password";
ssl.truststore.location=/path/to/truststore.jks
ssl.truststore.password=truststore-password
```

### 4. Authorization (ACLs)

**Principle of Least Privilege:**

```bash
# Producer ACL
kafka-acls.sh --add \
  --allow-principal User:app-producer \
  --operation WRITE \
  --topic orders

# Consumer ACL
kafka-acls.sh --add \
  --allow-principal User:app-consumer \
  --operation READ \
  --topic orders \
  --group order-processors

# Admin ACL
kafka-acls.sh --add \
  --allow-principal User:admin \
  --operation ALL \
  --cluster
```

**ACL Enforcement:**
```yaml
authorization:
  type: simple
  superUsers:
    - admin
```

**Audit Logging:**
```properties
# Enable authorizer logging
log4j.logger.kafka.authorizer.logger=INFO, authorizerAppender
```

### 5. Secrets Management

**External Secrets Operator:**

```yaml
Flow:
  1. Secrets stored in AWS Secrets Manager
  2. ESO syncs to Kubernetes secrets
  3. Strimzi uses secrets for users
  4. Auto-rotation supported
```

**Secret Rotation:**
```bash
# Rotate user password
1. Update password in AWS Secrets Manager
2. ESO syncs new password (within 1 hour)
3. Strimzi applies new password to Kafka
4. Update client applications
5. Old password invalidated
```

**Best Practices:**
```yaml
✅ Store secrets in AWS Secrets Manager
✅ Enable secret versioning
✅ Rotate every 90 days
✅ Use IAM roles (no hardcoded credentials)
✅ Enable encryption at rest
✅ Audit secret access
```

### 6. Quotas & Rate Limiting

**Prevent resource abuse:**

```properties
# Producer quotas (10 MB/s)
quota.producer.default=10485760

# Consumer quotas (20 MB/s)
quota.consumer.default=20971520

# Connection quotas
max.connections.per.ip=100
```

**Per-User Quotas:**
```bash
kafka-configs.sh --alter \
  --add-config 'producer_byte_rate=10485760' \
  --entity-type users \
  --entity-name app-producer
```

### 7. Data Protection

**Replication:**
```yaml
default.replication.factor: 3
min.insync.replicas: 2
unclean.leader.election.enable: false
```

**Backup & DR:**
```yaml
MirrorMaker2:
  - Continuous replication to DR cluster
  - RPO: < 1 minute
  - RTO: < 15 minutes
```

## Security Compliance

### SOC 2 / ISO 27001

**Controls implemented:**
```yaml
✅ Encryption in transit (TLS)
✅ Encryption at rest (EBS encrypted volumes)
✅ Access control (RBAC, ACLs)
✅ Audit logging (CloudWatch)
✅ Secret management (AWS Secrets Manager)
✅ Network isolation (VPC, Security Groups)
✅ Vulnerability scanning (Trivy, Checkov)
✅ Patch management (automated EKS updates)
```

### GDPR Compliance

**Data handling:**
```yaml
✅ Data minimization (retention policies)
✅ Right to deletion (topic compaction, retention)
✅ Data encryption (TLS, EBS)
✅ Access logging (who accessed what)
✅ Data locality (regional deployment)
```

## Incident Response

### Security Incident Playbook

**1. Unauthorized Access Detected:**
```bash
# Immediate actions
1. Revoke compromised credentials
2. Review ACLs for unusual grants
3. Check audit logs for access patterns
4. Rotate all related secrets
5. Notify security team
```

**2. Data Exfiltration Suspected:**
```bash
# Immediate actions
1. Enable detailed audit logging
2. Review consumer groups
3. Check unusual traffic patterns
4. Isolate affected brokers if needed
5. Forensic analysis
```

**3. Malicious Payload Detected:**
```bash
# Immediate actions
1. Identify affected topics
2. Pause consumers if needed
3. Sanitize data
4. Update input validation
5. Deploy fixes
```

## Security Monitoring

### Key Metrics

```yaml
Authentication failures: Alert if > 10/min
Authorization denials: Alert if > 50/min
Unusual traffic patterns: ML-based anomaly detection
Failed login attempts: Block after 5 attempts
Certificate expiry: Alert 30 days before
Secret rotation: Alert if overdue
```

### Audit Logging

**What to log:**
```yaml
- Authentication attempts (success/failure)
- Authorization decisions (allow/deny)
- ACL changes
- User creation/deletion
- Topic creation/deletion
- Configuration changes
- Admin operations
```

**Log retention:** 90 days minimum

## Security Hardening Checklist

**Pre-Production:**
- [ ] Enable TLS on all listeners
- [ ] Configure SASL authentication
- [ ] Set up ACLs for all users
- [ ] Enable quotas
- [ ] Configure External Secrets Operator
- [ ] Set up audit logging
- [ ] Enable network policies
- [ ] Configure security groups
- [ ] Encrypt EBS volumes
- [ ] Set up secret rotation
- [ ] Enable Kubernetes RBAC
- [ ] Configure pod security policies
- [ ] Set resource limits
- [ ] Enable vulnerability scanning
- [ ] Document security controls

**Ongoing:**
- [ ] Rotate secrets every 90 days
- [ ] Review ACLs monthly
- [ ] Update Kafka quarterly
- [ ] Scan for vulnerabilities weekly
- [ ] Review audit logs daily
- [ ] Test DR quarterly
- [ ] Update documentation
- [ ] Security training for team

## References

- [Kafka Security Documentation](https://kafka.apache.org/documentation/#security)
- [Strimzi Security](https://strimzi.io/docs/operators/latest/security.html)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
