# Frequently Asked Questions (FAQ)

## General

### What is KRaft mode and why use it?

**KRaft** (Kafka Raft) is Kafka's built-in consensus protocol that replaces ZooKeeper:

**Benefits:**
- Simpler architecture (one less system to manage)
- Faster controller failover (<200ms vs seconds)
- Better scalability (supports millions of partitions)
- Unified security model
- Improved operational simplicity

**Migration:** ZooKeeper mode is being deprecated. All new clusters should use KRaft.

### What's the difference between brokers and controllers in KRaft?

- **Controllers:** Manage cluster metadata, leader elections, partition assignments
- **Brokers:** Store data, serve produce/consume requests

In KRaft mode, you can run:
- **Combined mode:** Same nodes act as both controllers and brokers (simpler, good for small clusters)
- **Separate mode:** Dedicated controller nodes (better for large production clusters)

### How many brokers do I need?

**Minimum for production:** 3 brokers (for RF=3)

**Scaling considerations:**
- Storage capacity needs
- Throughput requirements
- Partition count (max ~4,000 per broker)
- Fault tolerance (can lose RF-1 brokers)

## Replication

### What is ISR (In-Sync Replicas)?

ISR is the set of replicas that are fully caught up with the leader.

**Example:**
```
Topic: orders, Partition: 0
Leader: broker-1
ISR: [broker-1, broker-2, broker-3]
```

If broker-3 falls behind:
```
ISR: [broker-1, broker-2]
```

**Why it matters:** With `min.insync.replicas=2`, you need at least 2 brokers in ISR to accept writes.

### What happens if ISR < min.insync.replicas?

**Producer with `acks=all`:**
- Will receive `NotEnoughReplicasException`
- Writes are rejected to prevent data loss

**Recovery:**
1. Fix the lagging/down broker
2. Wait for replica to catch up
3. ISR will auto-expand

### Should I use `unclean.leader.election.enable=true`?

**Generally: NO**

```yaml
unclean.leader.election.enable: false  # Recommended
```

**Reason:** Prevents data loss by not allowing out-of-sync replicas to become leaders.

**Exception:** If availability is more important than consistency (rare).

## Performance

### How do I optimize throughput?

**Producer side:**
```properties
batch.size=32768
linger.ms=10
compression.type=snappy
acks=1  # or all for reliability
```

**Broker side:**
```properties
num.network.threads=8
num.io.threads=16
num.replica.fetchers=4
```

**Consumer side:**
```properties
fetch.min.bytes=1024
max.poll.records=500
```

### Why is my consumer slow?

**Common causes:**
1. **Processing time:** Business logic is slow
   - Solution: Increase parallelism (more partitions/consumers)
   
2. **Large messages:** Taking too long to fetch
   - Solution: Compress, split messages, increase fetch.max.bytes
   
3. **Consumer rebalancing:** Frequent rebalances
   - Solution: Increase max.poll.interval.ms, optimize processing
   
4. **Network latency:** Consumer is far from broker
   - Solution: Deploy consumers closer, use compression

### How many partitions should a topic have?

**Rule of thumb:**
```
Partitions = (Target Throughput / Consumer Throughput) × 2
```

**Example:**
- Target: 100 MB/s
- Single consumer: 10 MB/s
- Partitions needed: (100/10) × 2 = 20

**Limits:**
- Maximum per broker: ~4,000
- Maximum per cluster: ~200,000
- **Cannot decrease**, only increase

## Storage

### How much storage do I need?

**Formula:**
```
Storage = (Messages/sec × Avg Size × Retention) × RF / Compression Ratio
```

**Example (100 MB/s, 7 days, RF=3, compression=3x):**
```
= (100 MB/s × 604,800s × 3) / 3
= 60.48 TB
+ 30% buffer = 78.62 TB
```

**Per broker (3 brokers):** 26.2 TB each

### When should I use log compaction?

**Use cases:**
- Database changelogs (CDC)
- Configuration topics
- Any topic where you only need latest value per key

**Example:**
```yaml
cleanup.policy: compact
min.cleanable.dirty.ratio: 0.5
segment.ms: 604800000  # 7 days
```

**How it works:** Keeps only the latest value for each key, deletes older duplicates.

## Security

### How do I secure Kafka?

**Required for production:**

1. **Encryption (TLS/mTLS):**
   ```yaml
   listeners:
     - name: external
       port: 9094
       type: loadbalancer
       tls: true
   ```

2. **Authentication (SASL):**
   ```yaml
   authentication:
     type: scram-sha-512
   ```

3. **Authorization (ACLs):**
   ```bash
   bin/kafka-acls.sh --add \
     --allow-principal User:app-producer \
     --operation WRITE \
     --topic orders
   ```

4. **Network policies:**
   - Restrict broker-to-broker communication
   - Limit external access

### How do I rotate credentials?

**SCRAM users:**
```bash
./scripts/bootstrap/create-users.sh --rotate --user app-producer
```

**TLS certificates:**
- Strimzi auto-rotates cluster CA
- Client certificates: use cert-manager

**Frequency:** Every 90 days recommended

## Operations

### How do I add a new broker?

**With Strimzi:**
```yaml
# Edit kafka.yaml
spec:
  kafka:
    replicas: 4  # was 3
```

```bash
kubectl apply -k k8s/strimzi/overlays/prod
```

**Then rebalance partitions:**
```bash
./scripts/admin/reassign-partitions.py --broker-id 3 --generate
./scripts/admin/reassign-partitions.py --execute
```

### How do I handle broker failure?

**Automatic recovery (RF=3):**
- Cluster continues operating
- Remaining brokers serve all partitions
- ISR shrinks but maintains min.insync.replicas

**Manual steps:**
1. Identify failed broker
2. Check for under-replicated partitions
3. If temporary: wait for recovery
4. If permanent: replace broker (see runbook)

### How do I increase partitions for a topic?

**Command:**
```bash
./scripts/admin/create-topic.sh \
  --name orders \
  --partitions 24 \
  --alter
```

**Notes:**
- Can only increase, never decrease
- Existing messages stay in old partitions
- May affect message ordering
- Consumer rebalance will occur

## Monitoring

### What metrics should I monitor?

**Critical:**
- Under-replicated partitions (should be 0)
- Offline partitions (should be 0)
- ISR shrink/expand rate
- Consumer lag
- Disk usage

**Important:**
- Request latency (P99 < 100ms)
- Throughput (MB/s)
- CPU/Memory usage
- GC pause time
- Error rates

**Access:**
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### How do I check consumer lag?

**Command:**
```bash
kubectl exec -n kafka prod-kafka-0 -c kafka -- \
  bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe --group my-group
```

**Grafana dashboard:** "Consumer Lag" dashboard

**What's acceptable?**
- Real-time processing: < 1 second
- Batch processing: < 1 hour
- Depends on your SLA

## Troubleshooting

### Producer getting "NotEnoughReplicasException"

**Cause:** ISR < min.insync.replicas

**Solutions:**
1. Check broker health: `kubectl get pods -n kafka`
2. Check under-replicated partitions
3. Fix unhealthy brokers
4. Wait for ISR to recover

### Consumer group keeps rebalancing

**Common causes:**
1. **Processing too slow:** Exceeds max.poll.interval.ms
   - Increase max.poll.interval.ms
   - Reduce max.poll.records
   - Optimize processing logic

2. **Network issues:** Heartbeat not reaching broker
   - Check network connectivity
   - Increase session.timeout.ms

3. **Consumer crashes:** Keep dying and rejoining
   - Fix application bugs
   - Check resource limits

### "No space left on device" error

**Immediate:**
```bash
# Find largest topics
kubectl exec -n kafka prod-kafka-0 -c kafka -- \
  du -sh /var/lib/kafka/data/kafka-log*

# Emergency: delete old logs
kubectl exec -n kafka prod-kafka-0 -c kafka -- \
  find /var/lib/kafka/data -name "*.log" -mtime +7 -delete
```

**Long-term:**
1. Reduce retention period
2. Enable compression
3. Add more storage
4. Scale out (more brokers)

## Disaster Recovery

### How do I backup Kafka?

**What to backup:**
1. **Cluster metadata:** Kafka CRs, topics, configs
2. **Data:** MirrorMaker2 to DR cluster (preferred)
3. **Consumer offsets:** Included in DR replication

**Not recommended:** File-level backups (complex, error-prone)

### How do I failover to DR cluster?

**Prerequisites:**
- MirrorMaker2 running and synced
- DR cluster healthy
- Documented procedure

**Steps:**
1. Stop producers on primary
2. Verify DR is caught up
3. Update DNS/load balancer to DR
4. Start producers on DR
5. Update consumer offsets

**See:** [docs/runbooks/disaster-recovery.md](runbooks/disaster-recovery.md)

## Cost Optimization

### How can I reduce costs?

1. **Right-size instances:** Don't over-provision
2. **Use Savings Plans:** 30-50% discount
3. **Optimize retention:** Delete old data
4. **Enable compression:** Reduce storage/network
5. **Clean up unused topics**
6. **Use gp3 vs io2:** Better price/performance

**Example savings:**
- Compression (3x): $480/month → $160/month storage
- Reserved instances: $841/month → $505/month compute

## Getting Help

### Where can I find more information?

**Documentation:**
- This repository: [docs/](.)
- Strimzi: https://strimzi.io/docs/
- Apache Kafka: https://kafka.apache.org/documentation/

**Runbooks:**
- [Broker Replacement](runbooks/broker-replacement.md)
- [Disaster Recovery](runbooks/disaster-recovery.md)
- [Partition Rebalance](runbooks/partition-rebalance.md)

**Support:**
- GitHub Issues
- Slack: #kafka-platform
- On-call: PagerDuty

### How do I report a bug?

1. Check if already reported
2. Gather diagnostics:
   ```bash
   kubectl logs -n kafka prod-kafka-0 -c kafka --tail=100
   kubectl describe kafka prod-kafka -n kafka
   ./scripts/testing/diagnose.sh
   ```
3. Open GitHub issue with details
