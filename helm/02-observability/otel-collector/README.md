# OpenTelemetry Collector Helm Chart

This Helm chart deploys an OpenTelemetry Collector with sidecar configurations for comprehensive observability in a Kubernetes cluster.

## Overview

This chart provides:
- Main OpenTelemetry Collector deployment for centralized telemetry processing
- LlamaStack sidecar collector for application-specific telemetry
- vLLM sidecar collector for vLLM workload observability
- RBAC configuration for Tempo traces access
- Configurable endpoints and authentication

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- OpenTelemetry Operator installed in the cluster
- Tempo operator and TempoStack instance (for trace export)

## Installation

### Basic Installation

```bash
helm install otel-collector ./otel-collector \
  --namespace observability-hub \
  --create-namespace
```

### Installation with Custom Values

```bash
helm install otel-collector ./otel-collector \
  --namespace observability-hub \
  --create-namespace \
  --values custom-values.yaml
```

## Configuration

### Key Configuration Areas

#### Global Settings

```yaml
global:
  namespace: observability-hub  # Target namespace
```

#### Main Collector

```yaml
collector:
  enabled: true
  name: "otel-collector"
  mode: deployment  # deployment, daemonset, sidecar, statefulset
  replicas: 1
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

#### Tempo Integration

```yaml
tempo:
  gateway:
    endpoint: "tempo-tempostack-gateway"
    port: 8080
    path: "/api/traces/v1/dev"
    protocol: "https"
    namespace: "observability-hub"
  auth:
    orgID: "dev"
    useServiceAccountToken: true
```

#### Prometheus Scrape Configuration

```yaml
prometheus:
  scrapeConfigs:
    llama32_3b:
      jobName: "llama3-2-3b"
      scrapeInterval: "15s"
      targets:
        - "llama3-2-3b-predictor.llama-serve.svc.cluster.local:8080"
```

#### Sidecar Collectors

```yaml
sidecars:
  llamastack:
    enabled: true
    name: "llamastack-otelsidecar-example"
    injectAnnotation: "llamastack-otelsidecar"
    
  vllm:
    enabled: true
    name: "vllm-otelsidecar"
    injectAnnotation: "vllm-otelsidecar"
```

### RBAC Configuration

```yaml
rbac:
  create: true
  clusterRole:
    name: "tempostack-traces-write"
    rules:
      - apiGroups:
          - 'tempo.grafana.com'
        resources:
          - dev
        resourceNames:
          - traces
        verbs:
          - 'create'
```

## Usage

### Using Sidecar Injection

To inject the LlamaStack sidecar collector into your pods, add the following annotation:

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    sidecar.opentelemetry.io/inject: llamastack-otelsidecar
```

For vLLM workloads:

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    sidecar.opentelemetry.io/inject: vllm-otelsidecar
```

### Accessing Collector Endpoints

The main collector exposes the following endpoints:
- OTLP gRPC: `otel-collector-collector:4317`
- OTLP HTTP: `otel-collector-collector:4318`
- Metrics: `otel-collector-collector:8888`

## Customization Examples

### Custom Namespace

```yaml
global:
  namespace: my-observability-namespace
```

### Custom Tempo Endpoint

```yaml
tempo:
  gateway:
    endpoint: "my-tempo-gateway"
    port: 8080
    namespace: "my-tempo-namespace"
```

### Additional Prometheus Targets

```yaml
prometheus:
  scrapeConfigs:
    llama32_3b:
      jobName: "llama3-2-3b"
      scrapeInterval: "15s"
      targets:
        - "llama3-2-3b-predictor.llama-serve.svc.cluster.local:8080"
    my_service:
      jobName: "my-custom-service"
      scrapeInterval: "30s"
      targets:
        - "my-service.default.svc.cluster.local:9090"
```

### Resource Limits

```yaml
collector:
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 200m
      memory: 256Mi

sidecars:
  llamastack:
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 64Mi
```

## Upgrading

```bash
helm upgrade otel-collector ./otel-collector \
  --namespace observability-hub \
  --values custom-values.yaml
```

## Uninstalling

```bash
helm uninstall otel-collector --namespace observability-hub
```

## Troubleshooting

### Common Issues

1. **RBAC Permission Errors**: Ensure the Tempo TempoStack is deployed and accessible
2. **Sidecar Injection Not Working**: Verify the OpenTelemetry Operator is running
3. **Metrics Not Scraped**: Check that target endpoints are accessible

### Debugging Commands

```bash
# Check collector status
kubectl get opentelemetrycollector -n observability-hub

# View collector logs
kubectl logs -n observability-hub deployment/otel-collector-collector

# Check RBAC
kubectl auth can-i create dev --as=system:serviceaccount:observability-hub:otel-collector
```

## Values Reference

For a complete list of configurable values, see the [values.yaml](./values.yaml) file.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Test the chart
5. Submit a pull request

## License

This chart is licensed under the Apache License 2.0.