#!/bin/bash
# Topic management script for Kafka

set -e

# Default values
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP:-localhost:9092}"
NAMESPACE="${KAFKA_NAMESPACE:-kafka}"
ENV="${ENV:-dev}"
KAFKA_POD="${ENV}-kafka-0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --name TOPIC           Topic name (required for create/alter/delete/describe)"
    echo "  --partitions NUM       Number of partitions (default: 12)"
    echo "  --replication NUM      Replication factor (default: 3)"
    echo "  --list                 List all topics"
    echo "  --describe             Describe a topic"
    echo "  --alter                Alter topic configuration"
    echo "  --delete               Delete a topic"
    echo "  --config KEY=VALUE     Add topic configuration"
    echo "  --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Create a topic"
    echo "  $0 --name orders --partitions 24"
    echo ""
    echo "  # Create with custom retention"
    echo "  $0 --name events --partitions 12 --config retention.ms=604800000"
    echo ""
    echo "  # List all topics"
    echo "  $0 --list"
    echo ""
    echo "  # Describe a topic"
    echo "  $0 --name orders --describe"
    echo ""
    echo "  # Increase partitions"
    echo "  $0 --name orders --partitions 48 --alter"
    exit 1
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

exec_kafka_cmd() {
    kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-topics.sh \
        --bootstrap-server localhost:9092 "$@"
}

list_topics() {
    log_info "Listing all topics..."
    exec_kafka_cmd --list
}

describe_topic() {
    if [ -z "$TOPIC_NAME" ]; then
        log_error "Topic name is required for describe"
        usage
    fi
    
    log_info "Describing topic: $TOPIC_NAME"
    exec_kafka_cmd --describe --topic "$TOPIC_NAME"
}

create_topic() {
    if [ -z "$TOPIC_NAME" ]; then
        log_error "Topic name is required for create"
        usage
    fi
    
    log_info "Creating topic: $TOPIC_NAME"
    log_info "  Partitions: $PARTITIONS"
    log_info "  Replication factor: $REPLICATION_FACTOR"
    
    CMD_ARGS="--create --topic $TOPIC_NAME --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR"
    
    if [ -n "$TOPIC_CONFIG" ]; then
        log_info "  Config: $TOPIC_CONFIG"
        CMD_ARGS="$CMD_ARGS --config $TOPIC_CONFIG"
    fi
    
    exec_kafka_cmd $CMD_ARGS
    log_info "Topic created successfully"
}

alter_topic() {
    if [ -z "$TOPIC_NAME" ]; then
        log_error "Topic name is required for alter"
        usage
    fi
    
    log_info "Altering topic: $TOPIC_NAME"
    
    if [ -n "$PARTITIONS" ]; then
        log_warn "Increasing partitions to: $PARTITIONS"
        exec_kafka_cmd --alter --topic "$TOPIC_NAME" --partitions "$PARTITIONS"
    fi
    
    if [ -n "$TOPIC_CONFIG" ]; then
        log_info "Setting config: $TOPIC_CONFIG"
        kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-configs.sh \
            --bootstrap-server localhost:9092 \
            --alter --entity-type topics --entity-name "$TOPIC_NAME" \
            --add-config "$TOPIC_CONFIG"
    fi
    
    log_info "Topic altered successfully"
}

delete_topic() {
    if [ -z "$TOPIC_NAME" ]; then
        log_error "Topic name is required for delete"
        usage
    fi
    
    log_warn "Are you sure you want to delete topic: $TOPIC_NAME? (yes/no)"
    read -r confirmation
    if [ "$confirmation" != "yes" ]; then
        log_info "Deletion cancelled"
        exit 0
    fi
    
    log_info "Deleting topic: $TOPIC_NAME"
    exec_kafka_cmd --delete --topic "$TOPIC_NAME"
    log_info "Topic deleted successfully"
}

# Parse arguments
PARTITIONS=12
REPLICATION_FACTOR=3
ACTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            TOPIC_NAME="$2"
            shift 2
            ;;
        --partitions)
            PARTITIONS="$2"
            shift 2
            ;;
        --replication)
            REPLICATION_FACTOR="$2"
            shift 2
            ;;
        --config)
            TOPIC_CONFIG="$2"
            shift 2
            ;;
        --list)
            ACTION="list"
            shift
            ;;
        --describe)
            ACTION="describe"
            shift
            ;;
        --alter)
            ACTION="alter"
            shift
            ;;
        --delete)
            ACTION="delete"
            shift
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Execute action
case $ACTION in
    list)
        list_topics
        ;;
    describe)
        describe_topic
        ;;
    alter)
        alter_topic
        ;;
    delete)
        delete_topic
        ;;
    *)
        create_topic
        ;;
esac
