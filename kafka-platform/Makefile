.PHONY: help bootstrap-dev bootstrap-stage bootstrap-prod deploy-dev deploy-stage deploy-prod smoke-test health-check install-strimzi install-external-secrets destroy-dev destroy-stage destroy-prod

# Variables
ENV ?= dev
AWS_REGION ?= us-east-1
CLUSTER_NAME ?= $(ENV)-kafka-cluster
KAFKA_NAMESPACE ?= kafka
MONITORING_NAMESPACE ?= monitoring

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'

###################
# Infrastructure
###################

bootstrap-dev: ## Bootstrap dev infrastructure (Terraform + EKS)
	@echo "🚀 Bootstrapping dev environment..."
	cd infra/terraform/environments/dev && \
	terraform init && \
	terraform plan -out=tfplan && \
	terraform apply tfplan
	@echo "✅ Dev infrastructure ready"
	@make configure-kubectl ENV=dev

bootstrap-stage: ## Bootstrap stage infrastructure
	@echo "🚀 Bootstrapping stage environment..."
	cd infra/terraform/environments/stage && \
	terraform init && \
	terraform plan -out=tfplan && \
	terraform apply tfplan
	@echo "✅ Stage infrastructure ready"
	@make configure-kubectl ENV=stage

bootstrap-prod: ## Bootstrap production infrastructure (requires approval)
	@echo "⚠️  WARNING: Deploying production infrastructure"
	@read -p "Are you sure? [yes/NO]: " confirm && [ "$$confirm" = "yes" ]
	@echo "🚀 Bootstrapping production environment..."
	cd infra/terraform/environments/prod && \
	terraform init && \
	terraform plan -out=tfplan && \
	terraform apply tfplan
	@echo "✅ Production infrastructure ready"
	@make configure-kubectl ENV=prod

configure-kubectl: ## Configure kubectl for EKS cluster
	@echo "🔧 Configuring kubectl for $(ENV) cluster..."
	aws eks update-kubeconfig --name $(ENV)-kafka-cluster --region $(AWS_REGION)
	kubectl cluster-info

###################
# Operators
###################

install-strimzi: ## Install Strimzi Kafka operator
	@echo "📦 Installing Strimzi operator..."
	kubectl create namespace $(KAFKA_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create -f 'https://strimzi.io/install/latest?namespace=$(KAFKA_NAMESPACE)' -n $(KAFKA_NAMESPACE)
	@echo "⏳ Waiting for Strimzi operator to be ready..."
	kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n $(KAFKA_NAMESPACE) --timeout=300s
	@echo "✅ Strimzi operator installed"

install-external-secrets: ## Install External Secrets Operator
	@echo "📦 Installing External Secrets Operator..."
	helm repo add external-secrets https://charts.external-secrets.io
	helm repo update
	helm upgrade --install external-secrets external-secrets/external-secrets \
		-n external-secrets-system --create-namespace \
		--set installCRDs=true
	@echo "⏳ Waiting for External Secrets Operator to be ready..."
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=external-secrets -n external-secrets-system --timeout=300s
	@echo "✅ External Secrets Operator installed"

install-monitoring: ## Install Prometheus & Grafana stack
	@echo "📦 Installing monitoring stack..."
	kubectl create namespace $(MONITORING_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -k k8s/monitoring/
	@echo "⏳ Waiting for Prometheus to be ready..."
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n $(MONITORING_NAMESPACE) --timeout=300s
	@echo "✅ Monitoring stack installed"

###################
# Kafka Deployment
###################

deploy-dev: install-strimzi install-external-secrets ## Deploy Kafka cluster to dev
	@echo "🚀 Deploying Kafka to dev environment..."
	kubectl apply -k k8s/strimzi/overlays/dev
	@make wait-for-kafka ENV=dev
	@make install-monitoring
	@echo "✅ Kafka dev cluster deployed"
	@make show-endpoints ENV=dev

deploy-stage: install-strimzi install-external-secrets ## Deploy Kafka cluster to stage
	@echo "🚀 Deploying Kafka to stage environment..."
	kubectl apply -k k8s/strimzi/overlays/stage
	@make wait-for-kafka ENV=stage
	@make install-monitoring
	@echo "✅ Kafka stage cluster deployed"
	@make show-endpoints ENV=stage

deploy-prod: install-strimzi install-external-secrets ## Deploy Kafka cluster to prod (requires approval)
	@echo "⚠️  WARNING: Deploying to PRODUCTION"
	@read -p "Are you sure? [yes/NO]: " confirm && [ "$$confirm" = "yes" ]
	@echo "🚀 Deploying Kafka to production environment..."
	kubectl apply -k k8s/strimzi/overlays/prod
	@make wait-for-kafka ENV=prod
	@make install-monitoring
	@echo "✅ Kafka production cluster deployed"
	@make show-endpoints ENV=prod

wait-for-kafka: ## Wait for Kafka cluster to be ready
	@echo "⏳ Waiting for Kafka cluster to be ready..."
	@for i in $$(seq 1 60); do \
		if kubectl get kafka $(ENV)-kafka -n $(KAFKA_NAMESPACE) -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q "True"; then \
			echo "✅ Kafka cluster is ready!"; \
			exit 0; \
		fi; \
		echo "Waiting... ($$i/60)"; \
		sleep 10; \
	done; \
	echo "❌ Timeout waiting for Kafka cluster"; \
	exit 1

show-endpoints: ## Show Kafka endpoints
	@echo "📡 Kafka Endpoints for $(ENV):"
	@echo ""
	@echo "Internal Bootstrap:"
	@kubectl get kafka $(ENV)-kafka -n $(KAFKA_NAMESPACE) -o jsonpath='{.status.listeners[?(@.name=="plain")].bootstrapServers}' 2>/dev/null || echo "Not available yet"
	@echo ""
	@echo "External Bootstrap:"
	@kubectl get kafka $(ENV)-kafka -n $(KAFKA_NAMESPACE) -o jsonpath='{.status.listeners[?(@.name=="external")].bootstrapServers}' 2>/dev/null || echo "Not available yet"
	@echo ""

###################
# Testing
###################

smoke-test: ## Run smoke tests on Kafka cluster
	@echo "🧪 Running smoke tests..."
	./scripts/testing/smoke-test.sh --env $(ENV)
	@echo "✅ Smoke tests passed"

perf-test: ## Run performance tests
	@echo "⚡ Running performance tests..."
	./scripts/testing/perf-test.sh --env $(ENV)

chaos-drill: ## Run chaos engineering drills
	@echo "💥 Running chaos drill..."
	./scripts/testing/chaos-drill.sh --env $(ENV)

health-check: ## Check cluster health
	@echo "🏥 Running health check..."
	@echo ""
	@echo "Kafka Pods:"
	@kubectl get pods -n $(KAFKA_NAMESPACE) -l app.kubernetes.io/name=kafka
	@echo ""
	@echo "Kafka Cluster Status:"
	@kubectl get kafka -n $(KAFKA_NAMESPACE)
	@echo ""
	@echo "Under-Replicated Partitions:"
	@kubectl exec -n $(KAFKA_NAMESPACE) $(ENV)-kafka-0 -c kafka -- \
		bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --under-replicated-partitions 2>/dev/null || echo "None"

###################
# Admin Operations
###################

create-topic: ## Create a topic (usage: make create-topic TOPIC=my-topic PARTITIONS=12)
	@echo "📝 Creating topic: $(TOPIC)"
	./scripts/admin/create-topic.sh --name $(TOPIC) --partitions $(PARTITIONS)

list-topics: ## List all topics
	@echo "📋 Listing topics..."
	./scripts/admin/create-topic.sh --list

create-user: ## Create SCRAM user (usage: make create-user USER=my-user)
	@echo "👤 Creating user: $(USER)"
	./scripts/bootstrap/create-users.sh --create --user $(USER)

set-quota: ## Set user quota (usage: make set-quota USER=my-user RATE=10485760)
	@echo "⚖️  Setting quota for user: $(USER)"
	./scripts/admin/set-quotas.sh --user $(USER) --producer-byte-rate $(RATE)

###################
# Monitoring
###################

port-forward-grafana: ## Port-forward Grafana to localhost:3000
	@echo "🔗 Port-forwarding Grafana to http://localhost:3000"
	@echo "Default credentials: admin/admin"
	kubectl port-forward -n $(MONITORING_NAMESPACE) svc/grafana 3000:80

port-forward-prometheus: ## Port-forward Prometheus to localhost:9090
	@echo "🔗 Port-forwarding Prometheus to http://localhost:9090"
	kubectl port-forward -n $(MONITORING_NAMESPACE) svc/prometheus 9090:9090

###################
# Validation
###################

validate-terraform: ## Validate Terraform configurations
	@echo "🔍 Validating Terraform..."
	@for env in dev stage prod; do \
		echo "Validating $$env..."; \
		cd infra/terraform/environments/$$env && terraform init -backend=false && terraform validate; \
	done
	@echo "✅ Terraform validation passed"

validate-k8s: ## Validate Kubernetes manifests
	@echo "🔍 Validating Kubernetes manifests..."
	kubectl apply --dry-run=client -k k8s/strimzi/overlays/dev
	kubectl apply --dry-run=client -k k8s/strimzi/overlays/stage
	kubectl apply --dry-run=client -k k8s/strimzi/overlays/prod
	@echo "✅ Kubernetes validation passed"

lint: ## Run all linters
	@echo "🔍 Running linters..."
	@make lint-yaml
	@make lint-terraform
	@make lint-shell
	@echo "✅ All linters passed"

lint-yaml: ## Lint YAML files
	@echo "Linting YAML files..."
	@command -v yamllint >/dev/null 2>&1 || { echo "yamllint not installed, skipping..."; exit 0; }
	yamllint -c .yamllint k8s/

lint-terraform: ## Lint Terraform files
	@echo "Linting Terraform files..."
	@cd infra/terraform && terraform fmt -check -recursive

lint-shell: ## Lint shell scripts
	@echo "Linting shell scripts..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not installed, skipping..."; exit 0; }
	find scripts/ -name "*.sh" -exec shellcheck {} \;

###################
# Cleanup
###################

destroy-dev: ## Destroy dev environment
	@echo "⚠️  WARNING: This will destroy dev environment"
	@read -p "Are you sure? [yes/NO]: " confirm && [ "$$confirm" = "yes" ]
	kubectl delete -k k8s/strimzi/overlays/dev --ignore-not-found=true
	cd infra/terraform/environments/dev && terraform destroy -auto-approve

destroy-stage: ## Destroy stage environment
	@echo "⚠️  WARNING: This will destroy stage environment"
	@read -p "Are you sure? [yes/NO]: " confirm && [ "$$confirm" = "yes" ]
	kubectl delete -k k8s/strimzi/overlays/stage --ignore-not-found=true
	cd infra/terraform/environments/stage && terraform destroy -auto-approve

destroy-prod: ## Destroy production environment (DANGEROUS!)
	@echo "🚨 DANGER: This will destroy PRODUCTION!"
	@read -p "Type 'DELETE PRODUCTION' to confirm: " confirm && [ "$$confirm" = "DELETE PRODUCTION" ]
	kubectl delete -k k8s/strimzi/overlays/prod --ignore-not-found=true
	cd infra/terraform/environments/prod && terraform destroy

###################
# Documentation
###################

docs-serve: ## Serve documentation locally
	@echo "📚 Serving documentation on http://localhost:8000"
	@command -v mkdocs >/dev/null 2>&1 || { echo "mkdocs not installed. Run: pip install mkdocs mkdocs-material"; exit 1; }
	mkdocs serve

###################
# CI/CD
###################

ci-lint: lint validate-terraform validate-k8s ## Run CI linting checks

ci-test: smoke-test ## Run CI tests

ci-plan: ## Run Terraform plan (CI)
	@echo "📋 Running Terraform plan..."
	cd infra/terraform/environments/$(ENV) && terraform init && terraform plan

ci-apply: ## Run Terraform apply (CI)
	@echo "🚀 Applying Terraform changes..."
	cd infra/terraform/environments/$(ENV) && terraform apply -auto-approve

###################
# Utilities
###################

clean: ## Clean temporary files
	@echo "🧹 Cleaning temporary files..."
	find . -name "*.tfplan" -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete
	@echo "✅ Cleaned"

logs: ## Tail Kafka broker logs (usage: make logs ENV=dev POD=0)
	@POD ?= 0
	kubectl logs -n $(KAFKA_NAMESPACE) -f $(ENV)-kafka-$(POD) -c kafka

exec-broker: ## Execute shell in broker pod (usage: make exec-broker ENV=dev POD=0)
	@POD ?= 0
	kubectl exec -it -n $(KAFKA_NAMESPACE) $(ENV)-kafka-$(POD) -c kafka -- bash

get-creds: ## Get bootstrap credentials
	@echo "🔑 Bootstrap Servers:"
	@make show-endpoints ENV=$(ENV)
	@echo ""
	@echo "Admin Password:"
	@kubectl get secret $(ENV)-kafka-admin -n $(KAFKA_NAMESPACE) -o jsonpath='{.data.password}' | base64 -d
	@echo ""

###################
# Default
###################

.DEFAULT_GOAL := help
