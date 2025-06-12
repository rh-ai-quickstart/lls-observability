# Llama Stack Observability

A comprehensive repository providing complete observability and deployment solutions for Llama Stack infrastructure on OpenShift. This project combines monitoring, tracing, and visualization capabilities with ready-to-use Helm charts for deploying AI workloads at scale.

## Overview

This repository contains two main components:

1. **[Observability Stack](./observability/)** - Complete monitoring and tracing infrastructure for AI workloads
2. **[Helm Charts](./helm/)** - Production-ready deployment templates for Llama Stack and related services

Together, these components provide a full-stack solution for deploying, monitoring, and observing AI applications in enterprise Kubernetes environments.

Jump straight to [installation](#installation) to get started quickly.

## Table of Contents

- [Description](#description)
- [Architecture](#architecture)
- [Components](#components)
  - [Observability Stack](#observability-stack)
  - [Helm Charts](#helm-charts)
- [Requirements](#requirements)
- [Installation](#installation)
- [Advanced Usage](#advanced-usage)
- [References](#references)

## Description

The Llama Stack Observability project addresses the critical need for comprehensive monitoring and easy deployment of Large Language Model (LLM) infrastructure. As AI workloads become increasingly complex and mission-critical, organizations require:

- **Complete observability** into model performance, resource utilization, and distributed tracing
- **Standardized deployment patterns** for consistent, scalable AI service delivery
- **Enterprise-grade monitoring** with OpenShift-native observability tools
- **Production-ready configurations** that follow cloud-native best practices

This repository provides both the monitoring infrastructure and deployment automation needed to run Llama Stack reliably in production environments.

## Architecture

The observability stack integrates seamlessly with OpenShift's native monitoring capabilities:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Workloads  │───▶│ OpenTelemetry   │───▶│    Backends     │
│                 │    │   Collector     │    │                 │
│ • Llama Stack   │    │                 │    │ • Tempo (Traces)│
│ • vLLM          │    │ • Metrics       │    │ • Prometheus    │
│ • Custom Apps   │    │ • Traces        │    │ • Grafana       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

For detailed architecture information, see the [observability architecture diagram](./observability/diagram-overview.md).

## Components

### Observability Stack

Located in [`./observability/`](./observability/), this component provides:

#### Core Operators
- **Red Hat Build of OpenTelemetry** - Telemetry collection and processing
- **Tempo Operator** - Distributed tracing backend with S3-compatible storage
- **Cluster Observability Operator** - PodMonitor/ServiceMonitor CRDs and UI plugins
- **Grafana Operator** - Visualization and dashboard management

#### Monitoring Components
- **[PodMonitor Examples](./observability/podmonitor-example-0.yaml)** - Pod-level metrics collection
- **[ServiceMonitor Examples](./observability/servicemonitor-example.yaml)** - Service-level metrics collection
- **[OpenTelemetry Collectors](./observability/otel-collector/)** - Central and sidecar deployment patterns
- **[Tempo Configuration](./observability/tempo/)** - Distributed tracing with MinIO storage

#### Visualization
- **[Grafana Dashboards](./observability/grafana/)** - Pre-built dashboards for vLLM and cluster metrics
- **[UI Plugins](./observability/tracing-ui-plugin.yaml)** - OpenShift console integration for tracing
- **Custom Dashboards** - Extensible dashboard configurations

#### Load Testing
- **[GuideLL](./observability/guidellm/)** - AI workload load testing and performance validation

### Helm Charts

Located in [`./helm/`](./helm/), providing production-ready deployments:

#### Core AI Services
- **[`llama-stack`](./helm/llama-stack/)** - Complete Llama Stack deployment with configurable endpoints
- **[`llama3.2-3b`](./helm/llama3.2-3b/)** - Optimized Llama 3.2 3B model deployment on vLLM
- **[`llama-stack-playground`](./helm/llama-stack-playground/)** - Interactive web interface for testing

#### Supporting Services
- **[`mcp-weather`](./helm/mcp-weather/)** - Model Context Protocol weather service example
- **[`hr-api`](./helm/hr-api/)** - Human Resources API demonstration service

Each chart includes:
- Configurable resource limits and requests
- Service accounts and RBAC configurations
- Ingress/Route configurations for OpenShift
- ConfigMap management for application settings
- Production-ready security configurations

## Requirements

### Minimum Hardware Requirements

- **CPU**: 8+ cores recommended for full stack deployment
- **Memory**: 16GB+ RAM for monitoring stack, additional memory based on AI workload requirements
- **Storage**: 100GB+ for observability data retention
- **GPU**: NVIDIA GPU required for AI model inference (varies by model size)

### Required Software

- **OpenShift 4.12+** or **Kubernetes 1.24+**
- **Helm 3.8+** for chart deployment
- **oc CLI** or **kubectl** for cluster management

### Required Operators (for Observability)

Install from OperatorHub:
- Red Hat Build of OpenTelemetry Operator
- Tempo Operator  
- Cluster Observability Operator
- Grafana Operator (optional, for enhanced visualization)

### Required Permissions

- **Cluster Admin** - Required for operator installation and observability stack setup
- **Namespace Admin** - Sufficient for Helm chart deployments in designated namespaces
- **GPU Access** - Required for AI workload deployment

## Installation

### Quick Start - Complete Stack

```bash
# 1. Create observability namespace
oc create namespace observability-hub

# 2. Deploy observability infrastructure
oc apply --kustomize ./observability/tempo -n observability-hub
oc apply --kustomize ./observability/otel-collector -n observability-hub
oc apply --kustomize ./observability/grafana/instance-with-prom-tempo-ds -n observability-hub

# 3. Deploy AI workloads
helm install llama3-2-3b ./helm/llama3.2-3b \
  --set model.name="meta-llama/Llama-3.2-3B-Instruct" \
  --set resources.limits."nvidia\.com/gpu"=1

helm install mcp-weather ./helm/mcp-weather

helm install llama-stack ./helm/llama-stack \
  --set inference.endpoints[0].url="http://llama3-2-3b:80/v1" \
  --set mcpServers[0].uri="http://mcp-weather:80"

helm install llama-stack-playground ./helm/llama-stack-playground \
  --set playground.llamaStackUrl="http://llama-stack:80"

# 4. Enable tracing UI
oc apply -f ./observability/tracing-ui-plugin.yaml
```

### Observability-Only Installation

For monitoring existing AI workloads:

```bash
# Deploy observability stack only
oc create namespace observability-hub
oc apply --kustomize ./observability/tempo -n observability-hub
oc apply --kustomize ./observability/otel-collector -n observability-hub
oc apply -f ./observability/tracing-ui-plugin.yaml

# Create monitors for existing workloads
oc apply -f ./observability/podmonitor-example-0.yaml
oc apply -f ./observability/servicemonitor-example.yaml
```

## Advanced Usage

### Individual Component Deployment

#### Deploy Llama 3.2-3B on vLLM

```bash
helm install llama3-2-3b ./helm/llama3.2-3b \
  --set model.name="meta-llama/Llama-3.2-3B-Instruct" \
  --set resources.limits."nvidia\.com/gpu"=1 \
  --set nodeSelector."nvidia\.com/gpu\.present"="true"
```

#### Deploy MCP Weather Server

```bash
helm install mcp-weather ./helm/mcp-weather 
```

#### Deploy Llama Stack

```bash
helm install llama-stack ./helm/llama-stack \
  --set inference.endpoints[0].url="http://llama3-2-3b:80/v1" \
  --set mcpServers[0].uri="http://mcp-weather:80" 
```

#### Deploy the Playground

```bash
helm install llama-stack-playground ./helm/llama-stack-playground \
  --set playground.llamaStackUrl="http://llama-stack:80"
```

### Custom Observability Configuration

#### Sidecar OpenTelemetry Collectors

Add telemetry collection to any deployment with annotations:

```yaml
# For vLLM workloads
template:
  metadata:
    annotations:
      sidecar.opentelemetry.io/inject: vllm-otelsidecar

# For Llama Stack workloads  
template:
  metadata:
    annotations:
      sidecar.opentelemetry.io/inject: llamastack-otelsidecar
```

#### Custom Grafana Dashboards

```bash
# Deploy vLLM dashboard
oc apply -n observability-hub -f ./observability/grafana/vllm-dashboard/vllm-dashboard.yaml

# Deploy cluster metrics dashboard
oc apply -n observability-hub -f ./observability/grafana/cluster-metrics-dashboard/cluster-metrics.yaml
```

### Load Testing with GuideLL

```bash
# Deploy GuideLL for performance testing
oc apply -f ./observability/guidellm/pvc.yaml
oc apply -f ./observability/guidellm/guidellm-job.yaml
```

## References

### Documentation
- [Observability Configuration Guide](./observability/run-configuration.md)
- [Architecture Overview](./observability/diagram-overview.md)
- [vLLM Distributed Tracing](./observability/vllm-distributed-tracing.md)
- [GuideLL Load Testing](./observability/guidellm/README.md)

### OpenShift Documentation
- [OpenShift Distributed Tracing (Tempo)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/distributed_tracing/distributed-tracing-platform-tempo)
- [OpenShift Observability](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/monitoring)
- [User Workload Monitoring](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/monitoring/enabling-monitoring-for-user-defined-projects)

### Related Projects
- [Llama Stack](https://github.com/meta-llama/llama-stack)
- [vLLM](https://github.com/vllm-project/vllm)
- [OpenTelemetry](https://opentelemetry.io/)
- [Grafana](https://grafana.com/)
- [Tempo](https://grafana.com/oss/tempo/)

### Community
- [Red Hat AI Kickstarts](https://github.com/rh-ai-kickstart)
- [OpenShift AI Documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_cloud_service)