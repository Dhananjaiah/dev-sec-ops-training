#!/bin/bash
# Performance testing script for Kafka

set -e

NAMESPACE="${KAFKA_NAMESPACE:-kafka}"
ENV="${1:-dev}"
KAFKA_POD="${ENV}-kafka-0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

usage() {
    echo "Usage: $0 [ENV]"
    echo ""
    echo "Options:"
    echo "  ENV    Environment (dev/stage/prod, default: dev)"
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 prod"
    exit 1
}

# Create test topic
create_test_topic() {
    local topic=$1
    local partitions=$2
    
    log_info "Creating test topic: $topic with $partitions partitions..."
    kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-topics.sh \
        --bootstrap-server localhost:9092 \
        --create --if-not-exists \
        --topic "$topic" \
        --partitions "$partitions" \
        --replication-factor 3 \
        --config min.insync.replicas=2 &>/dev/null || true
}

# Producer performance test
run_producer_perf_test() {
    local topic=$1
    local messages=$2
    local record_size=$3
    local throughput=$4
    
    log_section "Producer Performance Test"
    log_info "Topic: $topic"
    log_info "Messages: $messages"
    log_info "Record size: $record_size bytes"
    log_info "Target throughput: $throughput msg/sec"
    echo ""
    
    kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-producer-perf-test.sh \
        --topic "$topic" \
        --num-records "$messages" \
        --record-size "$record_size" \
        --throughput "$throughput" \
        --producer-props \
            bootstrap.servers=localhost:9092 \
            acks=all \
            compression.type=snappy \
            batch.size=16384 \
            linger.ms=10
}

# Consumer performance test
run_consumer_perf_test() {
    local topic=$1
    local messages=$2
    
    log_section "Consumer Performance Test"
    log_info "Topic: $topic"
    log_info "Messages to consume: $messages"
    echo ""
    
    kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-consumer-perf-test.sh \
        --bootstrap-server localhost:9092 \
        --topic "$topic" \
        --messages "$messages" \
        --threads 1 \
        --timeout 60000
}

# End-to-end latency test
run_latency_test() {
    local topic=$1
    
    log_section "End-to-End Latency Test"
    log_info "Topic: $topic"
    echo ""
    
    kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-run-class.sh \
        kafka.tools.EndToEndLatency \
        localhost:9092 \
        "$topic" \
        10000 \
        all \
        1024
}

# Cleanup test topics
cleanup() {
    log_info "Cleaning up test topics..."
    kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-topics.sh \
        --bootstrap-server localhost:9092 \
        --delete --if-exists \
        --topic perf-test-topic &>/dev/null || true
}

# Main execution
main() {
    echo "======================================"
    echo "Kafka Performance Test - $ENV"
    echo "======================================"
    echo ""
    
    # Configuration
    TOPIC="perf-test-topic"
    PARTITIONS=12
    
    # Test parameters
    NUM_MESSAGES=100000
    RECORD_SIZE=1024  # 1KB
    TARGET_THROUGHPUT=10000  # 10K msg/sec
    
    # Cleanup old test data
    cleanup
    
    # Create test topic
    create_test_topic "$TOPIC" "$PARTITIONS"
    sleep 2
    
    # Run tests
    run_producer_perf_test "$TOPIC" "$NUM_MESSAGES" "$RECORD_SIZE" "$TARGET_THROUGHPUT"
    echo ""
    
    run_consumer_perf_test "$TOPIC" "$NUM_MESSAGES"
    echo ""
    
    run_latency_test "$TOPIC"
    echo ""
    
    # Summary
    log_section "Test Summary"
    log_info "All performance tests completed"
    log_info "Topic: $TOPIC"
    log_info "Messages tested: $NUM_MESSAGES"
    log_info "Record size: $RECORD_SIZE bytes"
    echo ""
    
    # Cleanup
    cleanup
    
    echo "======================================"
    log_info "Performance test completed!"
    echo "======================================"
}

# Run main
main
