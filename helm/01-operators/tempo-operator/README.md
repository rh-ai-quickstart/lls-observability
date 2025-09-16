# Tempo Operator Helm Chart

This Helm chart deploys **only** the Tempo Operator on OpenShift. It does not create TempoStack instances - those should be created separately using the `../tempo/` kustomize configuration or other means.

## Prerequisites

- OpenShift cluster with Operator Lifecycle Manager (OLM)
- Helm 3.x
- Access to Red Hat Operators catalog

## Installation

### Basic Installation

```bash
helm install tempo-operator ./helm/tempo-operator
```

### Custom Installation

```bash
helm install tempo-operator ./helm/tempo-operator \
  --set operator.subscription.channel=stable \
  --set operator.namespace=my-tempo-operator
```

## Configuration

### Operator Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `operator.namespace` | Namespace for the operator | `openshift-tempo-operator` |
| `operator.subscription.name` | Subscription name | `tempo-product` |
| `operator.subscription.channel` | Subscription channel | `stable` |
| `operator.subscription.installPlanApproval` | Install plan approval | `Automatic` |
| `operator.subscription.source` | Operator source | `redhat-operators` |
| `operator.subscription.sourceNamespace` | Source namespace | `openshift-marketplace` |

### OperatorGroup Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `operator.operatorGroup.name` | OperatorGroup name | `openshift-tempo-operator` |
| `operator.operatorGroup.targetNamespaces` | Target namespaces for operator scope | `[]` (cluster-wide) |

**Important:** The OperatorGroup is configured for cluster-wide scope (AllNamespaces install mode) because the Tempo operator does not support OwnNamespace install mode. An empty `targetNamespaces` array enables the operator to watch all namespaces while being installed in the `openshift-tempo-operator` namespace. The OperatorGroup automatically includes `upgradeStrategy: Default` for proper operator lifecycle management.

### Namespace Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.create` | Create namespace | `true` |
| `namespace.name` | Namespace name | `openshift-tempo-operator` |
| `namespace.annotations` | Namespace annotations | `{"openshift.io/display-name": "Tempo Operator"}` |
| `namespace.labels` | Namespace labels | `{"openshift.io/cluster-monitoring": "true"}` |

### TempoStack Configuration

**Note:** This chart no longer creates TempoStack instances. Use the separate `../tempo/` kustomize configuration to deploy TempoStack instances after installing the operator.

## Usage

After installation, the chart will:

1. Create the `openshift-tempo-operator` namespace
2. Install the Tempo Operator via OLM subscription

### Creating TempoStack Instances

To create TempoStack instances after installing the operator, use the kustomize configuration in `../tempo/`:

```bash
# First install the operator
helm install tempo-operator ./helm/tempo-operator

# Then deploy TempoStack with MinIO storage
kubectl apply -k ./helm/tempo/
```

The `../tempo/` directory contains:
- MinIO deployment for S3-compatible storage
- TempoStack multitenant configuration
- Required secrets and PVCs
- RBAC configuration

### Storage Configuration

The `../tempo/` configuration includes a complete MinIO setup with the required storage secret. The secret is automatically configured for the TempoStack instance.

## Uninstalling

To uninstall the chart:

```bash
helm uninstall tempo-operator
```

**Note:** This will not remove the CRDs or the operator itself. To completely remove the operator, you may need to manually delete the subscription and operator group.

## Chart Development

This chart was converted from Kustomize configuration and follows the same structure and patterns as other Helm charts in this repository.

### Template Files

- `templates/namespace.yaml` - Creates the operator namespace
- `templates/operatorgroup.yaml` - Creates the operator group
- `templates/subscription.yaml` - Creates the OLM subscription
- `templates/tempostack.yaml` - Placeholder file (TempoStack instances are created separately)

### Helper Functions

The chart includes helper functions in `templates/_helpers.tpl` for consistent labeling and naming conventions.
