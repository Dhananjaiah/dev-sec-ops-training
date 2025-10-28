# Disaster Recovery Runbook

## Overview

This runbook covers disaster recovery procedures for the Kafka platform, including failover, failback, and recovery scenarios.

## Prerequisites

- MirrorMaker2 configured and running
- DR cluster provisioned and healthy
- Access to both primary and DR clusters
- DNS/Load Balancer configuration access
- Communication plan established

## DR Architecture

```
Primary Cluster (us-east-1)
    ↓ (MirrorMaker2)
DR Cluster (us-west-2)
```

**RPO (Recovery Point Objective):** < 1 minute
**RTO (Recovery Time Objective):** < 15 minutes

## Failure Scenarios

### Scenario 1: Complete Regional Outage

**Detection:**
```bash
# Check cluster health
kubectl get kafka prod-kafka -n kafka

# All pods down/unreachable
```

**Response:**

1. **Verify DR cluster is healthy**
```bash
# Switch to DR context
kubectl config use-context dr-cluster

# Check Kafka cluster
kubectl get kafka dr-kafka -n kafka

# Verify brokers running
kubectl get pods -n kafka -l app.kubernetes.io/name=kafka
```

2. **Check replication lag**
```bash
# Check MirrorMaker2 lag
kubectl logs -n kafka -l app.kubernetes.io/name=mirrormaker2 | grep lag
```

3. **Stop producers on primary** (if possible)
```bash
# Update DNS or notify teams to stop
# Wait for MirrorMaker2 to catch up (< 1 min)
```

4. **Promote DR cluster**
```bash
# Update DNS/Load Balancer to DR endpoints
# Update CNAME: kafka.example.com → dr-kafka-bootstrap.example.com

# Or update in load balancer configuration
```

5. **Update consumer offsets** (if needed)
```bash
# Consumers should automatically use replicated offsets
# Verify consumer groups
kubectl exec -n kafka dr-kafka-0 -c kafka -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

6. **Start producers on DR**
```bash
# Notify application teams
# Update producer configurations to DR endpoints
# Start publishing to DR cluster
```

7. **Verify operations**
```bash
# Run smoke test
./scripts/testing/smoke-test.sh --env dr

# Monitor dashboards
kubectl port-forward -n monitoring svc/grafana 3000:80
```

**Timeline:**
- Detection: 0-2 minutes
- Verification: 2-5 minutes
- Failover: 5-10 minutes
- Validation: 10-15 minutes
- **Total: ~15 minutes**

### Scenario 2: Partial Cluster Failure

**Example:** 2 out of 3 brokers down

**Response:**

1. **Assess damage**
```bash
# Check running brokers
kubectl get pods -n kafka

# Check under-replicated partitions
./scripts/admin/check-isr.sh

# Check offline partitions
kubectl exec -n kafka prod-kafka-0 -c kafka -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --describe --unavailable-partitions
```

2. **Determine if failover needed**

**If:**
- `min.insync.replicas` can be maintained → Stay on primary
- Cannot maintain ISR → Failover to DR

3. **If staying on primary:**
```bash
# Restart failed brokers
kubectl delete pod prod-kafka-1 prod-kafka-2 -n kafka

# Wait for recovery
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kafka -n kafka --timeout=600s

# Verify ISR recovery
./scripts/admin/check-isr.sh
```

4. **If failing over:**
- Follow "Complete Regional Outage" procedure

### Scenario 3: Data Corruption

**Detection:**
```bash
# Check logs for corruption errors
kubectl logs -n kafka prod-kafka-0 -c kafka | grep -i corrupt

# Example: "Found invalid message"
```

**Response:**

1. **Stop affected broker**
```bash
# Scale down to remove corrupted broker
kubectl patch kafka prod-kafka -n kafka --type='json' \
  -p='[{"op": "add", "path": "/spec/kafka/template/pod/metadata/annotations/strimzi.io~1delete-claim", "value": "true"}]'

kubectl delete pod prod-kafka-0 -n kafka
```

2. **Option A: Restore from replica**
```bash
# Kafka will automatically replicate from other brokers
# Wait for new pod to start and sync
```

3. **Option B: Restore from DR**
```bash
# If all replicas corrupted
# 1. Stop MirrorMaker2 from primary
# 2. Reverse MirrorMaker2 direction (DR → Primary)
# 3. Restore data
```

## Failback Procedure

After primary region recovers:

1. **Verify primary cluster is healthy**
```bash
kubectl config use-context primary-cluster
kubectl get kafka prod-kafka -n kafka
./scripts/testing/smoke-test.sh --env prod
```

2. **Configure reverse replication**
```bash
# Update MirrorMaker2 to replicate DR → Primary
# This catches up primary with any new data
```

3. **Monitor replication lag**
```bash
# Wait until primary is caught up
# Lag should be < 1 minute
```

4. **Planned cutover** (during maintenance window)

```bash
# Stop producers on DR
# Update DNS to primary
# Start producers on primary
```

5. **Resume normal MirrorMaker2 direction**
```bash
# Reconfigure MirrorMaker2: Primary → DR
```

## Testing DR

**Quarterly DR drill:**

1. **Announce drill**
```bash
# Notify all stakeholders
# Schedule maintenance window
```

2. **Simulate failure**
```bash
# Scale down primary cluster
kubectl scale kafka prod-kafka -n kafka --replicas=0
```

3. **Execute failover**
```bash
# Follow failover procedure
# Update DNS
# Verify applications working on DR
```

4. **Measure metrics**
```yaml
Detection time: ___ minutes
Failover time: ___ minutes
Data loss: ___ messages
Application downtime: ___ minutes
```

5. **Failback**
```bash
# Follow failback procedure
# Return to primary
```

6. **Document lessons learned**

## Checklists

### Pre-Failover Checklist

- [ ] Verify DR cluster health
- [ ] Check MirrorMaker2 replication lag
- [ ] Notify stakeholders (if planned)
- [ ] Document primary failure details
- [ ] Verify backup configurations available
- [ ] Confirm access to DR cluster

### Failover Checklist

- [ ] Stop producers on primary (if possible)
- [ ] Wait for MirrorMaker2 to catch up
- [ ] Update DNS/Load Balancer to DR
- [ ] Verify consumer offsets replicated
- [ ] Start producers on DR
- [ ] Run smoke tests
- [ ] Monitor dashboards for 1 hour
- [ ] Document failover timeline

### Failback Checklist

- [ ] Verify primary fully recovered
- [ ] Configure reverse replication
- [ ] Wait for primary to catch up
- [ ] Schedule maintenance window
- [ ] Stop producers on DR
- [ ] Update DNS to primary
- [ ] Start producers on primary
- [ ] Resume normal MirrorMaker2
- [ ] Monitor for 24 hours

## Monitoring & Alerts

**Critical alerts during DR:**
```yaml
- MirrorMaker2 lag > 1 minute
- DR cluster under-replicated partitions
- DR cluster offline partitions
- DR cluster disk usage > 80%
```

**Dashboard:**
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# Navigate to "Disaster Recovery" dashboard
```

## Communication Plan

**Stakeholders:**
1. Application teams
2. Infrastructure team
3. Management
4. On-call engineer

**Templates:**

**Incident Start:**
```
INCIDENT: Kafka Primary Cluster Failure
Status: Failover in progress
Impact: Potential message delays
ETA: 15 minutes
Action: Monitoring DR cluster activation
```

**Incident Resolution:**
```
RESOLVED: Kafka Failover Complete
Status: Running on DR cluster
Impact: Service restored
Failback: Planned for [DATE/TIME]
```

## Emergency Contacts

```yaml
Platform Team Lead: +1-XXX-XXX-XXXX
On-Call Engineer: PagerDuty
AWS Support: Premium Support
Confluent Support: Enterprise
```

## Post-Incident

1. **Document timeline**
2. **Calculate metrics** (RPO, RTO achieved)
3. **Root cause analysis**
4. **Update runbooks** if needed
5. **Test improvements** in next drill

## References

- [MirrorMaker2 Configuration](../k8s/strimzi/base/mirrormaker2.yaml)
- [Monitoring Setup](../k8s/monitoring/)
- [Architecture Diagram](../README.md#architecture-overview)
