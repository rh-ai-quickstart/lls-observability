# Llama Stack Operator Helm Chart

This Helm chart deploys the Llama Stack Operator, which manages LlamaStackDistribution custom resources on Kubernetes.

## Overview

The Llama Stack Operator provides a Kubernetes-native way to deploy and manage Llama Stack instances. It creates and manages the necessary resources for running Llama Stack distributions in your cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- RBAC enabled cluster

## Installation

### Install from local chart

```bash
# Install in default namespace
helm install llama-stack-operator ./helm/01-operators/llama-stack-operator

# Install in specific namespace
helm install llama-stack-operator ./helm/01-operators/llama-stack-operator \
  --create-namespace \
  --namespace llama-stack-system
```

### Install with custom values

```bash
helm install llama-stack-operator ./helm/01-operators/llama-stack-operator \
  --set image.tag=v0.4.0 \
  --set replicaCount=2
```

## Configuration

The following table lists the configurable parameters and their default values:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Namespace name for the operator | `llama-stack-k8s-operator-system` |
| `namespace.create` | Create the namespace | `true` |
| `image.repository` | Operator image repository | `quay.io/eformat/llama-stack-k8s-operator` |
| `image.tag` | Operator image tag | `v0.3.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of operator replicas | `1` |
| `env.operatorVersion` | Operator version environment variable | `latest` |
| `env.llamaStackVersion` | Llama Stack version environment variable | `latest` |
| `serviceAccount.create` | Create service account | `true` |
| `rbac.create` | Create RBAC resources | `true` |
| `crd.create` | Create CRD resources | `true` |
| `leaderElection.enabled` | Enable leader election | `true` |
| `resources.requests.cpu` | CPU requests | `10m` |
| `resources.requests.memory` | Memory requests | `64Mi` |

## Usage

After installing the operator, you can create LlamaStackDistribution resources:

```yaml
apiVersion: llamastack.io/v1alpha1
kind: LlamaStackDistribution
metadata:
  name: my-llama-stack
  namespace: default
spec:
  replicas: 1
  server:
    containerSpec:
      image: meta-llama/llama-stack:latest
      env:
      - name: LLAMA_STACK_PORT
        value: "5000"
```

## Monitoring

The operator exposes metrics on port 8080. You can monitor the operator using:

```bash
# Check operator status
kubectl get pods -n llama-stack-k8s-operator-system -l control-plane=controller-manager

# View operator logs
kubectl logs -n llama-stack-k8s-operator-system -l control-plane=controller-manager -f

# Check CRD status
kubectl get crd llamastackdistributions.llamastack.io

# List all LlamaStackDistributions
kubectl get llamastackdistributions -A
```

## Upgrading

To upgrade the operator:

```bash
helm upgrade llama-stack-operator ./helm/01-operators/llama-stack-operator
```

## Uninstalling

To uninstall the operator:

```bash
helm uninstall llama-stack-operator
```

**Note:** This will not delete the CRDs or any existing LlamaStackDistribution resources. To completely clean up:

```bash
# Delete all LlamaStackDistribution resources
kubectl delete llamastackdistributions --all --all-namespaces

# Delete the CRD (optional, will affect other installations)
kubectl delete crd llamastackdistributions.llamastack.io
```

## Troubleshooting

### Operator pod not starting

Check the operator logs:
```bash
kubectl logs -n llama-stack-k8s-operator-system deployment/llama-stack-operator-controller-manager
```

### CRD not found

Ensure the CRD is installed:
```bash
kubectl get crd llamastackdistributions.llamastack.io
```

### RBAC issues

Verify RBAC resources are created:
```bash
kubectl get clusterrole,clusterrolebinding -l app.kubernetes.io/name=llama-stack-operator
```

## Contributing

1. Make changes to the templates or values
2. Test with `helm template` and `helm lint`
3. Test deployment in a development cluster
4. Submit a pull request

## License

This chart is licensed under the same terms as the Llama Stack project.