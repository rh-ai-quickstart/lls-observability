# Distributed Tracing UI Plugin Helm Chart

This Helm chart deploys the OpenShift Distributed Tracing UI Plugin, which enables distributed tracing capabilities in the OpenShift console.

## Description

The Distributed Tracing UI Plugin provides a user interface for viewing and analyzing distributed traces in OpenShift. This chart creates a UIPlugin custom resource that integrates the distributed tracing functionality into the OpenShift web console.

## Prerequisites

- OpenShift Container Platform 4.10+
- OpenShift Distributed Tracing Platform Operator installed
- Cluster administrator privileges

## Installation

```bash
helm install distributed-tracing-ui-plugin ./distributed-tracing-ui-plugin
```

## Configuration

### UIPlugin Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `uiPlugin.name` | Name of the UIPlugin resource | `distributed-tracing` |
| `uiPlugin.type` | Type of the UI plugin | `DistributedTracing` |
| `uiPlugin.labels` | Additional labels for the UIPlugin | `{}` |
| `uiPlugin.annotations` | Additional annotations for the UIPlugin | `{}` |

### General Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the full name of the resources | `""` |
| `metadata.commonLabels` | Additional labels for all resources | `{}` |
| `metadata.commonAnnotations` | Additional annotations for all resources | `{}` |

### Monitoring Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `monitoring.enabled` | Enable monitoring labels | `true` |
| `monitoring.labels` | Additional monitoring labels | See values.yaml |

### Advanced Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `advanced.enabled` | Enable advanced UIPlugin features | `false` |
| `advanced.spec` | Additional spec configurations | `{}` |

## Examples

### Basic Installation

```bash
helm install my-tracing-plugin ./distributed-tracing-ui-plugin
```

## Uninstallation

```bash
helm uninstall distributed-tracing-ui-plugin
```

## Notes

- The UIPlugin name should typically remain as "distributed-tracing" as per OpenShift documentation requirements
- This chart only creates the UIPlugin resource; the actual distributed tracing infrastructure must be deployed separately
- Ensure the OpenShift Distributed Tracing Platform Operator is installed before deploying this chart

## Support

For issues and support, please contact the Observability Engineering Team.