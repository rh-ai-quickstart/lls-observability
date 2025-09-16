#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

HELM_DIR="./helm"

# Check if we're in the right directory
if [ ! -d "$HELM_DIR/01-operators" ]; then
    print_error "Operators directory not found. Please run this script from the repository root."
    exit 1
fi

print_status "Installing operators in parallel..."

# Function to check if a Helm release exists
release_exists() {
    local release_name=$1
    helm list -q | grep -q "^${release_name}$"
}

# Start parallel installations
pids=()

for chart_dir in "$HELM_DIR/01-operators"/*; do
    if [ -d "$chart_dir" ] && [ -f "$chart_dir/Chart.yaml" ]; then
        chart_name=$(basename "$chart_dir")
        
        # Check if release already exists
        if release_exists "$chart_name"; then
            print_status "$chart_name already installed, skipping..."
            continue
        fi
        
        print_status "Installing $chart_name..."
        helm install "$chart_name" "$chart_dir" &
        pids+=($!)
    fi
done

# Wait for all installations to complete
print_status "Waiting for all operator installations to complete..."
for pid in "${pids[@]}"; do
    wait $pid
done

# Function to check if operators are already ready
check_operators_ready() {
    local all_ready=true
    
    # Check cluster observability operator
    if ! oc get pods -l app.kubernetes.io/name=cluster-observability-operator -n openshift-cluster-observability-operator --no-headers 2>/dev/null | grep -q "Running"; then
        all_ready=false
    fi
    
    # Check grafana operator
    if ! oc get pods -l control-plane=controller-manager -n grafana-operator --no-headers 2>/dev/null | grep -q "Running"; then
        all_ready=false
    fi
    
    # Check otel operator
    if ! oc get pods -l app.kubernetes.io/name=opentelemetry-operator -n openshift-opentelemetry-operator --no-headers 2>/dev/null | grep -q "Running"; then
        all_ready=false
    fi
    
    # Check tempo operator
    if ! oc get pods -l app.kubernetes.io/name=tempo-operator -n tempo-operator --no-headers 2>/dev/null | grep -q "Running"; then
        all_ready=false
    fi
    
    # Check UIPlugin CRD
    if ! oc get crd uiplugins.observability.openshift.io >/dev/null 2>&1; then
        all_ready=false
    fi
    
    echo $all_ready
}

print_status "All operators installed successfully!"

print_status "Checking operator readiness..."

# Check if operators are already ready
if [ "$(check_operators_ready)" = "true" ]; then
    print_status "All operators are already ready!"
    exit 0
fi

print_status "Some operators not ready, waiting for initialization..."

# Give operators initial time to start
print_status "Allowing operators time to initialize..."
sleep 30

# Wait for operators to be available
oc wait --for=condition=Ready pod -l app.kubernetes.io/name=cluster-observability-operator \
    -n openshift-cluster-observability-operator --timeout=300s || print_status "Cluster observability operator timeout"

oc wait --for=condition=Ready pod -l app.kubernetes.io/name=observability-operator \
    -n openshift-cluster-observability-operator --timeout=300s || print_status "Observability operator timeout"

oc wait --for=condition=Ready pod -l control-plane=controller-manager \
    -n grafana-operator --timeout=300s || print_status "Grafana operator timeout"

oc wait --for=condition=Ready pod -l app.kubernetes.io/name=opentelemetry-operator \
    -n openshift-opentelemetry-operator --timeout=300s || print_status "OTEL operator timeout"

oc wait --for=condition=Ready pod -l app.kubernetes.io/name=tempo-operator \
    -n tempo-operator --timeout=300s || print_status "Tempo operator timeout"

# Wait for CRDs to be available
print_status "Waiting for CRDs to be available..."
sleep 30

# Check for UIPlugin CRD specifically
print_status "Checking for UIPlugin CRD..."
retries=0
while ! oc get crd uiplugins.observability.openshift.io >/dev/null 2>&1; do
    if [ $retries -ge 12 ]; then
        print_status "UIPlugin CRD not available after 60 seconds"
        break
    fi
    print_status "Waiting for UIPlugin CRD... (attempt $((retries + 1))/12)"
    sleep 5
    retries=$((retries + 1))
done

print_status "All operators are ready!"