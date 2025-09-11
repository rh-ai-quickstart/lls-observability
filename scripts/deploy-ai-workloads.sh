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

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

HELM_DIR="./helm"
AI_SERVICES_NAMESPACE="llama-serve"

# Check if we're in the right directory
if [ ! -d "$HELM_DIR/03-ai-services" ] || [ ! -d "$HELM_DIR/04-mcp-servers" ]; then
    print_error "AI services or MCP servers directory not found. Please run this script from the repository root."
    exit 1
fi

# Create AI services namespace
print_status "Creating AI services namespace..."
oc create namespace $AI_SERVICES_NAMESPACE --dry-run=client -o yaml | oc apply -f-

print_status "Deploying AI workloads..."

# Function to check if a Helm release exists
release_exists() {
    local release_name=$1
    local namespace=${2:-default}
    helm list -q -n "$namespace" | grep -q "^${release_name}$"
}

# First deploy MCP servers (dependencies for AI services)
print_status "Step 1: Deploying MCP servers..."

for chart_dir in "$HELM_DIR/04-mcp-servers"/*; do
    if [ -d "$chart_dir" ] && [ -f "$chart_dir/Chart.yaml" ]; then
        chart_name=$(basename "$chart_dir")
        
        if ! release_exists "$chart_name" "$AI_SERVICES_NAMESPACE"; then
            print_status "Installing MCP server: $chart_name in $AI_SERVICES_NAMESPACE..."
            helm install "$chart_name" "$chart_dir" -n "$AI_SERVICES_NAMESPACE"
        else
            print_warning "$chart_name already installed, skipping..."
        fi
    fi
done

print_status "MCP servers deployed. Waiting for readiness..."
sleep 30

# Deploy Milvus vector database
print_status "Step 2: Deploying Milvus vector database..."

if [ -d "$HELM_DIR/03-ai-services/milvus" ]; then
    if ! release_exists "milvus" "$AI_SERVICES_NAMESPACE"; then
        print_status "Adding Milvus Helm repository..."
        helm repo add milvus https://zilliztech.github.io/milvus-helm/ --force-update
        helm repo update
        
        print_status "Building Milvus chart dependencies..."
        helm dependency build "$HELM_DIR/03-ai-services/milvus"
        
        print_status "Installing Milvus vector database in $AI_SERVICES_NAMESPACE..."
        helm install milvus "$HELM_DIR/03-ai-services/milvus" -n "$AI_SERVICES_NAMESPACE"
    else
        print_warning "Milvus already installed, skipping..."
    fi
else
    print_warning "Milvus chart not found, skipping..."
fi

print_status "Milvus deployed. Waiting for readiness..."
sleep 30

# Deploy AI services with specific configurations
print_status "Step 3: Deploying AI services..."

# Deploy llama3.2-3b with GPU configuration
if [ -d "$HELM_DIR/03-ai-services/llama3.2-3b" ]; then
    if ! release_exists "llama3-2-3b" "$AI_SERVICES_NAMESPACE"; then
        print_status "Installing llama3.2-3b with GPU support in $AI_SERVICES_NAMESPACE..."
        helm install llama3-2-3b "$HELM_DIR/03-ai-services/llama3.2-3b" -n "$AI_SERVICES_NAMESPACE" \
            --set model.name="meta-llama/Llama-3.2-3B-Instruct" \
            --set resources.limits."nvidia\.com/gpu"=1
    else
        print_warning "llama3-2-3b already installed, skipping..."
    fi
else
    print_warning "llama3.2-3b chart not found, skipping..."
fi

# Wait for model to be ready before deploying llama-stack
print_status "Waiting for model deployment to initialize..."
sleep 60

# Deploy llama-stack-instance with inference endpoint configuration
if [ -d "$HELM_DIR/03-ai-services/llama-stack-instance" ]; then
    if ! release_exists "llama-stack-instance" "$AI_SERVICES_NAMESPACE"; then
        print_status "Installing llama-stack-instance in $AI_SERVICES_NAMESPACE..."
        helm install llama-stack-instance "$HELM_DIR/03-ai-services/llama-stack-instance" -n "$AI_SERVICES_NAMESPACE" \
            --set 'mcpServers[0].name=weather' \
            --set 'mcpServers[0].uri=http://mcp-weather.llama-serve.svc.cluster.local:80' \
            --set 'mcpServers[0].description=Weather MCP Server for real-time weather data'
    else
        print_warning "llama-stack-instance already installed, skipping..."
    fi
else
    print_warning "llama-stack-instance chart not found, skipping..."
fi

# Deploy playground
if [ -d "$HELM_DIR/03-ai-services/llama-stack-playground" ]; then
    if ! release_exists "llama-stack-playground" "$AI_SERVICES_NAMESPACE"; then
        print_status "Installing llama-stack-playground in $AI_SERVICES_NAMESPACE..."
        helm install llama-stack-playground "$HELM_DIR/03-ai-services/llama-stack-playground" -n "$AI_SERVICES_NAMESPACE" \
            --set playground.llamaStackUrl="http://llama-stack-instance.llama-serve.svc.cluster.local:80"
    else
        print_warning "llama-stack-playground already installed, skipping..."
    fi
else
    print_warning "llama-stack-playground chart not found, skipping..."
fi

# Deploy llama-guard if available
if [ -d "$HELM_DIR/03-ai-services/llama-guard" ]; then
    if ! release_exists "llama-guard" "$AI_SERVICES_NAMESPACE"; then
        print_status "Installing llama-guard in $AI_SERVICES_NAMESPACE..."
        helm install llama-guard "$HELM_DIR/03-ai-services/llama-guard" -n "$AI_SERVICES_NAMESPACE"
    else
        print_warning "llama-guard already installed, skipping..."
    fi
else
    print_warning "llama-guard chart not found, skipping..."
fi

print_status "AI workloads deployment completed!"

echo ""
echo "Deployment summary:"
echo "- MCP Servers: weather, hr-api (in $AI_SERVICES_NAMESPACE namespace)"
echo "- AI Services: milvus, llama3.2-3b, llama-stack-instance, playground, llama-guard (in $AI_SERVICES_NAMESPACE namespace)"
echo ""
echo "Next steps:"
echo "1. Check deployment status: oc get pods -n $AI_SERVICES_NAMESPACE"
echo "2. Monitor GPU usage: oc describe nodes | grep nvidia.com/gpu"
echo "3. Test inference: Access playground via route"
echo "4. View traces: OpenShift console -> Observe -> Traces"
echo "5. Check MCP servers: oc get pods -n $AI_SERVICES_NAMESPACE | grep mcp"