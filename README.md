# Llama Stack Telemetry & Observability

Observability & telemetry quickstart for both Llama-Stack and OpenShift AI.

This repository provides helm charts for deploying AI services with telemetry and observability on Llama-Stack, OpenShift and OpenShift AI.

Jump straight to [installation](#installation) to get started quickly.

## Table of Contents

- [Detailed description](#detailed-description)
    - [Architecture](#architecture)
    - [Components](#components)
- [Requirements](#requirements)
- [Installation](#installation)
- [Advanced Usage](#advanced-usage)
    - [MaaS Integration (Optional)](#maas-integration-optional)
    - [Uninstall](#uninstall)
- [References](#references)

## Detailed description

This telemetry and observability quickstart addresses the critical needs for Large Language Model (LLM) infrastructure. As AI workloads become more complex, organizations need:

- **AI observability** into model performance, resource utilization, and distributed tracing
- **Standardized deployment patterns** for consistent, scalable AI service delivery
- **Enterprise-grade monitoring** with OpenShift-native observability tools

This repository provides helm charts for both the monitoring infrastructure and AI service deployments needed to run Llama Stack reliably in production environments.

## FSI Use Case: Financial AI Audit System

This quickstart includes a **Financial Services Industry (FSI) compliance demo** that demonstrates auditability and traceability for AI-powered financial applications.

The demo shows how distributed tracing captures every step of an AI-driven loan decision process:

![FSI Tracing Flow](assets/images/traces4.png)

This provides complete audit trails for regulatory compliance and risk management in financial AI systems.

### Architecture

The proposed observability & telemetry architecture:

![observability architecture diagram](./assets/images/architecture.png).

### Components

All components are organized by dependency layers in the [`./helm/`](./helm/) directory:

#### Phase 1: Operators (`./helm/01-operators/`)
- **[`cluster-observability-operator`](./helm/01-operators/cluster-observability-operator/)** - PodMonitor/ServiceMonitor CRDs and UI plugins
- **[`grafana-operator`](./helm/01-operators/grafana-operator/)** - Grafana operator for visualization and dashboard management
- **[`otel-operator`](./helm/01-operators/otel-operator/)** - Red Hat Build of OpenTelemetry operator
- **[`tempo-operator`](./helm/01-operators/tempo-operator/)** - Distributed tracing backend operator

#### Phase 2: Observability Infrastructure (`./helm/02-observability/`)
- **[`tempo`](./helm/02-observability/tempo/)** - Distributed tracing backend with S3-compatible storage
- **[`otel-collector`](./helm/02-observability/otel-collector/)** - OpenTelemetry collector configurations for telemetry collection and processing
- **[`grafana`](./helm/02-observability/grafana/)** - Visualization and dashboard management with pre-built dashboards
- **[`uwm`](./helm/02-observability/uwm/)** - User Workload Monitoring with PodMonitors for VLLM and AI workloads
- **[`distributed-tracing-ui-plugin`](./helm/02-observability/distributed-tracing-ui-plugin/)** - OpenShift console integration for tracing

#### Phase 3: AI Services (`./helm/03-ai-services/`)
- **[`llama-stack-instance`](./helm/03-ai-services/llama-stack-instance/)** - Complete Llama Stack Instance with configurable endpoints
- **[`llama3.2-3b`](./helm/03-ai-services/llama3.2-3b/)** - Llama 3.2 3B model deployment on vLLM
- **[`llama-stack-playground`](./helm/03-ai-services/llama-stack-playground/)** - Interactive Llama-Stack web interface for testing
- **[`llama-guard`](./helm/03-ai-services/llama-guard/)** - Llama Guard 1B for providing Safety / Shield mechanisms 

#### Phase 4: MCP Servers (`./helm/04-mcp-servers/`)
- **[`mcp-weather`](./helm/04-mcp-servers/mcp-weather/)** - MCP weather service
- **[`hr-api`](./helm/04-mcp-servers/hr-api/)** - MCP HR API demonstration service
- **[`openshift-mcp`](./helm/04-mcp-servers/openshift-mcp/)** - MCP OpenShift/Kubernetes operations service

### Observability in Action

The telemetry and observability stack provides comprehensive visibility into AI workload performance and distributed system behavior.

#### Distributed Tracing Examples

![Llama Stack Request Tracing](assets/images/traces1.png)

**End-to-End Request Tracing**: Complete visibility into AI inference request flows through the Llama Stack infrastructure.

![Detailed Service Interaction Tracing](assets/images/traces2.png)

**Create Agent from LlamaStack Tracing**: Detailed trace view showing complex interactions between different services in the AI stack.

These traces provide insights into:
- Request latency and service dependencies
- Error tracking and performance bottlenecks
- Load distribution across model endpoints

## Requirements

### Minimum Hardware Requirements

- **CPU**: 8+ cores recommended for full stack deployment
- **Memory**: 16GB+ RAM for monitoring stack, additional memory based on AI workload requirements
- **Storage**: 100GB+ for observability data retention
- **GPU**: NVIDIA GPU required for AI model inference (varies by model size)

### Required Software

- **OpenShift 4.12+** or **Kubernetes 1.24+**
- **OpenShift AI 2.19 onwards**
- **Helm 3.8+** for chart deployment
- **oc CLI** or **kubectl** for cluster management

### Required Operators

Install these operators from OperatorHub before deploying the observability stack:

Install manually from OperatorHub:
- Red Hat Build of OpenTelemetry Operator
- Tempo Operator
- Cluster Observability Operator
- Grafana Operator

### Required Permissions

- **Cluster Admin** - Required for operator installation and observability stack setup
- **GPU Access** - Required for AI workload deployment

## Installation

### Quick Start - Automated Installation

**Option 1: Complete Stack (Recommended)**
```bash
# Run the full installation script
./scripts/install-full-stack.sh
```

**Option 2: Phase-by-Phase Installation**
```bash
# Phase 1: Install operators
./scripts/install-operators.sh

# Phase 2: Deploy observability infrastructure
./scripts/deploy-observability.sh

# Phase 3: Deploy AI workloads
./scripts/deploy-ai-workloads.sh
```

**Option 3: Using Makefile (Optional)**
```bash
# Install everything in one command
make install-all

# Or phase-by-phase
make install-operators      # Phase 1
make deploy-observability   # Phase 2  
make deploy-ai              # Phase 3
```

## Advanced Usage

### Manual Step-by-Step Installation

For users who prefer to understand each step or need to customize the installation.

Set these environment variables before running the installation commands:

```bash
export OBSERVABILITY_NAMESPACE="observability-hub"
export UWM_NAMESPACE="openshift-user-workload-monitoring"
export AI_SERVICES_NAMESPACE="llama-serve"
```

Launch this instructions:

```bash
# 1. Create required namespaces
oc create namespace ${OBSERVABILITY_NAMESPACE}
oc create namespace ${UWM_NAMESPACE}
oc create namespace ${AI_SERVICES_NAMESPACE}

# 2. Install required operators
helm install cluster-observability-operator ./helm/01-operators/cluster-observability-operator
helm install grafana-operator ./helm/01-operators/grafana-operator
helm install otel-operator ./helm/01-operators/otel-operator
helm install tempo-operator ./helm/01-operators/tempo-operator

# 3. Wait for operators to be ready
oc wait --for=condition=Ready pod -l app.kubernetes.io/name=cluster-observability-operator -n openshift-cluster-observability-operator --timeout=300s
oc wait --for=condition=Ready pod -l app.kubernetes.io/name=observability-operator -n openshift-cluster-observability-operator --timeout=300s

# 4. Deploy observability infrastructure
helm install tempo ./helm/02-observability/tempo -n ${OBSERVABILITY_NAMESPACE}
helm install otel-collector ./helm/02-observability/otel-collector -n ${OBSERVABILITY_NAMESPACE}
helm install grafana ./helm/02-observability/grafana -n ${OBSERVABILITY_NAMESPACE}

# 5. Enable User Workload Monitoring for AI workloads
helm template uwm ./helm/02-observability/uwm -n ${OBSERVABILITY_NAMESPACE} | oc apply -f-

# Verify UWM setup
oc get configmap user-workload-monitoring-config -n ${UWM_NAMESPACE}
oc get podmonitors -n ${OBSERVABILITY_NAMESPACE}

# 6. Deploy AI workloads
# Deploy MCP servers in AI services namespace
helm install mcp-weather ./helm/04-mcp-servers/mcp-weather -n ${AI_SERVICES_NAMESPACE}
helm install hr-api ./helm/04-mcp-servers/hr-api -n ${AI_SERVICES_NAMESPACE}

# Milvus vector database is configured inline within llama-stack-instance
# No external Milvus deployment needed

# Deploy AI services in AI services namespace  
helm install llama3-2-3b ./helm/03-ai-services/llama3.2-3b -n ${AI_SERVICES_NAMESPACE} \
  --set model.name="meta-llama/Llama-3.2-3B-Instruct" \
  --set resources.limits."nvidia\.com/gpu"=1

helm install llama-stack-instance ./helm/03-ai-services/llama-stack-instance -n ${AI_SERVICES_NAMESPACE} \
  --set 'mcpServers[0].name=weather' \
  --set 'mcpServers[0].uri=http://mcp-weather.${AI_SERVICES_NAMESPACE}.svc.cluster.local:80' \
  --set 'mcpServers[0].description=Weather MCP Server for real-time weather data'

helm install llama-stack-playground ./helm/03-ai-services/llama-stack-playground -n ${AI_SERVICES_NAMESPACE} \
  --set playground.llamaStackUrl="http://llama-stack-instance.${AI_SERVICES_NAMESPACE}.svc.cluster.local:80"

helm install llama-guard ./helm/03-ai-services/llama-guard -n ${AI_SERVICES_NAMESPACE}

# 7. Enable tracing UI
helm install distributed-tracing-ui-plugin ./helm/02-observability/distributed-tracing-ui-plugin
```

### MaaS Integration (Optional)

**Model-as-a-Service (MaaS) Remote Models**

The Llama Stack can optionally integrate with external MaaS (Models as a Server) to access remote models without local GPU requirements.

**Configuration Options:**
```yaml
maas:
  enabled: true                    # Enable MaaS provider
  apiToken: "your-api-token"      # Authentication token
  url: "https://endpoint.com/v1"  # MaaS endpoint URL
  maxTokens: 200000               # Maximum token limit
  tlsVerify: false                # TLS verification
  modelId: "model-name"           # Specific model identifier
```

### Uninstall

**Complete Stack Uninstall**
```bash
# Uninstall everything in reverse order
make clean
```

## References

### Documentation
- [OpenShift Distributed Tracing (Tempo)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/distributed_tracing/distributed-tracing-platform-tempo)
- [OpenShift Observability](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/monitoring)
- [User Workload Monitoring](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/monitoring/enabling-monitoring-for-user-defined-projects)

### Related Projects
- [Llama Stack](https://github.com/meta-llama/llama-stack)
- [vLLM](https://github.com/vllm-project/vllm)
- [OpenTelemetry](https://opentelemetry.io/)
- [Grafana](https://grafana.com/)
- [Tempo](https://grafana.com/oss/tempo/)