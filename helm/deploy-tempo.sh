#!/bin/bash

# Tempo Deployment Script
# This script deploys the Tempo operator and TempoStack using Helm charts

set -e

echo "🚀 Starting Tempo deployment..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed or not in PATH"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -d "tempo-operator" || ! -d "tempo" ]]; then
    print_error "Please run this script from the helm/ directory"
    exit 1
fi

print_status "Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_status "Step 1: Installing Tempo Operator..."
cd tempo-operator

# Check if the operator is already installed
if helm list -n openshift-tempo-operator | grep -q tempo-operator; then
    print_warning "Tempo operator already installed, skipping..."
else
    print_status "Installing Tempo operator via Helm..."
    helm install tempo-operator . --create-namespace
    
    print_status "Waiting for operator to be ready..."
    kubectl wait --for=condition=ready pod -l name=tempo-operator-controller -n openshift-tempo-operator --timeout=300s
fi

cd ..

print_status "Step 2: Installing TempoStack with MinIO storage..."
cd tempo

# Check if the TempoStack is already installed
if helm list -n observability-hub | grep -q tempo-stack; then
    print_warning "TempoStack already installed, upgrading..."
    helm upgrade tempo-stack . --create-namespace
else
    print_status "Installing TempoStack and MinIO via Helm..."
    helm install tempo-stack . --create-namespace
fi

print_status "Waiting for MinIO to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=minio-tempo -n observability-hub --timeout=300s

print_status "Waiting for TempoStack to be ready..."
kubectl wait --for=condition=ready tempostack tempostack -n observability-hub --timeout=600s

cd ..

print_status "✅ Deployment completed successfully!"

echo ""
echo "🔍 Deployment Summary:"
echo "====================="

# Check operator status
echo "Tempo Operator:"
kubectl get subscription tempo-product -n openshift-tempo-operator -o jsonpath='{.status.currentCSV}' 2>/dev/null || echo "  Status: Unknown"

# Check TempoStack status
echo ""
echo "TempoStack:"
kubectl get tempostack tempostack -n observability-hub -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | sed 's/^/  Ready: /' || echo "  Status: Unknown"

# Check MinIO status
echo ""
echo "MinIO:"
kubectl get pods -l app.kubernetes.io/name=minio-tempo -n observability-hub -o jsonpath='{.items[0].status.phase}' 2>/dev/null | sed 's/^/  Status: /' || echo "  Status: Unknown"

# Show routes (if any)
echo ""
echo "Access URLs:"
ROUTES=$(kubectl get routes -n observability-hub -o jsonpath='{.items[*].spec.host}' 2>/dev/null)
if [[ -n "$ROUTES" ]]; then
    for route in $ROUTES; do
        echo "  https://$route"
    done
else
    echo "  No routes found yet (operator may still be creating them)"
fi

echo ""
print_status "Helm releases:"
echo "  Tempo Operator: $(helm list -n openshift-tempo-operator -q)"
echo "  TempoStack: $(helm list -n observability-hub -q)"

echo ""
print_status "To check the status later, run:"
echo "  kubectl get tempostack,pods,routes -n observability-hub"
echo "  helm list -A"

echo ""
print_status "To access MinIO console (for debugging):"
echo "  kubectl port-forward svc/minio-tempo-svc 9001:9001 -n observability-hub"
echo "  Then open: http://localhost:9001"
echo "  Credentials: admin / minio123 (change in production!)"

echo ""
print_status "To upgrade deployments:"
echo "  helm upgrade tempo-operator ./tempo-operator"
echo "  helm upgrade tempo-stack ./tempo"

echo ""
print_status "To uninstall:"
echo "  helm uninstall tempo-stack -n observability-hub"
echo "  helm uninstall tempo-operator -n openshift-tempo-operator"

echo ""
print_warning "Remember to change default credentials for production use!"