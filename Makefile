# Variables
REG_NAME=kind-registry
REG_PORT=5001
KIND_CLUSTER_NAME=java-o11y
APP_NAMESPACE=java
MONITORING_NAMESPACE=monitoring

# Start the local registry container
start-registry:
	@if [ "$(shell docker inspect -f '{{.State.Running}}' $(REG_NAME) 2>/dev/null || true)" != 'true' ]; then \
		docker run -d --restart=always -p "$(REG_PORT):5000" --name "$(REG_NAME)" registry:2; \
	fi

# Connect the registry to the kind network
connect-registry-to-kind-network:
	@docker network connect kind $(REG_NAME) || true

# Create a kind cluster
define KIND_CONFIG
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:$(REG_PORT)"]
    endpoint = ["http://$(REG_NAME):5000"]
endef
export KIND_CONFIG

create-cluster: start-registry connect-registry-to-kind-network
	#@echo "$$KIND_CONFIG" | kind create cluster --name $(KIND_CLUSTER_NAME) --config=-
	@kind create cluster --config ./cluster.yml

# Build and push the Docker image
build-image:
	@docker build -t localhost:$(REG_PORT)/javao11y:latest .

push-image: build-image
	@docker push localhost:$(REG_PORT)/javao11y:latest

# Setup monitoring tools
setup-monitoring:
	#@kubectl create namespace $(MONITORING_NAMESPACE) || true
	#@curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/examples/simplest.yaml | docker run -i --rm jaegertracing/jaeger-operator:master generate | kubectl apply -n $(MONITORING_NAMESPACE) -f -
	#@helm repo add stable https://charts.helm.sh/stable && helm repo update
	#@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	#@helm install prometheus-operator prometheus-community/kube-prometheus-stack --namespace $(MONITORING_NAMESPACE)
	#@helm install grafana stable/grafana --namespace $(MONITORING_NAMESPACE)
	#@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update && helm install prometheus prometheus-community/kube-prometheus-stack --namespace $(MONITORING_NAMESPACE)

# Deploy the application to Kubernetes
deploy-app: push-image
	@kubectl apply -f kubernetes-app.yml

# Port-forward services
port-forward:
	@kubectl port-forward --namespace $(MONITORING_NAMESPACE) service/prometheus-operated 9090 &
	@kubectl port-forward --namespace $(MONITORING_NAMESPACE) service/grafana 3000:80 &
	@kubectl port-forward --namespace $(O11Y_NAMESPACE) service/javao11y-service 8080:8080 &
	@kubectl port-forward --namespace $(MONITORING_NAMESPACE) service/simplest-query 16686:16686 &

# Complete setup
#setup: create-cluster setup-monitoring deploy-app
setup: create-cluster setup-monitoring


# Clean up resources
clean:
	@kind delete cluster --name $(KIND_CLUSTER_NAME)
	@docker stop $(REG_NAME)
	@docker rm $(REG_NAME)

.PHONY: start-registry connect-registry-to-kind-network create-cluster build-image push-image setup-monitoring deploy-app port-forward setup clean
