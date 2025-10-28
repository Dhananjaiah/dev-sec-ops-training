#!/bin/bash
# Chaos engineering drill - simulate broker failures

set -e

NAMESPACE="${KAFKA_NAMESPACE:-kafka}"
ENV="${1:-dev}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --kill-broker POD    Kill a specific broker pod"
    echo "  --kill-random        Kill a random broker"
    echo "  --network-delay      Introduce network latency"
    echo "  --disk-pressure      Simulate disk pressure"
    echo "  --cpu-stress         Stress CPU on a broker"
    echo "  --env ENV            Environment (dev/stage/prod, default: dev)"
    echo ""
    echo "Examples:"
    echo "  $0 --kill-broker dev-kafka-0"
    echo "  $0 --kill-random --env dev"
    exit 1
}

kill_broker() {
    local pod=$1
    
    log_warn "Killing broker pod: $pod"
    log_info "This simulates a sudden broker failure"
    
    kubectl delete pod -n "$NAMESPACE" "$pod"
    
    log_info "Monitoring recovery..."
    echo ""
    
    # Wait for pod to restart
    kubectl wait --for=condition=ready pod "$pod" -n "$NAMESPACE" --timeout=300s || {
        log_error "Pod did not recover in time"
        return 1
    }
    
    log_info "Pod recovered successfully"
    
    # Check cluster health
    log_info "Checking for under-replicated partitions..."
    URP=$(kubectl exec -n "$NAMESPACE" "$pod" -c kafka -- \
        bin/kafka-topics.sh --bootstrap-server localhost:9092 \
        --describe --under-replicated-partitions 2>/dev/null | grep -v "^$" | wc -l)
    
    if [ "$URP" -gt 0 ]; then
        log_warn "Found $URP under-replicated partitions (may be temporary)"
    else
        log_info "No under-replicated partitions"
    fi
}

kill_random_broker() {
    log_info "Selecting random broker to kill..."
    
    # Get list of broker pods
    BROKERS=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=kafka -o name | sed 's|pod/||')
    BROKER_ARRAY=($BROKERS)
    
    if [ ${#BROKER_ARRAY[@]} -eq 0 ]; then
        log_error "No broker pods found"
        return 1
    fi
    
    # Select random broker
    RANDOM_INDEX=$((RANDOM % ${#BROKER_ARRAY[@]}))
    RANDOM_BROKER=${BROKER_ARRAY[$RANDOM_INDEX]}
    
    log_info "Selected: $RANDOM_BROKER"
    kill_broker "$RANDOM_BROKER"
}

introduce_network_delay() {
    local pod=$1
    local delay=${2:-100}  # 100ms default
    
    log_warn "Introducing ${delay}ms network delay to $pod"
    log_info "This simulates network latency issues"
    
    # Use tc (traffic control) to add latency
    kubectl exec -n "$NAMESPACE" "$pod" -c kafka -- \
        tc qdisc add dev eth0 root netem delay "${delay}ms" 2>/dev/null || {
        log_error "Failed to add network delay (tc may not be available)"
        return 1
    }
    
    log_info "Network delay applied for 60 seconds..."
    sleep 60
    
    # Remove delay
    log_info "Removing network delay..."
    kubectl exec -n "$NAMESPACE" "$pod" -c kafka -- \
        tc qdisc del dev eth0 root 2>/dev/null || true
    
    log_info "Network delay removed"
}

stress_cpu() {
    local pod=$1
    local duration=${2:-60}  # 60 seconds default
    
    log_warn "Stressing CPU on $pod for ${duration} seconds"
    log_info "This simulates high CPU load"
    
    # Run stress in background
    kubectl exec -n "$NAMESPACE" "$pod" -c kafka -- \
        sh -c "yes > /dev/null &" &
    
    STRESS_PID=$!
    
    sleep "$duration"
    
    # Kill stress process
    kill $STRESS_PID 2>/dev/null || true
    
    log_info "CPU stress completed"
}

run_full_chaos_drill() {
    log_info "Running full chaos engineering drill..."
    echo ""
    
    log_info "Step 1: Baseline health check"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=kafka
    echo ""
    
    log_info "Step 2: Kill random broker"
    kill_random_broker
    echo ""
    
    sleep 30
    
    log_info "Step 3: Verify cluster recovered"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=kafka
    echo ""
    
    log_info "Step 4: Check metrics"
    kubectl get kafka -n "$NAMESPACE"
    echo ""
    
    log_info "Chaos drill completed!"
}

# Parse arguments
ACTION=""
POD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --kill-broker)
            ACTION="kill"
            POD="$2"
            shift 2
            ;;
        --kill-random)
            ACTION="kill-random"
            shift
            ;;
        --network-delay)
            ACTION="network"
            shift
            ;;
        --cpu-stress)
            ACTION="cpu"
            shift
            ;;
        --full-drill)
            ACTION="full"
            shift
            ;;
        --env)
            ENV="$2"
            shift 2
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
echo "======================================"
echo "Chaos Engineering Drill - $ENV"
echo "======================================"
echo ""

log_warn "⚠️  This will intentionally cause failures!"
read -p "Continue? [yes/NO]: " confirm

if [ "$confirm" != "yes" ]; then
    log_info "Cancelled"
    exit 0
fi

echo ""

case $ACTION in
    kill)
        if [ -z "$POD" ]; then
            log_error "Pod name required for --kill-broker"
            usage
        fi
        kill_broker "$POD"
        ;;
    kill-random)
        kill_random_broker
        ;;
    network)
        if [ -z "$POD" ]; then
            POD="${ENV}-kafka-0"
        fi
        introduce_network_delay "$POD"
        ;;
    cpu)
        if [ -z "$POD" ]; then
            POD="${ENV}-kafka-0"
        fi
        stress_cpu "$POD"
        ;;
    full)
        run_full_chaos_drill
        ;;
    *)
        log_error "No action specified"
        usage
        ;;
esac

echo ""
echo "======================================"
log_info "Drill completed!"
echo "======================================"
