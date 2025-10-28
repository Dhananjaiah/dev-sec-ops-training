#!/bin/bash
# ACL management script for Kafka

set -e

NAMESPACE="${KAFKA_NAMESPACE:-kafka}"
ENV="${ENV:-dev}"
KAFKA_POD="${ENV}-kafka-0"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --user USER              User principal"
    echo "  --topic TOPIC            Topic name"
    echo "  --group GROUP            Consumer group name"
    echo "  --operation OP           Operation (READ, WRITE, CREATE, DELETE, ALTER, DESCRIBE, ALL)"
    echo "  --list                   List all ACLs"
    echo "  --remove                 Remove ACL"
    echo "  --help                   Show this help"
    echo ""
    echo "Examples:"
    echo "  # Grant producer access"
    echo "  $0 --user app-producer --topic orders --operation WRITE"
    echo ""
    echo "  # Grant consumer access"
    echo "  $0 --user app-consumer --topic orders --group order-processors --operation READ"
    echo ""
    echo "  # List all ACLs"
    echo "  $0 --list"
    exit 1
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

exec_kafka_acl() {
    kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -c kafka -- bin/kafka-acls.sh \
        --bootstrap-server localhost:9092 "$@"
}

list_acls() {
    log_info "Listing all ACLs..."
    exec_kafka_acl --list
}

add_acl() {
    if [ -z "$USER" ]; then
        log_error "User is required"
        usage
    fi
    
    CMD_ARGS="--add --allow-principal User:$USER"
    
    if [ -n "$TOPIC" ]; then
        CMD_ARGS="$CMD_ARGS --topic $TOPIC"
    fi
    
    if [ -n "$GROUP" ]; then
        CMD_ARGS="$CMD_ARGS --group $GROUP"
    fi
    
    if [ -n "$OPERATION" ]; then
        CMD_ARGS="$CMD_ARGS --operation $OPERATION"
    else
        log_error "Operation is required"
        usage
    fi
    
    log_info "Adding ACL for user: $USER"
    exec_kafka_acl $CMD_ARGS
    log_info "ACL added successfully"
}

remove_acl() {
    if [ -z "$USER" ]; then
        log_error "User is required"
        usage
    fi
    
    CMD_ARGS="--remove --allow-principal User:$USER"
    
    if [ -n "$TOPIC" ]; then
        CMD_ARGS="$CMD_ARGS --topic $TOPIC"
    fi
    
    if [ -n "$GROUP" ]; then
        CMD_ARGS="$CMD_ARGS --group $GROUP"
    fi
    
    if [ -n "$OPERATION" ]; then
        CMD_ARGS="$CMD_ARGS --operation $OPERATION"
    fi
    
    log_info "Removing ACL for user: $USER"
    exec_kafka_acl $CMD_ARGS --force
    log_info "ACL removed successfully"
}

ACTION="add"

while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            USER="$2"
            shift 2
            ;;
        --topic)
            TOPIC="$2"
            shift 2
            ;;
        --group)
            GROUP="$2"
            shift 2
            ;;
        --operation)
            OPERATION="$2"
            shift 2
            ;;
        --list)
            ACTION="list"
            shift
            ;;
        --remove)
            ACTION="remove"
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

case $ACTION in
    list)
        list_acls
        ;;
    remove)
        remove_acl
        ;;
    *)
        add_acl
        ;;
esac
