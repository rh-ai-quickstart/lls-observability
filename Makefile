.PHONY: help setup install-operators deploy-observability deploy-ai install-all clean validate

# Default target
help:
	@echo "Llama Stack Observability Deployment"
	@echo "====================================="
	@echo ""
	@echo "Available targets:"
	@echo "  setup              - Create required namespaces"
	@echo "  install-operators  - Install all operators (Phase 1)"
	@echo "  deploy-observability - Deploy observability infrastructure (Phase 2)"
	@echo "  deploy-ai          - Deploy AI workloads and MCP servers (Phase 3)"
	@echo "  install-all        - Complete end-to-end installation"
	@echo "  validate           - Validate configurations and deployments"
	@echo "  clean              - Remove all deployed resources"
	@echo ""
	@echo "Quick start: make install-all"

# Create required namespaces
setup:
	@echo "Creating required namespaces..."
	@oc create namespace observability-hub --dry-run=client -o yaml | oc apply -f-
	@oc create namespace openshift-user-workload-monitoring --dry-run=client -o yaml | oc apply -f-
	@echo "Namespaces created successfully"

# Install operators (Phase 1)
install-operators: setup
	@echo "Installing operators..."
	@chmod +x scripts/install-operators.sh
	@./scripts/install-operators.sh

# Deploy observability infrastructure (Phase 2)
deploy-observability:
	@echo "Deploying observability infrastructure..."
	@chmod +x scripts/deploy-observability.sh
	@./scripts/deploy-observability.sh

# Deploy AI workloads (Phase 3)
deploy-ai:
	@echo "Deploying AI workloads..."
	@chmod +x scripts/deploy-ai-workloads.sh
	@./scripts/deploy-ai-workloads.sh

# Complete installation
install-all: setup
	@echo "Starting complete installation..."
	@chmod +x scripts/install-full-stack.sh
	@./scripts/install-full-stack.sh

# Validate deployments
validate:
	@echo "Validating tempo configuration..."
	@cd helm/02-observability/tempo && ./validate-config.sh
	@echo "Validating MinIO permissions..."
	@cd helm/02-observability/tempo && ./validate-minio-permissions.sh
	@echo "Checking operator status..."
	@oc get pods -n openshift-operators | grep -E "(tempo|grafana|opentelemetry|cluster-observability)" || true
	@echo "Checking observability pods..."
	@oc get pods -n observability-hub || true
	@echo "Checking AI workloads..."
	@oc get pods || true

# Clean up all resources
clean:
	@echo "Removing all deployed resources..."
	@echo "WARNING: This will remove all Helm releases and may affect other workloads!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ]
	@helm list --all-namespaces | grep -E "(cluster-observability-operator|grafana-operator|otel-operator|tempo-operator|tempo|otel-collector|grafana|uwm|llama|mcp-weather|hr-api)" | awk '{print $$1 " -n " $$2}' | xargs -I {} sh -c 'helm uninstall {}'
	@oc delete namespace observability-hub --ignore-not-found=true
	@echo "Cleanup completed"

# Individual chart operations
install-chart:
	@if [ -z "$(CHART)" ]; then echo "Usage: make install-chart CHART=chart-name [NAMESPACE=namespace]"; exit 1; fi
	@NAMESPACE=$${NAMESPACE:-default}; \
	if [ -d "helm/01-operators/$(CHART)" ]; then \
		helm install $(CHART) helm/01-operators/$(CHART); \
	elif [ -d "helm/02-observability/$(CHART)" ]; then \
		helm install $(CHART) helm/02-observability/$(CHART) -n $$NAMESPACE; \
	elif [ -d "helm/03-ai-services/$(CHART)" ]; then \
		helm install $(CHART) helm/03-ai-services/$(CHART); \
	elif [ -d "helm/04-mcp-servers/$(CHART)" ]; then \
		helm install $(CHART) helm/04-mcp-servers/$(CHART); \
	else \
		echo "Chart $(CHART) not found in any directory"; exit 1; \
	fi

uninstall-chart:
	@if [ -z "$(CHART)" ]; then echo "Usage: make uninstall-chart CHART=chart-name [NAMESPACE=namespace]"; exit 1; fi
	@NAMESPACE=$${NAMESPACE:-default}; \
	helm uninstall $(CHART) -n $$NAMESPACE

# Development helpers
template-chart:
	@if [ -z "$(CHART)" ]; then echo "Usage: make template-chart CHART=chart-name"; exit 1; fi
	@if [ -d "helm/01-operators/$(CHART)" ]; then \
		helm template $(CHART) helm/01-operators/$(CHART); \
	elif [ -d "helm/02-observability/$(CHART)" ]; then \
		helm template $(CHART) helm/02-observability/$(CHART); \
	elif [ -d "helm/03-ai-services/$(CHART)" ]; then \
		helm template $(CHART) helm/03-ai-services/$(CHART); \
	elif [ -d "helm/04-mcp-servers/$(CHART)" ]; then \
		helm template $(CHART) helm/04-mcp-servers/$(CHART); \
	else \
		echo "Chart $(CHART) not found in any directory"; exit 1; \
	fi

lint-chart:
	@if [ -z "$(CHART)" ]; then echo "Usage: make lint-chart CHART=chart-name"; exit 1; fi
	@if [ -d "helm/01-operators/$(CHART)" ]; then \
		helm lint helm/01-operators/$(CHART); \
	elif [ -d "helm/02-observability/$(CHART)" ]; then \
		helm lint helm/02-observability/$(CHART); \
	elif [ -d "helm/03-ai-services/$(CHART)" ]; then \
		helm lint helm/03-ai-services/$(CHART); \
	elif [ -d "helm/04-mcp-servers/$(CHART)" ]; then \
		helm lint helm/04-mcp-servers/$(CHART); \
	else \
		echo "Chart $(CHART) not found in any directory"; exit 1; \
	fi