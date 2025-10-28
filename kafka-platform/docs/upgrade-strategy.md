# Rolling Upgrade Strategy

## Overview

This document outlines the procedure for safely upgrading Kafka clusters with zero downtime.

## Pre-Upgrade Checklist

- [ ] Review release notes for breaking changes
- [ ] Backup cluster metadata and configurations
- [ ] Verify all brokers are healthy (no under-replicated partitions)
- [ ] Check Strimzi operator version compatibility
- [ ] Notify stakeholders of maintenance window
- [ ] Ensure monitoring is active
- [ ] Prepare rollback plan
- [ ] Test upgrade in dev/stage first

## Upgrade Types

### 1. Configuration Changes Only

**Steps:**
1. Update Kafka CR configuration
2. Trigger manual rolling update:
```bash
kubectl annotate kafka prod-kafka -n kafka \
  strimzi.io/manual-rolling-update=true
```
3. Monitor rollout:
```bash
kubectl get pods -n kafka -w
```

**Duration:** ~10-15 minutes per broker (sequential)

### 2. Kafka Version Upgrade

**Supported upgrade paths:**
- 3.5.x → 3.6.x ✅
- 3.4.x → 3.6.x ✅ (via 3.5.x)
- Skip versions: ⚠️ Not recommended

**Steps:**

#### Phase 1: Upgrade Strimzi Operator
```bash
# Update operator
kubectl replace -f 'https://strimzi.io/install/latest?namespace=kafka'

# Verify operator
kubectl get pods -n kafka -l name=strimzi-cluster-operator
```

#### Phase 2: Configure Upgrade
```yaml
# Edit kafka.yaml
spec:
  kafka:
    version: 3.6.0  # New version
    config:
      log.message.format.version: 3.5  # Keep old format initially
      inter.broker.protocol.version: 3.5
```

#### Phase 3: Rolling Upgrade Brokers
```bash
# Apply changes
kubectl apply -k k8s/strimzi/overlays/prod

# Watch progress
kubectl get pods -n kafka -w

# Verify each broker before continuing
./scripts/testing/smoke-test.sh --env prod
```

#### Phase 4: Update Protocol Versions
```yaml
# After all brokers upgraded
spec:
  kafka:
    version: 3.6.0
    config:
      log.message.format.version: 3.6
      inter.broker.protocol.version: 3.6
```

**Duration:** ~30-45 minutes

### 3. Strimzi Operator Upgrade

**Steps:**
```bash
# Backup CRDs
kubectl get crds -o yaml > kafka-crds-backup.yaml

# Update operator
kubectl replace -f 'https://strimzi.io/install/latest?namespace=kafka'

# Verify
kubectl get pods -n kafka -l name=strimzi-cluster-operator
```

## Monitoring During Upgrade

### Key Metrics to Watch

```bash
# Under-replicated partitions (should be 0)
kubectl exec -n kafka prod-kafka-0 -c kafka -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --describe --under-replicated-partitions

# ISR status
kubectl exec -n kafka prod-kafka-0 -c kafka -- \
  bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092

# Consumer lag
kubectl exec -n kafka prod-kafka-0 -c kafka -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

### Expected Behavior

✅ **Normal:**
- One broker at a time restarting
- Brief ISR shrink/expand during restart
- Leader elections
- Short consumer rebalances

❌ **Abnormal (STOP UPGRADE):**
- Multiple brokers down
- Persistent under-replicated partitions
- Failed broker startups
- Data corruption warnings

## Rollback Procedure

### If Upgrade Fails

```bash
# Immediate rollback
kubectl rollout undo statefulset prod-kafka -n kafka

# Or restore previous version in CR
kubectl apply -f kafka-backup.yaml

# Verify
kubectl get kafka prod-kafka -n kafka -o yaml
```

### If Protocol Version Changed

1. Cannot easily rollback
2. May need to restore from backup
3. **Prevention:** Always keep old protocol version initially

## Best Practices

### Timing
- Perform during low-traffic periods
- Allow 2-3 hours for production upgrades
- Upgrade dev → stage → prod

### Process
1. **Test in Dev/Stage First**
2. **One Change at a Time**
   - Upgrade Strimzi operator first
   - Then upgrade Kafka brokers
   - Finally update protocol versions
3. **Monitor Continuously**
4. **Document Everything**

### Safety Measures

```yaml
# Pod disruption budget (prevent multiple simultaneous restarts)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: kafka-pdb
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: kafka
```

## Automation

### GitOps Approach

```yaml
# Flux/ArgoCD reconciliation
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: kafka-prod
spec:
  interval: 10m
  path: ./k8s/strimzi/overlays/prod
  prune: false  # Don't auto-delete during upgrade
  healthChecks:
    - apiVersion: kafka.strimzi.io/v1beta2
      kind: Kafka
      name: prod-kafka
      namespace: kafka
```

## Emergency Procedures

### Broker Won't Start

```bash
# Check logs
kubectl logs -n kafka prod-kafka-0 -c kafka --tail=100

# Common issues:
# - Incompatible protocol versions
# - Corrupted logs
# - Resource constraints

# Resolution:
# 1. Fix configuration
# 2. Increase resources
# 3. Restore from backup if needed
```

### Split Brain / Data Loss

```bash
# Check replication status
kubectl exec -n kafka prod-kafka-0 -c kafka -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --describe

# If data loss detected:
# 1. Stop all writes
# 2. Assess extent
# 3. Restore from backup
# 4. Replay from source if possible
```

## Post-Upgrade Validation

```bash
# Run comprehensive tests
make smoke-test ENV=prod

# Verify metrics
kubectl port-forward -n monitoring svc/grafana 3000:80
# Check Kafka dashboards

# Performance test
./scripts/testing/perf-test.sh --env prod

# Monitor for 24 hours
# Watch for:
# - Consumer lag
# - Error rates
# - Under-replicated partitions
# - Unusual GC activity
```

## Upgrade Log Template

```markdown
## Kafka Upgrade Log

**Date:** YYYY-MM-DD
**Version:** 3.5.x → 3.6.0
**Performed by:** [Name]
**Environment:** Production

### Timeline
- 10:00 - Upgrade started
- 10:15 - Strimzi operator upgraded
- 10:30 - Kafka brokers upgrade started
- 11:00 - Broker 0 upgraded ✅
- 11:20 - Broker 1 upgraded ✅
- 11:40 - Broker 2 upgraded ✅
- 12:00 - Protocol versions updated
- 12:15 - Validation complete ✅

### Metrics
- Under-replicated partitions: 0
- Consumer lag: Normal
- Error rate: 0.01%
- Downtime: 0 seconds

### Issues
None

### Next Steps
- Monitor for 24 hours
- Update documentation
- Schedule next upgrade
```

## References

- [Strimzi Upgrade Guide](https://strimzi.io/docs/operators/latest/deploying.html#assembly-upgrade-str)
- [Kafka Upgrade Documentation](https://kafka.apache.org/documentation/#upgrade)
- [KRaft Migration Guide](https://kafka.apache.org/documentation/#kraft_migration)
