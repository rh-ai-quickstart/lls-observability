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
NAMESPACE="observability-hub"

# Check if we're in the right directory
if [ ! -d "$HELM_DIR/02-observability" ]; then
    print_error "Observability directory not found. Please run this script from the repository root."
    exit 1
fi

# Create namespace if it doesn't exist
print_status "Creating observability namespace..."
oc create namespace $NAMESPACE --dry-run=client -o yaml | oc apply -f-

# Function to check if a Helm release exists
release_exists() {
    local release_name=$1
    local namespace=$2
    helm list -q -n "$namespace" | grep -q "^${release_name}$"
}

print_status "Deploying observability infrastructure..."

# Deploy charts in specific order, skipping distributed-tracing-ui-plugin initially
charts_order=("tempo" "otel-collector" "grafana")

for chart_name in "${charts_order[@]}"; do
    chart_dir="$HELM_DIR/02-observability/$chart_name"
    if [ -d "$chart_dir" ] && [ -f "$chart_dir/Chart.yaml" ]; then
        if ! release_exists "$chart_name" "$NAMESPACE"; then
            print_status "Installing $chart_name..."
            helm install "$chart_name" "$chart_dir" -n "$NAMESPACE"
        else
            print_status "$chart_name already installed, skipping..."
        fi
    else
        print_status "Chart $chart_name not found, skipping..."
    fi
done

# Deploy User Workload Monitoring separately (requires template processing)
print_status "Checking User Workload Monitoring configuration..."
if oc get configmap user-workload-monitoring-config -n openshift-user-workload-monitoring >/dev/null 2>&1; then
    print_status "User Workload Monitoring already configured, skipping..."
else
    print_status "Deploying User Workload Monitoring configuration..."
    helm template uwm "$HELM_DIR/02-observability/uwm" -n "$NAMESPACE" | oc apply -f-
fi

# Wait for CRDs to be available before deploying UI plugin
print_status "Checking for UIPlugin CRD before deploying UI plugin..."
retries=0
while ! oc get crd uiplugins.observability.openshift.io >/dev/null 2>&1; do
    if [ $retries -ge 12 ]; then
        print_error "UIPlugin CRD not available after 60 seconds"
        break
    fi
    print_status "Waiting for UIPlugin CRD... (attempt $((retries + 1))/12)"
    sleep 5
    retries=$((retries + 1))
done

# Deploy distributed-tracing-ui-plugin last
if oc get crd uiplugins.observability.openshift.io >/dev/null 2>&1; then
    chart_dir="$HELM_DIR/02-observability/distributed-tracing-ui-plugin"
    if [ -d "$chart_dir" ] && [ -f "$chart_dir/Chart.yaml" ]; then
        if ! release_exists "distributed-tracing-ui-plugin" "$NAMESPACE"; then
            print_status "Installing distributed-tracing-ui-plugin..."
            helm install distributed-tracing-ui-plugin "$chart_dir" -n "$NAMESPACE"
        else
            print_status "distributed-tracing-ui-plugin already installed, skipping..."
        fi
    fi
else
    print_error "UIPlugin CRD not available, skipping distributed-tracing-ui-plugin"
fi

print_status "Verifying observability deployment..."

# Check deployments
oc get pods -n "$NAMESPACE"

# Verify UWM
print_status "Checking User Workload Monitoring setup..."
oc get configmap user-workload-monitoring-config -n openshift-user-workload-monitoring || true
oc get podmonitors -n "$NAMESPACE" || true

print_status "Observability infrastructure deployed successfully!"

echo ""
echo "Access points:"
echo "- Grafana: Check OpenShift console -> Networking -> Routes"
echo "- Tempo: Access via OpenShift console -> Observe -> Traces"
echo "- Metrics: Available via built-in Prometheus"