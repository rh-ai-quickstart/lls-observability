# OpenTelemetry Operator Helm Chart

This Helm chart installs the OpenTelemetry Operator on OpenShift clusters using the Operator Lifecycle Manager (OLM).

## Overview

The OpenTelemetry Operator provides Kubernetes-native management of OpenTelemetry components, including:
- OpenTelemetry Collector instances
- Auto-instrumentation for applications
- Simplified configuration and deployment

## Prerequisites

- OpenShift 4.x cluster
- Cluster administrator privileges
- Helm 3.x installed

## Installation

### Basic Installation

```bash
# Add the repository (if using a Helm repository)
helm repo add llama-stack-observability /path/to/helm/charts

# Install the operator
helm install otel-operator llama-stack-observability/otel-operator
```

### Installation with Custom Values

```bash
# Install with custom namespace and configuration
helm install otel-operator llama-stack-observability/otel-operator \
  --set namespace.name=my-otel-namespace \
  --set subscription.channel=fast
```

### Installation from Local Chart

```bash
# From the chart directory
helm install otel-operator ./otel-operator
```

## Configuration

### Default Values

The chart comes with sensible defaults for OpenShift environments:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Namespace for the operator | `openshift-opentelemetry-operator` |
| `namespace.create` | Whether to create the namespace | `true` |
| `subscription.channel` | Operator subscription channel | `stable` |
| `subscription.packageName` | Operator package name | `opentelemetry-product` |
| `subscription.source` | Catalog source | `redhat-operators` |
| `subscription.installPlanApproval` | Install plan approval mode | `Automatic` |
| `operatorGroup.targetNamespaces` | Target namespaces for operator scope | `[]` (cluster-wide) |

### OperatorGroup Configuration

The OpenTelemetry Operator is configured for cluster-wide deployment (AllNamespaces install mode) to enable monitoring and instrumentation across all namespaces. The OperatorGroup uses an empty `targetNamespaces` array to achieve this scope while keeping the operator installed in its dedicated namespace.

This configuration allows the operator to:
- Deploy OpenTelemetry Collectors in any namespace
- Apply auto-instrumentation across the cluster
- Monitor workloads cluster-wide

### Customization Examples

#### Different Update Channel

```yaml
# values.yaml
subscription:
  channel: fast  # Use fast update channel instead of stable
```

#### Custom Namespace

```yaml
# values.yaml
namespace:
  name: custom-otel-namespace
  annotations:
    custom.annotation/example: "value"
  labels:
    custom.label/example: "value"
```

#### Manual Install Plan Approval

```yaml
# values.yaml
subscription:
  installPlanApproval: Manual  # Require manual approval for updates
```

## Usage

### Verify Installation

After installation, verify the operator is running:

```bash
# Check operator deployment
oc get pods -n openshift-opentelemetry-operator

# Check subscription status
oc get subscription -n openshift-opentelemetry-operator

# Check cluster service version (CSV)
oc get csv -n openshift-opentelemetry-operator
```

### Creating OpenTelemetry Collectors

Once the operator is installed, you can create OpenTelemetry Collector instances:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: my-app-namespace
spec:
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    
    processors:
      batch:
    
    exporters:
      logging:
        loglevel: debug
    
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [logging]
```

### Auto-Instrumentation

Enable automatic instrumentation for applications:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: my-instrumentation
  namespace: my-app-namespace
spec:
  exporter:
    endpoint: http://otel-collector:4318
  propagators:
    - tracecontext
    - baggage
  sampler:
    type: parentbased_traceidratio
    argument: "0.1"
  python:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-python:latest
  nodejs:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-nodejs:latest
  java:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:latest
```

Then annotate your deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        instrumentation.opentelemetry.io/inject-python: "true"
    spec:
      containers:
      - name: my-app
        image: my-app:latest
```

## Upgrade

### Upgrade the Chart

```bash
# Upgrade to a new chart version
helm upgrade otel-operator llama-stack-observability/otel-operator

# Upgrade with new values
helm upgrade otel-operator llama-stack-observability/otel-operator \
  --set subscription.channel=fast
```

### Operator Updates

The operator will automatically update based on the configured channel unless manual approval is required.

## Uninstall

### Remove the Chart

```bash
# Uninstall the Helm release
helm uninstall otel-operator
```

### Complete Cleanup

```bash
# Remove the namespace (if created by the chart)
oc delete namespace openshift-opentelemetry-operator

# Remove any remaining cluster-scoped resources
oc get crd | grep opentelemetry
oc delete crd <opentelemetry-crds>
```

## Troubleshooting

### Common Issues

1. **Operator not starting**: Check subscription and install plan status
   ```bash
   oc describe subscription opentelemetry-product -n openshift-opentelemetry-operator
   oc get installplan -n openshift-opentelemetry-operator
   ```

2. **Missing CRDs**: Ensure the operator CSV has been successfully installed
   ```bash
   oc get csv -n openshift-opentelemetry-operator
   oc describe csv <csv-name> -n openshift-opentelemetry-operator
   ```

3. **Permission issues**: Verify cluster administrator privileges

### Logs

Check operator logs:
```bash
oc logs -l app.kubernetes.io/name=opentelemetry-operator -n openshift-opentelemetry-operator
```

## Chart Development

### Testing

```bash
# Lint the chart
helm lint ./otel-operator

# Render templates locally
helm template otel-operator ./otel-operator

# Test installation
helm install --dry-run --debug otel-operator ./otel-operator
```

### Directory Structure

```
otel-operator/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── README.md           # This file
└── templates/
    ├── _helpers.tpl    # Template helpers
    ├── namespace.yaml  # Namespace definition
    ├── operatorgroup.yaml  # OperatorGroup resource
    └── subscription.yaml   # Operator subscription
```

## Integration with Other Charts

This operator chart is designed to work with other observability components:

- **Tempo Operator**: For distributed tracing backend
- **Prometheus**: For metrics collection
- **Grafana**: For visualization and dashboards

See the main observability stack documentation for complete integration examples.

## Support

For issues and questions:
- Check the [OpenTelemetry Operator documentation](https://github.com/open-telemetry/opentelemetry-operator)
- Review OpenShift operator troubleshooting guides
- Contact the observability engineering team

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This chart is licensed under the same terms as the OpenTelemetry project.