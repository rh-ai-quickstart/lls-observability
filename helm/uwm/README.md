# UWM (User Workload Monitoring) Helm Chart

This Helm chart deploys PodMonitors for User Workload Monitoring of VLLM and LLaMA Stack services in OpenShift/Kubernetes environments.

## Overview

The UWM (User Workload Monitoring) chart contains PodMonitor resources extracted from the `llama-serve` namespace and converted into configurable Helm templates. This enables monitoring of VLLM-based AI workloads with Prometheus.

Additionally, this chart includes a ConfigMap for enabling user workload monitoring in OpenShift, which is essential infrastructure that the PodMonitors depend on to function properly.

## What's Included

This chart deploys the following resources:

### ConfigMap
- **User Workload Monitoring Config** (`user-workload-monitoring-config`)
  - Enables user workload monitoring in OpenShift
  - Configures Prometheus settings (log level, retention)
  - Enables Alertmanager functionality
  - Deployed to `openshift-user-workload-monitoring` namespace

### PodMonitors

1. **VLLM LLM Monitor** (`vllm-llama-serve-monitor`)
   - Monitors multiple AI models
   - Default scrape interval: 30s
   - Metrics path: `/metrics`

2. **VLLM Metrics Monitor** (`vllm-metrics`)
   - Monitors the llama3-2-3b predictor specifically
   - Default scrape interval: 15s
   - Metrics path: `/metrics`
   - Uses port: `h2c`

## Prerequisites

### Required Operators

**IMPORTANT**: Install these operators **before** deploying the UWM chart:

1. **Cluster Observability Operator** (required for PodMonitor CRDs):
   ```bash
   # Install using the provided helm chart
   helm install cluster-observability-operator ../cluster-observability-operator
   
   # Or install manually from OperatorHub in OpenShift console
   ```

2. **OpenShift User Workload Monitoring** must be supported by your cluster

### Required Namespaces

Create the required namespaces before installation:

```bash
# Create namespace for UWM chart deployment
oc create namespace observability-hub

# Create OpenShift user workload monitoring namespace (OpenShift only)
oc create namespace openshift-user-workload-monitoring
```

### System Requirements

- **OpenShift 4.12+** or **Kubernetes 1.24+** with Prometheus Operator
- **Helm 3.8+** for chart deployment
- **Cluster Admin privileges** for operator installation
- **Namespace Admin privileges** for UWM chart deployment
- **VLLM-based AI workloads** deployed and exposing metrics endpoints

## Installation

### Step 1: Install Prerequisites

```bash
# 1. Install required operator (if not already installed)
helm install cluster-observability-operator ../cluster-observability-operator

# 2. Wait for operator to be ready
oc wait --for=condition=Ready pod -l app.kubernetes.io/name=cluster-observability-operator -n openshift-cluster-observability-operator --timeout=300s

# 3. Create required namespaces
oc create namespace observability-hub
oc create namespace openshift-user-workload-monitoring
```

### Step 2: Install UWM Chart

#### Basic Installation

```bash
# Install in observability-hub namespace
helm install uwm ./uwm -n observability-hub
```

#### Installation with Custom Values

```bash
# Install with custom configuration file
helm install uwm ./uwm -n observability-hub -f custom-values.yaml
```

#### Installation for Specific Target Namespace

```bash
# Monitor workloads in a specific namespace (e.g., llama-serve)
helm install uwm ./uwm -n observability-hub \
  --set global.targetNamespace=llama-serve
```

### Step 3: Verify Installation

```bash
# Check if UWM resources were created
oc get configmap user-workload-monitoring-config -n openshift-user-workload-monitoring
oc get podmonitors -n observability-hub

# Verify user workload monitoring is enabled (OpenShift)
oc get prometheus -n openshift-user-workload-monitoring
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.targetNamespace` | Target namespace for monitoring (defaults to release namespace) | `""` |
| `userWorkloadMonitoring.enabled` | Enable user workload monitoring ConfigMap | `true` |
| `userWorkloadMonitoring.configMapName` | Name of the ConfigMap | `user-workload-monitoring-config` |
| `userWorkloadMonitoring.namespace` | Namespace for the ConfigMap | `openshift-user-workload-monitoring` |
| `userWorkloadMonitoring.prometheus.logLevel` | Prometheus log level | `debug` |
| `userWorkloadMonitoring.prometheus.retention` | Prometheus data retention period | `15d` |
| `userWorkloadMonitoring.alertmanager.enabled` | Enable Alertmanager | `true` |
| `userWorkloadMonitoring.alertmanager.enableAlertmanagerConfig` | Enable AlertmanagerConfig CRD support | `true` |
| `vllmLlamaServeMonitor.enabled` | Enable VLLM LLaMA Serve Monitor | `true` |
| `vllmLlamaServeMonitor.name` | Name of the PodMonitor | `vllm-llama-serve-monitor` |
| `vllmMetricsMonitor.enabled` | Enable VLLM Metrics Monitor | `true` |
| `vllmMetricsMonitor.name` | Name of the PodMonitor | `vllm-metrics` |
| `common.defaultInterval` | Default scrape interval | `30s` |
| `common.defaultPath` | Default metrics path | `/metrics` |

### Example Custom Values

```yaml
# custom-values.yaml
global:
  targetNamespace: "llama-serve"

# User workload monitoring configuration
userWorkloadMonitoring:
  enabled: true
  prometheus:
    logLevel: info
    retention: 30d
  alertmanager:
    enabled: true
    enableAlertmanagerConfig: true
  labels:
    environment: production
    team: ai-platform

vllmLlamaServeMonitor:
  enabled: true
  podMetricsEndpoints:
    - interval: 15s
      path: /metrics
  selector:
    matchExpressions:
      - key: app
        operator: In
        values:
          - safety
          - llama32-3b
          - granite-8b
          - llama31-70b
          - my-custom-model

vllmMetricsMonitor:
  enabled: true
  labels:
    release: prometheus
    environment: production

common:
  defaultInterval: 20s
  commonLabels:
    team: ai-platform
    monitoring: enabled
```

## Monitoring Setup

### User Workload Monitoring

The chart automatically creates the required ConfigMap to enable user workload monitoring in OpenShift. This ConfigMap is deployed to the `openshift-user-workload-monitoring` namespace and configures:

- Prometheus log level and retention settings
- Alertmanager enablement and configuration

**Note**: The `openshift-user-workload-monitoring` namespace must exist before deployment. If it doesn't exist, create it manually:

```bash
oc create namespace openshift-user-workload-monitoring
```

### Verify ConfigMap and PodMonitors

1. Check if the user workload monitoring ConfigMap is created:
```bash
oc get configmap user-workload-monitoring-config -n openshift-user-workload-monitoring
oc describe configmap user-workload-monitoring-config -n openshift-user-workload-monitoring
```

2. Verify PodMonitors are created:

```bash
# Check if PodMonitors are created
oc get podmonitors -n <target-namespace>

# Check PodMonitor details
oc describe podmonitor vllm-llama-serve-monitor -n <target-namespace>
oc describe podmonitor vllm-metrics -n <target-namespace>
```

### Access Metrics

1. **Through Prometheus UI:**
   - Access the Prometheus instance for user workloads
   - Query metrics using PromQL

2. **Through Grafana:**
   - Import dashboards for VLLM metrics
   - Create custom visualizations

## Troubleshooting

### Prerequisites Issues

#### 1. Cluster Observability Operator Not Installed

**Error**: `no matches for kind "PodMonitor"`

**Solution**:
```bash
# Install the required operator first
helm install cluster-observability-operator ../cluster-observability-operator

# Wait for CRDs to be available
oc wait --for=condition=Established crd/podmonitors.monitoring.coreos.com --timeout=300s
```

#### 2. Missing Namespace

**Error**: `namespace "openshift-user-workload-monitoring" not found`

**Solution**:
```bash
# Create the required namespace
oc create namespace openshift-user-workload-monitoring
```

### Installation Issues

#### 3. PodMonitor Creation Failed

**Error**: `admission webhook denied the request`

**Diagnosis**:
```bash
# Check if the operator is running
oc get pods -n openshift-cluster-observability-operator

# Check operator logs
oc logs -l app.kubernetes.io/name=cluster-observability-operator -n openshift-cluster-observability-operator
```

#### 4. User Workload Monitoring Not Enabled

**Error**: No metrics appearing in Prometheus

**Diagnosis & Solution**:
```bash
# Check if user workload monitoring ConfigMap exists
oc get configmap user-workload-monitoring-config -n openshift-user-workload-monitoring

# Check if Prometheus is running for user workloads
oc get prometheus -n openshift-user-workload-monitoring

# If missing, reinstall the chart with user workload monitoring enabled
helm upgrade uwm ./uwm -n observability-hub --set userWorkloadMonitoring.enabled=true
```

### Monitoring Issues

#### 5. PodMonitor Not Scraping Metrics

**Diagnosis**:
```bash
# 1. Check if target pods exist and have correct labels
oc get pods -l app=llama32-3b -n <target-namespace>
oc get pods -l app=isvc.llama3-2-3b-predictor -n <target-namespace>

# 2. Verify metrics endpoint is accessible
oc port-forward pod/<pod-name> 8080:8080 -n <target-namespace>
curl http://localhost:8080/metrics

# 3. Check PodMonitor configuration
oc describe podmonitor vllm-llama-serve-monitor -n observability-hub
oc describe podmonitor vllm-metrics -n observability-hub
```

**Common Solutions**:
- Ensure target pods have the correct labels matching the PodMonitor selector
- Verify the metrics endpoint port and path are correct
- Check if the target namespace matches `global.targetNamespace`

#### 6. No Metrics in Prometheus

**Diagnosis**:
```bash
# Check Prometheus configuration
oc get prometheus -n openshift-user-workload-monitoring -o yaml

# Check ServiceMonitor/PodMonitor status
oc get podmonitors -n observability-hub -o yaml

# Review Prometheus logs
oc logs -l app.kubernetes.io/name=prometheus -n openshift-user-workload-monitoring
```

**Solutions**:
- Verify User Workload Monitoring is properly enabled
- Check namespace selectors in PodMonitors
- Ensure RBAC permissions are correct

### Configuration Issues

#### 7. Wrong Target Namespace

**Issue**: Monitoring the wrong namespace

**Solution**:
```bash
# Update target namespace
helm upgrade uwm ./uwm -n observability-hub \
  --set global.targetNamespace=correct-namespace
```

#### 8. Custom Models Not Being Monitored

**Solution**: Add your model labels to the PodMonitor selector:
```bash
helm upgrade uwm ./uwm -n observability-hub \
  --set vllmLlamaServeMonitor.selector.matchExpressions[0].values='{safety,llama32-3b,granite-8b,llama31-70b,your-model}'
```

### Verification Commands

```bash
# Complete health check
echo "=== UWM Health Check ==="

echo "1. Check operators:"
oc get pods -n openshift-cluster-observability-operator

echo "2. Check namespaces:"
oc get namespace observability-hub openshift-user-workload-monitoring

echo "3. Check user workload monitoring:"
oc get configmap user-workload-monitoring-config -n openshift-user-workload-monitoring
oc get prometheus -n openshift-user-workload-monitoring

echo "4. Check PodMonitors:"
oc get podmonitors -n observability-hub

echo "5. Check target pods:"
oc get pods -n <your-target-namespace> -l 'app in (safety,llama32-3b,granite-8b,llama31-70b,isvc.llama3-2-3b-predictor)'
```

## Installation Order & Dependencies

### Proper Installation Sequence

For a complete observability setup, follow this order:

```bash
# 1. Install required operators (prerequisite)
helm install cluster-observability-operator ../cluster-observability-operator

# 2. Wait for operators to be ready
oc wait --for=condition=Ready pod -l app.kubernetes.io/name=cluster-observability-operator -n openshift-cluster-observability-operator --timeout=300s

# 3. Create namespaces
oc create namespace observability-hub
oc create namespace openshift-user-workload-monitoring

# 4. Install UWM chart
helm install uwm ./uwm -n observability-hub

# 5. Deploy your AI workloads (with proper labels)
helm install llama3-2-3b ../llama3.2-3b \
  --set model.name="meta-llama/Llama-3.2-3B-Instruct" \
  --set resources.limits."nvidia\.com/gpu"=1

# 6. Verify metrics are being collected
oc get podmonitors -n observability-hub
oc get prometheus -n openshift-user-workload-monitoring
```

### Dependencies Summary

- **Cluster Observability Operator** → Provides PodMonitor CRDs
- **OpenShift User Workload Monitoring** → Enables Prometheus for user workloads
- **Target AI Workloads** → Must have correct labels matching PodMonitor selectors

### Post-Installation Verification

After installation, verify everything is working:

```bash
# Step 1: Check all components are running
oc get pods -n openshift-cluster-observability-operator
oc get pods -n openshift-user-workload-monitoring
oc get podmonitors -n observability-hub

# Step 2: Verify target workloads are labeled correctly
oc get pods -n <target-namespace> --show-labels | grep -E "app=(safety|llama32-3b|granite-8b|llama31-70b|isvc.llama3-2-3b-predictor)"

# Step 3: Test metrics endpoints
oc port-forward pod/<target-pod> 8080:8080 -n <target-namespace>
curl http://localhost:8080/metrics

# Step 4: Check Prometheus targets (if accessible)
# Navigate to Prometheus UI → Status → Targets
```

## Customization

### Adding New Models

To monitor additional AI models, extend the selector values:

```yaml
vllmLlamaServeMonitor:
  selector:
    matchExpressions:
      - key: app
        operator: In
        values:
          - safety
          - llama32-3b
          - granite-8b
          - llama31-70b
          - my-new-model  # Add your model here
```

### Custom Metrics Endpoints

To add custom metrics endpoints:

```yaml
vllmLlamaServeMonitor:
  podMetricsEndpoints:
    - interval: 30s
      path: /metrics
    - interval: 60s
      path: /custom-metrics
      port: 9090
```

## Original Source

This Helm chart was created by extracting and cleaning PodMonitors from the `llama-serve` namespace. The original resources have been converted to configurable Helm templates while preserving their core functionality.

## Support

For issues related to:
- Helm chart: Check this README and values.yaml
- Prometheus configuration: Consult OpenShift User Workload Monitoring documentation
- VLLM metrics: Refer to VLLM documentation

## Chart Information

- **Chart Name**: uwm
- **Chart Version**: 0.1.0
- **App Version**: 1.0.0
- **Kubernetes Version**: 1.20+
- **Helm Version**: 3.0+