# Capacity Planning Guide

## Overview

This guide helps you plan and size your Kafka cluster for production workloads.

## Key Metrics

### Throughput Planning

**Partition Throughput:**
- Write: 10-100 MB/s per partition (depends on message size, compression)
- Read: 50-200 MB/s per partition (replicas can serve reads)

**Broker Throughput:**
- Network: Limited by NIC (typically 1-10 Gbps)
- Disk: Limited by IOPS and throughput (gp3: 16,000 IOPS, 1,000 MB/s)
- CPU: Depends on compression, encryption, replication

### Storage Planning

**Formula:**
```
Total Storage = (Messages/sec × Avg Message Size × Retention Period) × Replication Factor
```

**Example: 100 MB/s ingress rate**
```
Messages/sec: 100 MB/s
Retention: 7 days = 604,800 seconds
Replication Factor: 3
Compression Ratio: 3:1 (typical for text/JSON)

Uncompressed: 100 MB/s × 604,800s × 3 = 181.44 TB
Compressed: 181.44 TB / 3 = 60.48 TB
With 30% buffer: 78.62 TB
```

**Storage per Broker (3 brokers):**
```
78.62 TB / 3 = 26.2 TB per broker
```

## Sizing Recommendations

### Development Environment

```yaml
Brokers: 1
Controllers: 1 (KRaft)
Instance Type: m5.xlarge (4 vCPU, 16 GB RAM)
Storage: 100 GB gp3
Expected Throughput: 10-50 MB/s
Use Case: Testing, development, CI/CD
```

### Staging Environment

```yaml
Brokers: 3
Controllers: 3 (KRaft, can be combined with brokers)
Instance Type: m5.2xlarge (8 vCPU, 32 GB RAM)
Storage: 500 GB gp3 per broker
Expected Throughput: 50-100 MB/s
Use Case: Pre-production testing, load testing
```

### Production Environment - Small

```yaml
Brokers: 3
Controllers: 3 (separate or combined)
Instance Type: m5.2xlarge (8 vCPU, 32 GB RAM)
Storage: 2 TB gp3 per broker
Network: Up to 10 Gbps
Expected Throughput: 100-300 MB/s
Topics: 50-100
Partitions: 500-1,000
Use Case: Small to medium production workloads
```

### Production Environment - Large

```yaml
Brokers: 6-12
Controllers: 3 (dedicated)
Instance Type: m5.4xlarge (16 vCPU, 64 GB RAM)
Storage: 5-10 TB gp3 per broker
Network: 10+ Gbps
Expected Throughput: 500+ MB/s
Topics: 100-500
Partitions: 2,000-10,000
Use Case: Large production workloads, high throughput
```

## Partition Sizing

### Number of Partitions

**Recommended:**
- Start with `num_brokers × 2 to 4`
- For high throughput topics: `num_brokers × 10 to 20`
- Maximum per broker: ~4,000 partitions

**Example for 3 brokers:**
```
Low traffic topic: 6 partitions (2 per broker)
Medium traffic topic: 12 partitions (4 per broker)
High traffic topic: 24-60 partitions (8-20 per broker)
```

**Considerations:**
- More partitions = higher throughput (up to a point)
- More partitions = more overhead (file handles, memory)
- More partitions = slower leader election
- Cannot reduce partition count (only increase)

### Partition Size

**Recommended:**
- Segment size: 1 GB (default)
- Max partition size: 100-500 GB
- Keep partitions evenly distributed

## Replication Factor

**Recommendations:**
```
Development: RF=1
Staging: RF=2
Production: RF=3
Critical data: RF=3 with min.insync.replicas=2
```

**Trade-offs:**
- RF=3: Survives 2 broker failures
- RF=2: Survives 1 broker failure
- RF=1: No redundancy (not recommended)

## Retention Policies

### Time-Based Retention

```properties
# 7 days (recommended for most use cases)
retention.ms=604800000

# 30 days (for audit logs, compliance)
retention.ms=2592000000

# Infinite (use with log compaction)
retention.ms=-1
```

### Size-Based Retention

```properties
# Per partition size limit
retention.bytes=107374182400  # 100 GB

# Topic-level limit
# retention.bytes × num_partitions
```

### Log Compaction

**Use cases:**
- Changelog topics (database CDC)
- Configuration topics
- State stores

```properties
cleanup.policy=compact
min.cleanable.dirty.ratio=0.5
segment.ms=604800000  # 7 days
```

## Memory Allocation

### Broker JVM Heap

**Formula:**
```
Heap Size = 4-6 GB base + (Num Partitions / 1000) GB
```

**Examples:**
```
1,000 partitions: 4-6 GB heap
2,000 partitions: 6-8 GB heap
4,000 partitions: 8-10 GB heap
```

**Settings:**
```bash
-Xms6g -Xmx6g  # 6 GB heap
-XX:+UseG1GC
-XX:MaxGCPauseMillis=20
```

### OS Page Cache

**Recommendation:**
- Leave 60-70% of RAM for OS page cache
- Kafka relies heavily on page cache for performance

**Example (32 GB instance):**
```
JVM Heap: 8 GB
Page Cache: 20 GB
OS/Other: 4 GB
```

## Network Planning

### Bandwidth Requirements

**Formula:**
```
Network Bandwidth = Ingress + (Ingress × RF) + (Ingress × Consumer_Count)
```

**Example:**
```
Ingress: 100 MB/s
RF: 3
Consumers: 5

Replication: 100 MB/s × 3 = 300 MB/s
Consumer reads: 100 MB/s × 5 = 500 MB/s
Total: 100 + 300 + 500 = 900 MB/s (~7.2 Gbps)
```

**Recommendation:**
- Use 10 Gbps network for production
- Enable jumbo frames (MTU 9000) for better performance

## Cost Optimization

### AWS Costs (us-east-1)

**Production Cluster (3 brokers):**
```
Compute:
- 3 × m5.2xlarge: $0.384/hr × 3 × 730 hrs = $841/month

Storage:
- 3 × 2 TB gp3: $0.08/GB × 2000 × 3 = $480/month

Network:
- Data transfer: ~$0.09/GB (varies by usage)
- NLB: ~$25/month

Total: ~$1,350-1,500/month
```

**Cost Reduction Tips:**
1. Use Reserved/Savings Plans (30-50% discount)
2. Enable compression (snappy, lz4)
3. Optimize retention periods
4. Use gp3 instead of io2 (cheaper, better)
5. Clean up unused topics

## Performance Tuning

### Producer Settings

```properties
# Throughput
batch.size=16384
linger.ms=10
compression.type=snappy
buffer.memory=33554432

# Reliability
acks=all
enable.idempotence=true
max.in.flight.requests.per.connection=5
```

### Consumer Settings

```properties
# Throughput
fetch.min.bytes=1
fetch.max.wait.ms=500
max.poll.records=500

# Parallelism
num.consumer.fetchers=4
```

### Broker Settings

```properties
# Network threads
num.network.threads=8
num.io.threads=16

# Replication
num.replica.fetchers=4
replica.fetch.max.bytes=1048576

# Log
log.segment.bytes=1073741824  # 1 GB
log.retention.check.interval.ms=300000
```

## Monitoring Thresholds

### Key Metrics to Watch

```yaml
Under-Replicated Partitions: 0
Offline Partitions: 0
CPU Usage: < 70%
Memory Usage: < 80%
Disk Usage: < 75%
Network Usage: < 70% of capacity
ISR Shrink Rate: Low
Leader Election Rate: Low
```

## Scaling Guidelines

### When to Scale Up (Vertical)

- CPU consistently > 70%
- Network saturation
- Disk I/O bottleneck

### When to Scale Out (Horizontal)

- Storage capacity exhausted
- Need higher aggregate throughput
- More fault tolerance required

### Scaling Process

1. Add new brokers
2. Create partition reassignment plan
3. Execute reassignment during off-peak
4. Monitor replication progress
5. Verify data distribution

## Checklist

**Before Production:**
- [ ] Size cluster based on expected throughput
- [ ] Calculate storage requirements with buffer
- [ ] Plan partition count per topic
- [ ] Set appropriate retention policies
- [ ] Configure replication factor (RF=3)
- [ ] Allocate JVM heap properly
- [ ] Enable monitoring and alerting
- [ ] Test failover scenarios
- [ ] Document capacity plans
- [ ] Plan for growth (6-12 months)

## References

- [Kafka Documentation - Operations](https://kafka.apache.org/documentation/#operations)
- [Confluent Capacity Planning](https://docs.confluent.io/platform/current/kafka/deployment.html)
- [AWS EBS gp3 Specs](https://aws.amazon.com/ebs/general-purpose/)
