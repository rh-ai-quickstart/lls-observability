# Grafana Operator Helm Chart

This Helm chart installs the Grafana Operator on OpenShift clusters using the Operator Lifecycle Manager (OLM).

## Overview

The Grafana Operator provides Kubernetes-native management of Grafana components, including:
- Grafana instances with custom configurations
- Dashboard and datasource management
- User and authentication management
- Multi-tenancy support

## Prerequisites

- OpenShift 4.x cluster
- Cluster administrator privileges
- Helm 3.x installed

## Installation

```bash
# From the chart directory
helm install grafana-operator ./grafana-operator
```

## Configuration

### Default Values

The chart comes with sensible defaults for OpenShift environments:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Namespace for the operator | `openshift-grafana-operator` |
| `namespace.create` | Whether to create the namespace | `true` |
| `subscription.channel` | Operator subscription channel | `v5` |
| `subscription.packageName` | Operator package name | `grafana-operator` |
| `subscription.source` | Catalog source | `community-operators` |
| `subscription.installPlanApproval` | Install plan approval mode | `Automatic` |
| `operatorGroup.targetNamespaces` | Target namespaces for operator scope | `[]` (cluster-wide) |

## Usage

### Verify Installation

After installation, verify the operator is running:

```bash
# Check operator deployment
oc get pods -n openshift-grafana-operator

# Check subscription status
oc get subscription -n openshift-grafana-operator

# Check cluster service version (CSV)
oc get csv -n openshift-grafana-operator
```

## Upgrade

### Upgrade the Chart

```bash
# Upgrade to a new chart version
helm upgrade grafana-operator llama-stack-observability/grafana-operator

# Upgrade with new values
helm upgrade grafana-operator llama-stack-observability/grafana-operator \
  --set subscription.channel=v4
```

### Operator Updates

The operator will automatically update based on the configured channel unless manual approval is required.

## Uninstall

### Remove the Chart

```bash
# Uninstall the Helm release
helm uninstall grafana-operator
```

### Complete Cleanup

```bash
# Remove the namespace (if created by the chart)
oc delete namespace openshift-grafana-operator

# Remove any remaining cluster-scoped resources
oc get crd | grep grafana
oc delete crd <grafana-crds>
```

### Directory Structure

```
grafana-operator/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── README.md           # This file
└── templates/
    ├── _helpers.tpl    # Template helpers
    ├── namespace.yaml  # Namespace definition
    ├── operatorgroup.yaml  # OperatorGroup resource
    └── subscription.yaml   # Operator subscription
```