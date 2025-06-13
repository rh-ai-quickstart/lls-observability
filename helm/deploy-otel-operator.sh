#!/bin/bash

# OpenTelemetry Operator Deployment Script
# This script deploys the OpenTelemetry Operator using Helm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="openshift-opentelemetry-operator"
RELEASE_NAME="otel-operator"
CHART_PATH="./otel-operator"
CHANNEL="stable"
INSTALL_PLAN_APPROVAL="Automatic"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy OpenTelemetry Operator using Helm

OPTIONS:
    -n, --namespace NAMESPACE           Target namespace (default: openshift-opentelemetry-operator)
    -r, --release RELEASE_NAME          Helm release name (default: otel-operator)
    -c, --channel CHANNEL              Operator channel (default: stable)
    -a, --approval MODE                Install plan approval (Automatic|Manual, default: Automatic)
    --dry-run                          Show what would be deployed without actually deploying
    --upgrade                          Upgrade existing installation
    --uninstall                        Uninstall the operator
    -h, --help                         Show this help message

EXAMPLES:
    # Basic installation
    $0

    # Install with fast channel
    $0 --channel fast

    # Install with manual approval
    $0 --approval Manual

    # Dry run to see what would be deployed
    $0 --dry-run

    # Upgrade existing installation
    $0 --upgrade

    # Uninstall
    $0 --uninstall
EOF
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm first."
        exit 1
    fi
    
    # Check if oc is installed
    if ! command -v oc &> /dev/null; then
        print_error "OpenShift CLI (oc) is not installed. Please install oc first."
        exit 1
    fi
    
    # Check if logged into OpenShift
    if ! oc whoami &> /dev/null; then
        print_error "Not logged into OpenShift. Please login first with 'oc login'."
        exit 1
    fi
    
    # Check if chart directory exists
    if [ ! -d "$CHART_PATH" ]; then
        print_error "Chart directory '$CHART_PATH' not found. Please run this script from the helm directory."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Function to deploy the operator
deploy_operator() {
    local dry_run_flag=""
    if [ "$DRY_RUN" = "true" ]; then
        dry_run_flag="--dry-run"
        print_status "Performing dry run of OpenTelemetry Operator deployment..."
    else
        print_status "Deploying OpenTelemetry Operator..."
    fi
    
    # Build helm command
    local helm_cmd="helm install $RELEASE_NAME $CHART_PATH"
    
    if [ "$UPGRADE" = "true" ]; then
        helm_cmd="helm upgrade $RELEASE_NAME $CHART_PATH"
        print_status "Upgrading existing OpenTelemetry Operator installation..."
    fi
    
    helm_cmd="$helm_cmd --set namespace.name=$NAMESPACE"
    helm_cmd="$helm_cmd --set subscription.channel=$CHANNEL"
    helm_cmd="$helm_cmd --set subscription.installPlanApproval=$INSTALL_PLAN_APPROVAL"
    
    if [ "$DRY_RUN" = "true" ]; then
        helm_cmd="$helm_cmd --dry-run --debug"
    fi
    
    # Execute helm command
    if eval $helm_cmd; then
        if [ "$DRY_RUN" != "true" ]; then
            print_success "OpenTelemetry Operator deployed successfully!"
            
            print_status "Deployment details:"
            echo "  - Release name: $RELEASE_NAME"
            echo "  - Namespace: $NAMESPACE"
            echo "  - Channel: $CHANNEL"
            echo "  - Install plan approval: $INSTALL_PLAN_APPROVAL"
            
            print_status "To check the deployment status:"
            echo "  oc get pods -n $NAMESPACE"
            echo "  oc get subscription -n $NAMESPACE"
            echo "  oc get csv -n $NAMESPACE"
        fi
    else
        print_error "Failed to deploy OpenTelemetry Operator"
        exit 1
    fi
}

# Function to uninstall the operator
uninstall_operator() {
    print_status "Uninstalling OpenTelemetry Operator..."
    
    if helm list | grep -q "^$RELEASE_NAME"; then
        if helm uninstall $RELEASE_NAME; then
            print_success "OpenTelemetry Operator uninstalled successfully!"
            
            print_warning "Note: The namespace '$NAMESPACE' and any OpenTelemetry resources may still exist."
            print_status "To completely clean up:"
            echo "  oc delete namespace $NAMESPACE"
            echo "  oc get crd | grep opentelemetry"
        else
            print_error "Failed to uninstall OpenTelemetry Operator"
            exit 1
        fi
    else
        print_warning "Release '$RELEASE_NAME' not found. Nothing to uninstall."
    fi
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Wait for operator to be ready
    print_status "Waiting for operator to be ready..."
    sleep 10
    
    # Check subscription
    if oc get subscription $RELEASE_NAME -n $NAMESPACE &> /dev/null; then
        print_success "Subscription created successfully"
        
        # Check CSV
        local csv=$(oc get subscription $RELEASE_NAME -n $NAMESPACE -o jsonpath='{.status.currentCSV}')
        if [ -n "$csv" ]; then
            print_success "ClusterServiceVersion: $csv"
            
            # Check if CSV is ready
            local phase=$(oc get csv $csv -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
            echo "  CSV Phase: $phase"
            
            if [ "$phase" = "Succeeded" ]; then
                print_success "OpenTelemetry Operator is ready!"
            else
                print_warning "Operator may still be installing. Check status with:"
                echo "  oc get csv -n $NAMESPACE"
            fi
        fi
    else
        print_error "Subscription not found"
    fi
}

# Parse command line arguments
DRY_RUN=false
UPGRADE=false
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -c|--channel)
            CHANNEL="$2"
            shift 2
            ;;
        -a|--approval)
            INSTALL_PLAN_APPROVAL="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --upgrade)
            UPGRADE=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
print_status "OpenTelemetry Operator Deployment Script"
print_status "========================================"

if [ "$UNINSTALL" = "true" ]; then
    check_prerequisites
    uninstall_operator
else
    check_prerequisites
    deploy_operator
    
    if [ "$DRY_RUN" != "true" ]; then
        verify_deployment
        
        print_success "Deployment completed!"
        print_status "Next steps:"
        echo "1. Create OpenTelemetry Collector instances"
        echo "2. Configure auto-instrumentation"
        echo "3. Set up exporters to your observability backend"
        echo ""
        echo "For examples, see the chart README.md"
    fi
fi