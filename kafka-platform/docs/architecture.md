# Architecture Deep Dive

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (Region)                           │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.x.0.0/16)                         │   │
│  │                                                               │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │   │
│  │  │  AZ-1        │  │  AZ-2        │  │  AZ-3        │      │   │
│  │  │              │  │              │  │              │      │   │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │      │   │
│  │  │ │ Kafka    │ │  │ │ Kafka    │ │  │ │ Kafka    │ │      │   │
│  │  │ │ Broker-0 │ │  │ │ Broker-1 │ │  │ │ Broker-2 │ │      │   │
│  │  │ │          │ │  │ │          │ │  │ │          │ │      │   │
│  │  │ │ 2TB gp3  │ │  │ │ 2TB gp3  │ │  │ │ 2TB gp3  │ │      │   │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │      │   │
│  │  │              │  │              │  │              │      │   │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │      │   │
│  │  │ │ Connect  │ │  │ │ Connect  │ │  │ │ Schema   │ │      │   │
│  │  │ │ Worker   │ │  │ │ Worker   │ │  │ │ Registry │ │      │   │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │      │   │
│  │  │              │  │              │  │              │      │   │
│  │  │ Private      │  │ Private      │  │ Private      │      │   │
│  │  │ Subnet       │  │ Subnet       │  │ Subnet       │      │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘      │   │
│  │                                                               │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │   │
│  │  │ Public       │  │ Public       │  │ Public       │      │   │
│  │  │ Subnet       │  │ Subnet       │  │ Subnet       │      │   │
│  │  │              │  │              │  │              │      │   │
│  │  │ ┌──────┐     │  │ ┌──────┐     │  │ ┌──────┐     │      │   │
│  │  │ │ NAT  │     │  │ │ NAT  │     │  │ │ NAT  │     │      │   │
│  │  │ │  GW  │     │  │ │  GW  │     │  │ │  GW  │     │      │   │
│  │  │ └──────┘     │  │ └──────┘     │  │ └──────┘     │      │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘      │   │
│  │                                                               │   │
│  │                       ┌───────────────┐                      │   │
│  │                       │   NLB (L4)    │                      │   │
│  │                       │ External Access│                     │   │
│  │                       └───────────────┘                      │   │
│  │                                                               │   │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │              EKS Control Plane (Managed by AWS)                │  │
│  │                                                                 │  │
│  │  • Strimzi Operator  • External Secrets  • Prometheus          │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                   AWS Services                                  │  │
│  │  • Secrets Manager  • CloudWatch  • IAM  • Route53             │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

External Clients → NLB → Kafka Brokers (Port 9094, TLS + SASL)
Internal Clients → ClusterIP → Kafka Brokers (Port 9092, TLS + SASL)
```

## Component Interactions

### Data Flow: Producer → Kafka → Consumer

```
┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│ Producer │  ───→   │   NLB    │  ───→   │  Broker  │  ───→   │ Consumer │
│          │  TLS+   │          │  TLS+   │  Leader  │  TLS+   │          │
│ (Client) │  SASL   │  (9094)  │  SASL   │  (9092)  │  SASL   │ (Client) │
└──────────┘         └──────────┘         └──────────┘         └──────────┘
                                                │
                                                │ Replication
                                                ↓
                                         ┌──────────┐
                                         │ Follower │
                                         │ Brokers  │
                                         │  (RF=3)  │
                                         └──────────┘
```

### Security Flow

```
1. Client Request
   └─→ 2. TLS Handshake
       └─→ 3. SASL Authentication (SCRAM-SHA-512)
           └─→ 4. ACL Authorization Check
               └─→ 5. Request Processing
                   └─→ 6. Response (Encrypted)
```

### Monitoring Flow

```
┌──────────┐
│  Kafka   │  ─┐
│ Brokers  │   │  JMX Metrics
└──────────┘   │  (Port 9404)
               │
┌──────────┐   │
│ Connect  │  ─┤
└──────────┘   │
               │
┌──────────┐   │
│ Schema   │  ─┘
│ Registry │
└──────────┘
      │
      ↓
┌──────────┐
│Prometheus│  ─→  Scrapes every 30s
└──────────┘      Evaluates alerts
      │
      ↓
┌──────────┐
│ Grafana  │  ─→  Visualizes metrics
└──────────┘      Real-time dashboards
```

## Network Architecture

### Listener Configuration

```yaml
Internal Listener (plain):
  Port: 9092
  Type: ClusterIP
  Protocol: SASL_SSL
  Use: In-cluster clients
  
External Listener (external):
  Port: 9094
  Type: LoadBalancer (NLB)
  Protocol: SASL_SSL
  Use: External clients
  Advertised: kafka-{0,1,2}.example.com
```

### Security Groups

```
┌─────────────────────────────────────┐
│     EKS Worker Node SG              │
│                                     │
│  Inbound:                           │
│  • 9092 from VPC CIDR (internal)   │
│  • 9094 from NLB SG (external)     │
│  • 9404 from Prometheus (metrics)  │
│  • 1025-65535 from self (node comm)│
│                                     │
│  Outbound:                          │
│  • All traffic (0.0.0.0/0)         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│     NLB Security Group              │
│                                     │
│  Inbound:                           │
│  • 9094 from 0.0.0.0/0 (TLS only)  │
│                                     │
│  Outbound:                          │
│  • 9094 to Worker Node SG          │
└─────────────────────────────────────┘
```

## Storage Architecture

### Volume Layout

```
Each Broker Pod:
┌────────────────────────────────┐
│  /var/lib/kafka/data/          │
│                                │
│  ┌──────────────────────────┐ │
│  │ kafka-log0/              │ │  ← Journal/Data
│  │  ├─ topic-0-partition-0  │ │
│  │  ├─ topic-0-partition-1  │ │
│  │  └─ ...                  │ │
│  └──────────────────────────┘ │
│                                │
│  Type: EBS gp3                │
│  Size: 2 TB                   │
│  IOPS: 16,000                 │
│  Throughput: 1,000 MB/s       │
│  Encryption: Yes (at rest)    │
└────────────────────────────────┘
```

### Partition Distribution

```
Topic: orders (12 partitions, RF=3)

Broker-0: [P0-L, P1-F, P2-F, P3-L, ...]  (L=Leader, F=Follower)
Broker-1: [P0-F, P1-L, P2-F, P4-L, ...]
Broker-2: [P0-F, P1-F, P2-L, P5-L, ...]

Rack Awareness ensures followers in different AZs
```

## KRaft Mode Architecture

```
Traditional (ZooKeeper):
┌──────────┐     ┌──────────┐
│ ZooKeeper│ ←─→ │  Kafka   │
│ Ensemble │     │ Brokers  │
└──────────┘     └──────────┘
  3 nodes         3 nodes
  = 6 total nodes

KRaft (New):
┌──────────────────────────┐
│  Kafka Nodes             │
│  (Combined Controller +  │
│   Broker or Separate)    │
└──────────────────────────┘
  3 nodes = 3 total nodes

Benefits:
✓ Simpler deployment
✓ Faster failover (<200ms)
✓ Better scalability
✓ Unified security
```

### Controller Quorum

```
Controllers (Raft consensus):
┌─────────┐   ┌─────────┐   ┌─────────┐
│Controller│←→│Controller│←→│Controller│
│    1     │  │    2     │  │    3     │
│ (Leader) │  │(Follower)│  │(Follower)│
└─────────┘   └─────────┘   └─────────┘
     │
     └─→ Manages cluster metadata
         • Topic configs
         • Partition assignments
         • Leader elections
```

## Disaster Recovery Architecture

```
Primary Region (us-east-1)         DR Region (us-west-2)
┌────────────────────┐            ┌────────────────────┐
│   Prod Cluster     │            │    DR Cluster      │
│                    │            │                    │
│  ┌──────────────┐  │            │  ┌──────────────┐  │
│  │   Broker 0   │  │            │  │   Broker 0   │  │
│  │   Broker 1   │  │            │  │   Broker 1   │  │
│  │   Broker 2   │  │            │  │   Broker 2   │  │
│  └──────────────┘  │            │  └──────────────┘  │
│                    │            │                    │
└────────────────────┘            └────────────────────┘
         │                                   ▲
         │        MirrorMaker2               │
         └───────────────────────────────────┘
         
Replication:
• Topics: All application topics
• Offsets: Consumer group offsets
• ACLs: Optionally replicated
• Lag: < 1 minute
```

## Scaling Patterns

### Vertical Scaling

```
Current: m5.2xlarge         →    Target: m5.4xlarge
  8 vCPU, 32 GB RAM              16 vCPU, 64 GB RAM
  
Process:
1. Update Terraform config
2. Apply changes (rolling update)
3. Verify performance improvement
```

### Horizontal Scaling

```
Current: 3 brokers          →    Target: 6 brokers

Process:
1. Update Kafka CR (replicas: 6)
2. Strimzi creates new pods
3. Run partition reassignment
4. Rebalance data across brokers
5. Monitor ISR status
```

## References

- [Kafka KRaft Documentation](https://kafka.apache.org/documentation/#kraft)
- [Strimzi Architecture](https://strimzi.io/docs/operators/latest/overview.html)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
