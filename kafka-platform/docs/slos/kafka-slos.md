# Service Level Objectives (SLOs)

## Overview

This document defines the Service Level Objectives (SLOs) for the Kafka platform.

## Availability SLOs

### Production Cluster

**Target Availability: 99.9% (Three Nines)**
- Monthly downtime budget: 43.8 minutes
- Quarterly downtime budget: 131.4 minutes
- Annual downtime budget: 525.6 minutes

**Measurement:**
```
Availability = (Total Time - Downtime) / Total Time × 100%
```

**Definition of Downtime:**
- Unable to produce messages (acks=all fails)
- Unable to consume messages
- Data loss occurred
- More than 50% of brokers unavailable

**Excluded from Downtime:**
- Planned maintenance (with 7-day notice)
- Client errors (invalid requests)
- Upstream/downstream service issues
- Network issues outside our control

### Development/Staging

**Target Availability: 99.0%**
- Monthly downtime budget: 7.2 hours

## Performance SLOs

### Latency

**Producer Latency (P99):**
```yaml
Target: < 100ms
Measurement: Time from send() to ack received
Conditions: acks=all, normal load
```

**Consumer Latency (P99):**
```yaml
Target: < 50ms
Measurement: Time from message arrival to delivery
Conditions: Single consumer, normal load
```

**End-to-End Latency (P95):**
```yaml
Target: < 150ms
Measurement: Producer send to consumer receive
Conditions: Normal operation
```

### Throughput

**Production:**
```yaml
Minimum: 100 MB/s aggregate
Target: 300 MB/s aggregate
Peak capacity: 500 MB/s
```

**Consumption:**
```yaml
Minimum: 200 MB/s aggregate
Target: 600 MB/s aggregate
```

## Durability SLOs

### Data Durability

**Target: 99.999% (Five Nines)**
- No data loss under normal operations
- Maximum data loss: 1 minute of data during catastrophic failure

**Guarantees:**
```yaml
Replication Factor: 3
min.insync.replicas: 2
unclean.leader.election: false
acks: all (for critical topics)
```

**Backup & Recovery:**
```yaml
RPO (Recovery Point Objective): < 1 minute
RTO (Recovery Time Objective): < 15 minutes
```

## Capacity SLOs

### Storage

**Target Utilization: < 75%**
```yaml
Warning: 70%
Critical: 80%
Action: Scale storage before 75%
```

**Message Retention:**
```yaml
Standard topics: 7 days
Audit topics: 30 days
Changelog topics: Infinite (compacted)
```

### Partitions

**Maximum per Broker: 4,000 partitions**
```yaml
Warning: 3,000
Target: 2,000-2,500
```

**Per Topic:**
```yaml
Recommended: 12-24 partitions
Maximum: 100 partitions
```

## Operational SLOs

### Deployment Success Rate

**Target: 95%**
```yaml
Definition: Successful deployment without rollback
Excluded: Failed due to config errors
```

### Time to Deploy

**Target: < 30 minutes**
```yaml
Measurement: Git commit to production ready
Includes: CI/CD pipeline + deployment
```

### Time to Detect Incidents

**Target: < 5 minutes**
```yaml
Measurement: Issue occurrence to alert fired
Method: Prometheus alerting
```

### Time to Resolve

**Priority levels:**
```yaml
P0 (Critical): < 1 hour
  - Cluster down
  - Data loss
  - Security breach

P1 (High): < 4 hours
  - Degraded performance
  - Single broker down
  - High consumer lag

P2 (Medium): < 1 business day
  - Non-critical bugs
  - Documentation issues

P3 (Low): < 1 week
  - Enhancement requests
  - Nice-to-have features
```

## Quality SLOs

### Error Rate

**Producer Errors:**
```yaml
Target: < 0.1%
Measurement: Failed produce requests / total requests
```

**Consumer Errors:**
```yaml
Target: < 0.1%
Measurement: Failed fetch requests / total requests
```

### Rebalance Frequency

**Target: < 1 per hour per consumer group**
```yaml
Measurement: Consumer group rebalances
Impact: Temporary processing pause
```

## Monitoring & Alerting SLOs

### Alert Accuracy

**Target: 90% of alerts are actionable**
```yaml
Definition: Alert leads to action or change
Measurement: Actionable alerts / total alerts
```

### Alert Response Time

**Target: < 15 minutes**
```yaml
Measurement: Alert fired to acknowledged
Applies to: P0 and P1 alerts
```

### False Positive Rate

**Target: < 10%**
```yaml
Definition: Alert that doesn't require action
Measurement: False positives / total alerts
```

## Compliance SLOs

### Security Patch Application

**Target: < 7 days for critical patches**
```yaml
High severity: < 14 days
Medium severity: < 30 days
Low severity: Next maintenance window
```

### Audit Log Retention

**Target: 90 days minimum**
```yaml
Format: Structured JSON
Storage: CloudWatch Logs
```

### Secret Rotation

**Target: Every 90 days**
```yaml
TLS certificates: Auto-rotated
SCRAM passwords: Manual or automated
API keys: Every 90 days
```

## Disaster Recovery SLOs

### Backup Success Rate

**Target: 100%**
```yaml
Method: MirrorMaker2 replication
Frequency: Continuous
Validation: Daily
```

### DR Failover Time

**Target: < 15 minutes**
```yaml
Detection: < 5 minutes
Decision: < 2 minutes
Execution: < 5 minutes
Validation: < 3 minutes
```

### DR Drill Success

**Target: 100% success**
```yaml
Frequency: Quarterly
Scope: Full failover and failback
Documentation: Required
```

## SLO Monitoring

### Dashboards

**Real-time SLO Dashboard:**
```yaml
Location: Grafana
URL: http://grafana/d/kafka-slo
Refresh: 30 seconds
Metrics:
  - Availability %
  - Latency P99
  - Error rate
  - Throughput
  - Capacity utilization
```

**SLO Burn Rate:**
```yaml
Fast burn: Alert if SLO budget consumed in < 1 hour
Slow burn: Alert if SLO budget consumed in < 6 hours
```

### Reporting

**Weekly SLO Report:**
```markdown
- Availability: XX.XX%
- Budget remaining: XX.X minutes
- Incidents: X
- Latency P99: XXms
- Error rate: X.XX%
```

**Monthly SLO Review:**
```markdown
- SLO achievement summary
- Incidents root cause analysis
- Improvement actions
- Trend analysis
```

## SLO Budget Policy

### Error Budget

**Calculation:**
```
Error Budget = (1 - SLO) × Time Period
```

**Example (99.9% availability):**
```
Monthly error budget = (1 - 0.999) × 720 hours = 43.8 minutes
```

### Budget Consumption

**If budget > 50%:**
- Normal operations
- Focus on features

**If budget < 50%:**
- Reduce feature velocity
- Focus on reliability

**If budget < 25%:**
- Freeze features
- Emergency reliability work only

**If budget exhausted:**
- No deployments except critical fixes
- Postmortem required
- Recovery plan needed

## SLI (Service Level Indicators)

### Availability SLI

```promql
# Success rate
sum(rate(kafka_network_requestmetrics_totaltimems_count{request="Produce"}[5m])) 
- 
sum(rate(kafka_server_brokertopicmetrics_failedproducerequests_total[5m]))
/
sum(rate(kafka_network_requestmetrics_totaltimems_count{request="Produce"}[5m]))
```

### Latency SLI

```promql
# P99 latency
histogram_quantile(0.99, 
  rate(kafka_network_requestmetrics_totaltimems_bucket{request="Produce"}[5m])
)
```

### Throughput SLI

```promql
# Messages per second
sum(rate(kafka_server_brokertopicmetrics_messagesin_total[5m]))
```

## Review & Updates

**SLO Review Frequency:**
- Monthly: Check if SLOs met
- Quarterly: Review if SLOs appropriate
- Annually: Major SLO revision

**Stakeholders:**
- Platform team
- Application teams
- Management
- SRE team

**Process:**
1. Collect metrics
2. Analyze trends
3. Identify gaps
4. Propose changes
5. Get approval
6. Update documentation
7. Communicate changes

## References

- [Google SRE Book - SLOs](https://sre.google/sre-book/service-level-objectives/)
- [Prometheus Queries](../observability/alerts/)
- [Grafana Dashboards](../observability/dashboards/)
