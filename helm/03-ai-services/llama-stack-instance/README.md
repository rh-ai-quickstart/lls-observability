# Llama Stack Instance Helm Chart

This Helm chart creates LlamaStackDistribution custom resources that are managed by the [Llama Stack Operator](../../../01-operators/llama-stack-operator/). This provides an operator-based approach to deploying Llama Stack instances.

## Overview

The Llama Stack Instance chart creates Custom Resources (CRs) that define desired Llama Stack distributions. The Llama Stack Operator watches for these CRs and creates the necessary Kubernetes resources (Deployments, Services, ConfigMaps, etc.) to run the actual Llama Stack instances.

## Architecture

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│ llama-stack-        │───▶│ LlamaStackDistribution│───▶│ llama-stack-operator│
│ instance chart      │    │ Custom Resource      │    │                     │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
                                                                   │
                                                                   ▼
                           ┌─────────────────────────────────────────────────────┐
                           │ Creates: Deployment, Service, ConfigMap, PVC, etc. │
                           └─────────────────────────────────────────────────────┘
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- **Llama Stack Operator must be installed** (`../../../01-operators/llama-stack-operator/`)
- RBAC enabled cluster

## Installation

### 1. Install the Llama Stack Operator (Required)

First, ensure the operator is installed:

```bash
# Install the operator
helm install llama-stack-operator ./helm/01-operators/llama-stack-operator \
  --namespace llama-stack-k8s-operator-system \
  --create-namespace

# Verify operator is running
kubectl get pods -n llama-stack-k8s-operator-system
```

### 2. Install a Llama Stack Instance

```bash
# Install with default configuration
helm install my-llama-stack ./helm/03-ai-services/llama-stack-instance

# Install in specific namespace
helm install my-llama-stack ./helm/03-ai-services/llama-stack-instance \
  --namespace llama-serve \
  --create-namespace
```

### 3. Install with Custom Configuration

```bash
helm install my-llama-stack ./helm/03-ai-services/llama-stack-instance \
  --set llamaStackDistribution.replicas=2 \
  --set llamaStackDistribution.server.distribution.name=custom-dist \
  --set llamaStackDistribution.server.containerSpec.port=9000
```

## Configuration

The following table lists the configurable parameters and their default values:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `llamaStackDistribution.create` | Create LlamaStackDistribution resource | `true` |
| `llamaStackDistribution.name` | Name of the distribution | `""` (uses chart fullname) |
| `llamaStackDistribution.replicas` | Number of replicas | `1` |
| `llamaStackDistribution.server.containerSpec.name` | Container name | `llama-stack` |
| `llamaStackDistribution.server.containerSpec.port` | Container port | `8321` |
| `llamaStackDistribution.server.containerSpec.env.otelServiceName` | OpenTelemetry service name | `llamastack` |
| `llamaStackDistribution.server.distribution.name` | Distribution type | `rh-dev` |
| `llamaStackDistribution.server.distribution.image` | Custom container image | `""` |
| `llamaStackDistribution.server.userConfig.configMapName` | ConfigMap name | `""` (auto-generated) |
| `llamaStackDistribution.server.podOverrides.serviceAccountName` | Custom service account | `""` |
| `operator.namespace` | Operator namespace | `llama-stack-k8s-operator-system` |
| `namespace.create` | Create namespace | `false` |
| `namespace.name` | Namespace name | `""` (uses release namespace) |

## Examples

### Basic Instance

```yaml
# values.yaml
llamaStackDistribution:
  replicas: 1
  server:
    containerSpec:
      name: llama-stack
      port: 8321
    distribution:
      name: rh-dev
```

### Custom Distribution with Image

```yaml
# values.yaml
llamaStackDistribution:
  replicas: 2
  server:
    containerSpec:
      name: custom-llama
      port: 9000
      env:
        otelServiceName: my-llama-stack
        customVariables:
          DEBUG: "true"
          LOG_LEVEL: "info"
      resources:
        requests:
          cpu: 1000m
          memory: 2Gi
        limits:
          cpu: 2000m
          memory: 4Gi
    distribution:
      image: "my-registry/llama-stack:v1.0.0"
    userConfig:
      configMapName: my-custom-config
```

### Advanced Pod Overrides

```yaml
# values.yaml
llamaStackDistribution:
  server:
    podOverrides:
      serviceAccountName: custom-sa
      volumeMounts:
        - name: custom-volume
          mountPath: /custom/path
      volumes:
        - name: custom-volume
          configMap:
            name: custom-config
```

## Monitoring

### Check LlamaStackDistribution Status

```bash
# List all distributions
kubectl get llamastackdistributions -A

# Check specific distribution
kubectl get llamastackdistribution my-llama-stack -o yaml

# Watch for changes
kubectl get llamastackdistribution my-llama-stack -w
```

### View Operator-Created Resources

```bash
# View all resources created by the operator
kubectl get all -l app.kubernetes.io/created-by=llama-stack-operator

# Check specific resource types
kubectl get pods,svc,configmap,pvc -l app.kubernetes.io/managed-by=llama-stack-operator
```

### Monitor Operator

```bash
# Check operator status
kubectl get pods -n llama-stack-k8s-operator-system

# View operator logs
kubectl logs -l control-plane=controller-manager -n llama-stack-k8s-operator-system -f
```

## Upgrading

To upgrade a Llama Stack instance:

```bash
helm upgrade my-llama-stack ./helm/03-ai-services/llama-stack-instance \
  --set llamaStackDistribution.replicas=3
```

The operator will handle the rolling update of the underlying resources.

## Uninstalling

To remove a Llama Stack instance:

```bash
# Remove the instance (this deletes the LlamaStackDistribution CR)
helm uninstall my-llama-stack

# The operator will automatically clean up the created resources
```

**Note:** The operator will automatically delete all resources it created when the LlamaStackDistribution CR is removed.

## Troubleshooting

### Instance Not Ready

1. **Check the LlamaStackDistribution status:**
   ```bash
   kubectl describe llamastackdistribution my-llama-stack
   ```

2. **Verify operator is running:**
   ```bash
   kubectl get pods -n llama-stack-k8s-operator-system
   ```

3. **Check operator logs:**
   ```bash
   kubectl logs -l control-plane=controller-manager -n llama-stack-k8s-operator-system --tail=50
   ```

### CRD Not Found

If you see "no matches for kind LlamaStackDistribution":

```bash
# Check if CRD exists
kubectl get crd llamastackdistributions.llamastack.io

# If not found, install the operator first
helm install llama-stack-operator ./helm/01-operators/llama-stack-operator
```

### Resource Conflicts

If you're migrating from the traditional `llama-stack` chart:

1. **Uninstall the old chart first:**
   ```bash
   helm uninstall old-llama-stack
   ```

2. **Clean up any remaining resources:**
   ```bash
   kubectl delete configmap,pvc,svc -l app.kubernetes.io/name=llama-stack
   ```

3. **Install the instance chart:**
   ```bash
   helm install new-llama-stack ./helm/03-ai-services/llama-stack-instance
   ```

### Operator Permissions

If the operator can't create resources, check RBAC:

```bash
# Check ClusterRole
kubectl get clusterrole -l app.kubernetes.io/name=llama-stack-operator

# Check ClusterRoleBinding
kubectl get clusterrolebinding -l app.kubernetes.io/name=llama-stack-operator
```

## Differences from Traditional Llama Stack Chart

| Aspect | Traditional Chart | Instance Chart (Operator-based) |
|--------|------------------|--------------------------------|
| **Resources Created** | Deployment, Service, ConfigMap, PVC directly | LlamaStackDistribution CR only |
| **Management** | Helm manages all resources | Operator manages resources |
| **Lifecycle** | Standard Kubernetes resources | Custom Resource lifecycle |
| **Updates** | Helm rolling updates | Operator-controlled updates |
| **Deletion** | Manual resource cleanup | Automatic cleanup via operator |
| **Scaling** | Manual replica changes | Operator handles scaling |

## Contributing

1. Make changes to templates or values
2. Test with `helm template` and `helm lint`
3. Test deployment with operator installed
4. Submit a pull request

## License

This chart is licensed under the same terms as the Llama Stack project.