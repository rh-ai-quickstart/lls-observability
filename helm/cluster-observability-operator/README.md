# Cluster Observability Operator Helm Chart

This Helm chart installs the OpenShift Cluster Observability Operator on OpenShift clusters using the Operator Lifecycle Manager (OLM).

## Overview

The Cluster Observability Operator provides comprehensive cluster-wide observability capabilities, including:
- Cluster-wide telemetry collection and management
- Integration with OpenShift monitoring stack
- Custom resource management for observability configuration
- Enhanced cluster visibility and monitoring

## Prerequisites

- OpenShift 4.x cluster
- Cluster administrator privileges
- Helm 3.x installed

## Installation

### Basic Installation

```bash
# Install the operator
helm install cluster-observability-operator ./cluster-observability-operator
```

### Installation with Custom Values

```bash
# Install with custom namespace and configuration
helm install cluster-observability-operator ./cluster-observability-operator \
  --set namespace.name=my-cluster-obs-namespace \
  --set subscription.channel=stable
```
## Configuration

### Default Values

The chart comes with sensible defaults for OpenShift environments:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Namespace for the operator | `openshift-cluster-observability-operator` |
| `namespace.create` | Whether to create the namespace | `true` |
| `subscription.channel` | Operator subscription channel | `stable` |
| `subscription.packageName` | Operator package name | `cluster-observability-operator` |
| `subscription.source` | Catalog source | `redhat-operators` |
| `subscription.installPlanApproval` | Install plan approval mode | `Automatic` |
| `subscription.startingCSV` | Starting CSV version | `cluster-observability-operator.v1.2.0` |
| `operatorGroup.targetNamespaces` | Target namespaces for operator scope | `[]` (cluster-wide) |

### OperatorGroup Configuration

The Cluster Observability Operator is configured for cluster-wide deployment (AllNamespaces install mode) to enable comprehensive cluster monitoring and observability. The OperatorGroup uses an empty `targetNamespaces` array to achieve this scope while keeping the operator installed in its dedicated namespace.

This configuration allows the operator to:
- Monitor cluster-wide metrics and telemetry
- Manage observability resources across all namespaces
- Integrate with OpenShift's built-in monitoring stack
- Provide unified cluster observability

## Usage

### Verify Installation

After installation, verify the operator is running:

```bash
# Check operator deployment
oc get pods -n openshift-cluster-observability-operator

# Check subscription status
oc get subscription -n openshift-cluster-observability-operator

# Check cluster service version (CSV)
oc get csv -n openshift-cluster-observability-operator
```

## Upgrade

### Upgrade the Chart

```bash
# Upgrade to a new chart version
helm upgrade cluster-observability-operator llama-stack-observability/cluster-observability-operator

# Upgrade with new values
helm upgrade cluster-observability-operator llama-stack-observability/cluster-observability-operator \
  --set subscription.startingCSV=cluster-observability-operator.v1.3.0
```

### Operator Updates

The operator will automatically update based on the configured channel unless manual approval is required.

## Uninstall

### Remove the Chart

```bash
# Uninstall the Helm release
helm uninstall cluster-observability-operator
```

### Complete Cleanup

```bash
# Remove the namespace (if created by the chart)
oc delete namespace openshift-cluster-observability-operator

# Remove any remaining cluster-scoped resources
oc get crd | grep observability
oc delete crd <observability-crds>
```

## Troubleshooting

### Common Issues

1. **Operator not starting**: Check subscription and install plan status
   ```bash
   oc describe subscription cluster-observability-operator -n openshift-cluster-observability-operator
   oc get installplan -n openshift-cluster-observability-operator
   ```

2. **Missing CRDs**: Ensure the operator CSV has been successfully installed
   ```bash
   oc get csv -n openshift-cluster-observability-operator
   oc describe csv <csv-name> -n openshift-cluster-observability-operator
   ```

3. **Permission issues**: Verify cluster administrator privileges and RBAC configuration

### Logs

Check operator logs:
```bash
oc logs -l app.kubernetes.io/name=cluster-observability-operator -n openshift-cluster-observability-operator
```

## Chart Development

### Testing

```bash
# Lint the chart
helm lint ./cluster-observability-operator

# Render templates locally
helm template cluster-observability-operator ./cluster-observability-operator

# Test installation
helm install --dry-run --debug cluster-observability-operator ./cluster-observability-operator
```

### Directory Structure

```
cluster-observability-operator/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── README.md               # This file
└── templates/
    ├── _helpers.tpl        # Template helpers
    ├── namespace.yaml      # Namespace definition
    ├── operatorgroup.yaml  # OperatorGroup resource
    └── subscription.yaml   # Operator subscription
```