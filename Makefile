# Superset MCP Service Makefile for OpenShift

.PHONY: help build deploy clean logs health test

# Default target
help:
	@echo "Superset MCP Service - OpenShift Deployment"
	@echo ""
	@echo "Available commands:"
	@echo "  build     - Build the Docker image in OpenShift"
	@echo "  deploy    - Deploy the service to OpenShift"
	@echo "  clean     - Remove all OpenShift resources"
	@echo "  logs      - Show service logs"
	@echo "  health    - Check service health"
	@echo "  test      - Run basic connectivity tests"
	@echo "  help      - Show this help message"

# Build the Docker image
build:
	@echo "Building Superset MCP Service..."
	oc start-build superset-mcp --follow

# Deploy all resources
deploy: 
	@echo "Deploying Superset MCP Service to OpenShift..."
	oc apply -f openshift-config-secret.yaml
	oc apply -f openshift-buildconfig.yaml
	oc apply -f openshift-deployment.yaml
	@echo "Waiting for deployment to be ready..."
	oc rollout status deployment/superset-mcp
	@echo "Deployment completed!"
	@echo "Route URL: https://$(oc get route superset-mcp -o jsonpath='{.spec.host}')"

# Clean up all resources
clean:
	@echo "Removing Superset MCP Service from OpenShift..."
	oc delete route,deployment,service,hpa,buildconfig,imagestream,secret -l app=superset-mcp --ignore-not-found=true
	@echo "Cleanup completed!"

# Show logs
logs:
	@echo "Showing Superset MCP Service logs..."
	oc logs -l app=superset-mcp -f

# Check health
health:
	@echo "Checking Superset MCP Service health..."
	@echo "Pods:"
	oc get pods -l app=superset-mcp
	@echo ""
	@echo "Services:"
	oc get svc -l app=superset-mcp
	@echo ""
	@echo "Routes:"
	oc get route -l app=superset-mcp
	@echo ""
	@echo "Health Check:"
	curl -f https://$(oc get route superset-mcp -o jsonpath='{.spec.host}')/health || echo "❌ Health check failed"

# Run basic tests
test:
	@echo "Running basic connectivity tests..."
	@echo "Testing health endpoint..."
	curl -f https://$(oc get route superset-mcp -o jsonpath='{.spec.host}')/health || (echo "❌ Health check failed" && exit 1)
	@echo "✅ Health check passed"
	@echo "Testing MCP endpoint..."
	curl -X POST https://$(oc get route superset-mcp -o jsonpath='{.spec.host}')/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}' || (echo "❌ MCP endpoint test failed" && exit 1)
	@echo "✅ MCP endpoint test passed"

# Scale deployment
scale:
	@if [ -z "$(REPLICAS)" ]; then echo "Usage: make scale REPLICAS=3"; exit 1; fi
	@echo "Scaling to $(REPLICAS) replicas..."
	oc scale deployment superset-mcp --replicas=$(REPLICAS)
	oc rollout status deployment/superset-mcp

# Get shell access to pod
shell:
	@echo "Getting shell access to MCP Service pod..."
	oc exec -it $$(oc get pods -l app=superset-mcp -o jsonpath='{.items[0].metadata.name}') -- /bin/bash

# Show configuration
config:
	@echo "Showing Superset MCP Service configuration..."
	@echo "Secret:"
	oc get secret superset-mcp-config -o yaml
	@echo ""
	@echo "Deployment:"
	oc get deployment superset-mcp -o yaml | grep -A 20 "env:"
