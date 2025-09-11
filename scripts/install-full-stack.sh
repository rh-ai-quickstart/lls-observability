#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
HELM_DIR="./helm"
OBSERVABILITY_NAMESPACE="observability-hub"
AI_SERVICES_NAMESPACE="llama-serve"
DEFAULT_NAMESPACE="default"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to create namespaces
create_namespaces() {
    print_status "Creating required namespaces..."
    
    oc create namespace $OBSERVABILITY_NAMESPACE --dry-run=client -o yaml | oc apply -f-
    oc create namespace openshift-user-workload-monitoring --dry-run=client -o yaml | oc apply -f-
    oc create namespace $AI_SERVICES_NAMESPACE --dry-run=client -o yaml | oc apply -f-
    
    print_status "Namespaces created successfully"
}

# Function to check if a Helm release exists
release_exists() {
    local release_name=$1
    local namespace=${2:-$DEFAULT_NAMESPACE}
    
    if [ "$namespace" = "$DEFAULT_NAMESPACE" ]; then
        helm list -q | grep -q "^${release_name}$"
    else
        helm list -q -n "$namespace" | grep -q "^${release_name}$"
    fi
}

# Function to install charts in a directory
install_charts_in_directory() {
    local dir=$1
    local namespace=${2:-$DEFAULT_NAMESPACE}
    local parallel=${3:-false}
    
    if [ ! -d "$HELM_DIR/$dir" ]; then
        print_warning "Directory $HELM_DIR/$dir not found, skipping..."
        return
    fi
    
    print_status "Installing charts from $dir..."
    
    local pids=()
    
    for chart_dir in "$HELM_DIR/$dir"/*; do
        if [ -d "$chart_dir" ] && [ -f "$chart_dir/Chart.yaml" ]; then
            chart_name=$(basename "$chart_dir")
            
            # Check if release already exists
            if release_exists "$chart_name" "$namespace"; then
                print_warning "$chart_name already installed, skipping..."
                continue
            fi
            
            print_status "Installing $chart_name..."
            
            if [ "$parallel" = "true" ]; then
                # Install in background for parallel execution
                if [ "$namespace" = "$DEFAULT_NAMESPACE" ]; then
                    helm install "$chart_name" "$chart_dir" &
                else
                    helm install "$chart_name" "$chart_dir" -n "$namespace" &
                fi
                pids+=($!)
            else
                # Install sequentially
                if [ "$namespace" = "$DEFAULT_NAMESPACE" ]; then
                    helm install "$chart_name" "$chart_dir"
                else
                    helm install "$chart_name" "$chart_dir" -n "$namespace"
                fi
            fi
        fi
    done
    
    # Wait for parallel installations to complete
    if [ "$parallel" = "true" ] && [ ${#pids[@]} -gt 0 ]; then
        print_status "Waiting for parallel installations to complete..."
        for pid in "${pids[@]}"; do
            wait $pid
        done
    fi
    
    print_status "Charts from $dir processed successfully"
}

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

# Function to wait for operators to be ready
wait_for_operators() {
    print_status "Checking operator readiness..."
    
    # Check if operators are already ready
    if [ "$(check_operators_ready)" = "true" ]; then
        print_status "All operators are already ready!"
        return
    fi
    
    print_status "Some operators not ready, waiting for initialization..."
    
    # Give operators initial time to start
    print_status "Allowing operators time to initialize..."
    sleep 30
    
    # Wait for cluster observability operator
    print_status "Waiting for cluster observability operator..."
    oc wait --for=condition=Ready pod -l app.kubernetes.io/name=cluster-observability-operator \
        -n openshift-cluster-observability-operator --timeout=300s || print_warning "Cluster observability operator not ready"
    
    # Wait for observability operator  
    oc wait --for=condition=Ready pod -l app.kubernetes.io/name=observability-operator \
        -n openshift-cluster-observability-operator --timeout=300s || print_warning "Observability operator not ready"
    
    # Wait for grafana operator
    print_status "Waiting for grafana operator..."
    oc wait --for=condition=Ready pod -l control-plane=controller-manager \
        -n grafana-operator --timeout=300s || print_warning "Grafana operator not ready"
    
    # Wait for otel operator
    print_status "Waiting for otel operator..."
    oc wait --for=condition=Ready pod -l app.kubernetes.io/name=opentelemetry-operator \
        -n openshift-opentelemetry-operator --timeout=300s || print_warning "OTEL operator not ready"
    
    # Wait for tempo operator
    print_status "Waiting for tempo operator..."
    oc wait --for=condition=Ready pod -l app.kubernetes.io/name=tempo-operator \
        -n tempo-operator --timeout=300s || print_warning "Tempo operator not ready"
    
    # Wait for CRDs to be available
    print_status "Waiting for CRDs to be available..."
    sleep 15
    
    # Check for UIPlugin CRD specifically
    print_status "Checking for UIPlugin CRD..."
    local retries=0
    while ! oc get crd uiplugins.observability.openshift.io >/dev/null 2>&1; do
        if [ $retries -ge 12 ]; then
            print_warning "UIPlugin CRD not available after 60 seconds"
            break
        fi
        print_status "Waiting for UIPlugin CRD... (attempt $((retries + 1))/12)"
        sleep 5
        retries=$((retries + 1))
    done
    
    print_status "All operators are ready"
}

# Function to deploy User Workload Monitoring
deploy_uwm() {
    print_status "Checking User Workload Monitoring configuration..."
    
    # Check if UWM config already exists
    if oc get configmap user-workload-monitoring-config -n openshift-user-workload-monitoring >/dev/null 2>&1; then
        print_warning "User Workload Monitoring already configured, skipping..."
        return
    fi
    
    print_status "Deploying User Workload Monitoring configuration..."
    helm template uwm "$HELM_DIR/02-observability/uwm" -n $OBSERVABILITY_NAMESPACE | oc apply -f-
    
    print_status "Verifying UWM setup..."
    oc get configmap user-workload-monitoring-config -n openshift-user-workload-monitoring || true
    oc get podmonitors -n $OBSERVABILITY_NAMESPACE || true
}

# Function to install AI workloads with specific configurations
install_ai_workloads() {
    print_status "Installing AI workloads with specific configurations..."
    
    # Install llama3.2-3b with GPU configuration
    if ! release_exists "llama3-2-3b" "$AI_SERVICES_NAMESPACE"; then
        print_status "Installing llama3.2-3b with GPU support in $AI_SERVICES_NAMESPACE..."
        helm install llama3-2-3b "$HELM_DIR/03-ai-services/llama3.2-3b" -n "$AI_SERVICES_NAMESPACE" \
            --set model.name="meta-llama/Llama-3.2-3B-Instruct" \
            --set resources.limits."nvidia\.com/gpu"=1
    else
        print_warning "llama3-2-3b already installed, skipping..."
    fi
    
    # Install llama-stack with inference endpoint configuration
    if ! release_exists "llama-stack" "$AI_SERVICES_NAMESPACE"; then
        print_status "Installing llama-stack in $AI_SERVICES_NAMESPACE..."
        helm install llama-stack "$HELM_DIR/03-ai-services/llama-stack" -n "$AI_SERVICES_NAMESPACE" \
            --set 'inference.endpoints[0].url=http://llama3-2-3b.llama-serve.svc.cluster.local:80/v1' \
            --set 'mcpServers[0].name=weather' \
            --set 'mcpServers[0].uri=http://mcp-weather.llama-serve.svc.cluster.local:80' \
            --set 'mcpServers[0].description=Weather MCP Server for real-time weather data'
    else
        print_warning "llama-stack already installed, skipping..."
    fi
    
    # Install playground
    if ! release_exists "llama-stack-playground" "$AI_SERVICES_NAMESPACE"; then
        print_status "Installing llama-stack-playground in $AI_SERVICES_NAMESPACE..."
        helm install llama-stack-playground "$HELM_DIR/03-ai-services/llama-stack-playground" -n "$AI_SERVICES_NAMESPACE" \
            --set playground.llamaStackUrl="http://llama-stack.llama-serve.svc.cluster.local:80"
    else
        print_warning "llama-stack-playground already installed, skipping..."
    fi
    
    # Install llama-guard if available
    if [ -d "$HELM_DIR/03-ai-services/llama-guard" ]; then
        if ! release_exists "llama-guard" "$AI_SERVICES_NAMESPACE"; then
            print_status "Installing llama-guard in $AI_SERVICES_NAMESPACE..."
            helm install llama-guard "$HELM_DIR/03-ai-services/llama-guard" -n "$AI_SERVICES_NAMESPACE"
        else
            print_warning "llama-guard already installed, skipping..."
        fi
    fi
}

# Main installation function
main() {
    echo "========================================"
    echo "  Llama Stack Observability Installer"
    echo "========================================"
    echo ""
    
    # Check if we're in the right directory
    if [ ! -d "$HELM_DIR" ]; then
        print_error "Helm directory not found. Please run this script from the repository root."
        exit 1
    fi
    
    print_status "Starting full stack installation..."
    
    # Phase 1: Create namespaces
    print_status "Phase 1: Creating namespaces"
    create_namespaces
    echo ""
    
    # Phase 2: Install operators
    print_status "Phase 2: Installing operators"
    install_charts_in_directory "01-operators" "$DEFAULT_NAMESPACE" "true"
    echo ""
    
    # Phase 3: Wait for operators
    print_status "Phase 3: Waiting for operators to be ready"
    wait_for_operators
    echo ""
    
    # Phase 4: Deploy observability infrastructure
    print_status "Phase 4: Deploying observability infrastructure"
    
    # Deploy charts in specific order, skipping distributed-tracing-ui-plugin initially
    charts_order=("tempo" "otel-collector" "grafana")
    
    for chart_name in "${charts_order[@]}"; do
        chart_dir="$HELM_DIR/02-observability/$chart_name"
        if [ -d "$chart_dir" ] && [ -f "$chart_dir/Chart.yaml" ]; then
            # Check if release already exists
            if release_exists "$chart_name" "$OBSERVABILITY_NAMESPACE"; then
                print_warning "$chart_name already installed, skipping..."
                continue
            fi
            
            print_status "Installing $chart_name..."
            helm install "$chart_name" "$chart_dir" -n "$OBSERVABILITY_NAMESPACE"
        else
            print_status "Chart $chart_name not found, skipping..."
        fi
    done
    
    # Deploy UWM separately as it requires special handling
    deploy_uwm
    
    # Deploy distributed-tracing-ui-plugin last after ensuring CRDs are ready
    print_status "Deploying distributed-tracing-ui-plugin..."
    if [ -d "$HELM_DIR/02-observability/distributed-tracing-ui-plugin" ]; then
        if ! release_exists "distributed-tracing-ui-plugin" "$OBSERVABILITY_NAMESPACE"; then
            helm install distributed-tracing-ui-plugin "$HELM_DIR/02-observability/distributed-tracing-ui-plugin" -n "$OBSERVABILITY_NAMESPACE"
        else
            print_warning "distributed-tracing-ui-plugin already installed, skipping..."
        fi
    fi
    echo ""
    
    # Phase 5: Deploy MCP servers first (dependencies for AI services)
    print_status "Phase 5: Deploying MCP servers"
    install_charts_in_directory "04-mcp-servers" "$AI_SERVICES_NAMESPACE" "true"
    echo ""
    
    # Phase 6: Deploy AI services with configurations
    print_status "Phase 6: Deploying AI services"
    install_ai_workloads
    echo ""
    
    print_status "Installation completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Check operator status: oc get pods -n openshift-operators"
    echo "2. Verify observability: oc get pods -n $OBSERVABILITY_NAMESPACE"
    echo "3. Check AI workloads: oc get pods"
    echo "4. Access Grafana dashboards via OpenShift console"
    echo "5. View distributed traces in OpenShift console -> Observe -> Traces"
}

# Run main function
main "$@"