#!/bin/bash
# Smoke test script for Kafka cluster

set -e

NAMESPACE="${KAFKA_NAMESPACE:-kafka}"
ENV="${1:-dev}"
KAFKA_POD="${ENV}-kafka-0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    exit 1
}

echo "======================================"
echo "Kafka Cluster Smoke Test - $ENV"
echo "======================================"
echo ""

# 1. Check if Kafka cluster exists
log_info "Checking Kafka cluster status..."
if ! kubectl get kafka "${ENV}-kafka" -n "$NAMESPACE" &>/dev/null; then
    log_error "Kafka cluster not found"
fi

# 2. Check if cluster is ready
log_info "Verifying cluster readiness..."
READY=$(kubectl get kafka "${ENV}-kafka" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
if [ "$READY" != "True" ]; then
    log_error "Kafka cluster is not ready"
fi

# 3. Check broker pods
log_info "Checking broker pods..."
REPLICAS=$(kubectl get kafka "${ENV}-kafka" -n "$NAMESPACE" -o jsonpath='{.spec.kafka.replicas}')
RUNNING_PODS=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=kafka -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
if [ "$RUNNING_PODS" -ne "$REPLICAS" ]; then
    log_error "Expected $REPLICAS running pods, found $RUNNING_PODS"
fi

# 4. Create test topic
TEST_TOPIC="smoke-test-$(date +%s)"
log_info "Creating test topic: $TEST_TOPIC..."
kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-topics.sh \
    --bootstrap-server localhost:9092 \
    --create --topic "$TEST_TOPIC" \
    --partitions 3 --replication-factor 1 &>/dev/null || log_error "Failed to create topic"

# 5. Produce test messages
log_info "Producing test messages..."
for i in {1..10}; do
    echo "Test message $i"
done | kubectl exec -i -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-console-producer.sh \
    --bootstrap-server localhost:9092 \
    --topic "$TEST_TOPIC" &>/dev/null || log_error "Failed to produce messages"

# 6. Consume test messages
log_info "Consuming test messages..."
MESSAGES=$(kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic "$TEST_TOPIC" \
    --from-beginning \
    --max-messages 10 \
    --timeout-ms 10000 2>/dev/null | wc -l)

if [ "$MESSAGES" -ne 10 ]; then
    log_error "Expected 10 messages, got $MESSAGES"
fi

# 7. Delete test topic
log_info "Cleaning up test topic..."
kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-topics.sh \
    --bootstrap-server localhost:9092 \
    --delete --topic "$TEST_TOPIC" &>/dev/null || log_warn "Failed to delete test topic"

# 8. Check for under-replicated partitions
log_info "Checking for under-replicated partitions..."
URP=$(kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-topics.sh \
    --bootstrap-server localhost:9092 \
    --describe --under-replicated-partitions 2>/dev/null | grep -v "^$" | wc -l)

if [ "$URP" -gt 0 ]; then
    log_warn "Found $URP under-replicated partitions"
else
    log_info "No under-replicated partitions found"
fi

# 9. Check cluster health metrics
log_info "Verifying metrics endpoint..."
if kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- curl -s http://localhost:9404/metrics | grep -q "kafka_server"; then
    log_info "Metrics endpoint is responding"
else
    log_warn "Metrics endpoint may not be working correctly"
fi

echo ""
echo "======================================"
log_info "Smoke test completed successfully!"
echo "======================================"
