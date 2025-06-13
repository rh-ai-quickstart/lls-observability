# Tempo Deployment Architecture Guide

This document explains the Tempo deployment approach using Helm charts that separates operator installation from TempoStack instance creation.

## Architecture Overview

The Tempo deployment is split into two distinct Helm charts:

1. **Tempo Operator** (`tempo-operator/`) - Installs only the operator via OLM
2. **TempoStack Instance** (`tempo/`) - Creates TempoStack instances with MinIO storage

## Deployment Order

### 1. Install the Tempo Operator

First, deploy the Tempo Operator using the Helm chart:

```bash
# Navigate to the operator directory
cd helm/tempo-operator

# Install the operator
helm install tempo-operator .
```

This will:
- Create the `openshift-tempo-operator` namespace
- Install the Tempo Operator via OLM subscription
- Set up the necessary OperatorGroup with cluster-wide scope (AllNamespaces install mode)

**Important Note**: The Tempo operator requires cluster-wide installation (AllNamespaces install mode) and does not support namespace-scoped installation (OwnNamespace mode). The OperatorGroup is configured with an empty `targetNamespaces` array to enable cluster-wide scope while keeping the operator installed in its dedicated namespace.

### 2. Deploy TempoStack with Storage

After the operator is running, deploy the TempoStack instance:

```bash
# Navigate to the tempo directory
cd helm/tempo

# Install TempoStack and MinIO
helm install tempo-stack .
```

This will:
- Create the `observability-hub` namespace
- Deploy MinIO for S3-compatible storage
- Create storage secrets and PVCs
- Deploy a multitenant TempoStack instance
- Set up RBAC for trace access

## Key Benefits of This Approach

### Separation of Concerns
- **Operator Management**: The operator Helm chart handles operator lifecycle
- **Instance Management**: The TempoStack chart handles specific deployments
- **Storage Management**: Dedicated MinIO deployment with proper persistence

### Flexibility
- Multiple TempoStack instances can be created using the same operator
- Different storage backends can be configured per instance
- Easier to manage different environments (dev, staging, prod)
- Helm templating allows for easy customization

### Maintenance
- Operator updates are independent of instance configurations
- Instance configurations can be version-controlled separately
- Easier troubleshooting and debugging
- Standard Helm upgrade/rollback capabilities

## Directory Structure

```
helm/
├── tempo-operator/          # Helm chart for operator installation
│   ├── Chart.yaml          # Operator chart metadata
│   ├── values.yaml         # Operator configuration
│   ├── README.md           # Operator installation guide
│   └── templates/
│       ├── _helpers.tpl
│       ├── namespace.yaml   # Operator namespace
│       ├── operatorgroup.yaml
│       ├── subscription.yaml
│       └── tempostack.yaml  # Placeholder (disabled)
│
└── tempo/                   # Helm chart for TempoStack instances
    ├── Chart.yaml          # TempoStack chart metadata
    ├── values.yaml         # TempoStack and MinIO configuration
    ├── README.md           # TempoStack deployment guide
    └── templates/
        ├── _helpers.tpl
        ├── tempostack.yaml      # TempoStack configuration
        ├── rbac.yaml           # RBAC for trace access
        ├── minio-deployment.yaml # MinIO deployment
        ├── minio-service.yaml   # MinIO service
        ├── minio-pvc.yaml      # MinIO storage
        └── minio-secrets.yaml   # Storage and auth credentials
```

## Configuration Options

### Tempo Operator Configuration

The operator Helm chart supports these key values:

```yaml
# Operator namespace and subscription
operator:
  namespace: openshift-tempo-operator
  subscription:
    name: tempo-product
    channel: stable
    source: redhat-operators

# Namespace creation
namespace:
  create: true
  name: openshift-tempo-operator
```

### TempoStack Configuration

The tempo chart contains configurable options for:

```yaml
# Global settings
global:
  namespace: observability-hub

# TempoStack configuration
tempoStack:
  name: tempostack
  storageSize: 15Gi
  resources:
    total:
      limits:
        memory: 10Gi
        cpu: 5000m
  tenants:
    mode: openshift
    authentication:
      - tenantName: dev
        tenantId: "1610b0c3-c509-4592-a256-a1871353dbfa"

# MinIO configuration
minio:
  storage:
    size: 12Gi
    storageClass: ""  # Use default storage class
  credentials:
    rootUser: admin
    rootPassword: minio123  # CHANGE IN PRODUCTION
```

## Automated Deployment

Use the provided deployment script for automated deployment:

```bash
# Make script executable
chmod +x deploy-tempo.sh

# Run deployment script
./deploy-tempo.sh
```

The script will:
1. Install the Tempo Operator via Helm
2. Install the TempoStack with MinIO via Helm
3. Wait for components to be ready
4. Provide status summary and access information

## Migration from Kustomize Setup

If you have an existing deployment with the old Kustomize approach:

1. **Backup existing data** if you have traces stored
2. **Uninstall old deployment**:
   ```bash
   kubectl delete -k tempo/       # Remove old kustomize deployment
   helm uninstall tempo-operator  # If using old combined chart
   ```
3. **Follow the new deployment order** above

## Troubleshooting

### Operator Issues
Check operator status:
```bash
kubectl get subscription tempo-product -n openshift-tempo-operator
kubectl get csv -n openshift-tempo-operator
helm list -n openshift-tempo-operator
```

### TempoStack Issues
Check TempoStack status:
```bash
kubectl get tempostack -n observability-hub
kubectl describe tempostack tempostack -n observability-hub
helm list -n observability-hub
```

### Storage Issues
Check MinIO and PVC status:
```bash
kubectl get pods,pvc,svc -n observability-hub -l app.kubernetes.io/name=minio-tempo
```

### Helm Operations
Common Helm operations:
```bash
# List releases
helm list -A

# Get values
helm get values tempo-stack -n observability-hub

# Upgrade with new values
helm upgrade tempo-stack ./tempo -f custom-values.yaml

# Rollback if needed
helm rollback tempo-stack 1 -n observability-hub
```

## Security Considerations

⚠️ **Production Deployment Notes**:

1. **Change default credentials** in `values.yaml` for production
2. **Configure proper RBAC** for tenant access
3. **Use external S3** instead of MinIO for production workloads
4. **Enable TLS** for MinIO and Tempo endpoints
5. **Configure resource limits** appropriately for your workload
6. **Use secrets management** for credential handling

## Advanced Configuration

### Custom Values File

Create a custom values file for your environment:

```yaml
# production-values.yaml
global:
  namespace: tempo-production

tempoStack:
  storageSize: 100Gi
  resources:
    total:
      limits:
        memory: 32Gi
        cpu: 16000m

minio:
  storage:
    size: 500Gi
    storageClass: "fast-ssd"
  credentials:
    rootUser: "your-secure-user"
    rootPassword: "your-secure-password"
```

Deploy with custom values:
```bash
helm install tempo-stack ./tempo -f production-values.yaml
```

### Multiple Environments

Deploy multiple TempoStack instances:
```bash
# Development environment
helm install tempo-dev ./tempo -f dev-values.yaml

# Staging environment  
helm install tempo-staging ./tempo -f staging-values.yaml

# Production environment
helm install tempo-prod ./tempo -f prod-values.yaml
```

## Next Steps

After successful deployment:

1. **Configure applications** to send traces to Tempo
2. **Set up Grafana** to query traces from Tempo
3. **Configure alerting** for Tempo component health
4. **Monitor storage usage** and adjust as needed
5. **Set up backup procedures** for trace data

For detailed configuration options, see the README files in each chart directory.