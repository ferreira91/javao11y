##!/bin/bash
#set -o errexit
#
## 1. Create a registry container unless it already exists
#reg_name='kind-registry'
#reg_port='5000'
#if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
#  docker run \
#    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
#    registry:2
#fi
#
## 2. Create a kind cluster
#kind create cluster --name java-o11y --config=-
#kind: Cluster
#apiVersion: kind.x-k8s.io/v1alpha4
#containerdConfigPatches:
#- |-
#  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
#    endpoint = ["http://${reg_name}:5000"]
#
## 3. Build the Docker image of the application
#docker build -t localhost:${reg_port}/javao11y:latest .
#
## 4. Push the image to the local registry
#docker push localhost:${reg_port}/javao11y:latest
#
## 5. Create Kubernetes resources for javao11y
#kubectl apply -f kubernetes-app.yml
#
## 6. Add Helm repositories and update
#helm repo add stable https://charts.helm.sh/stable
#helm repo update
#
## 7. Install Prometheus
#helm install prometheus stable/prometheus --set server.configFile=prometheus.yml
#
## 8. Install Grafana
#helm install grafana stable/grafana
#
## 9. Port-forward for the services
#echo "Starting port-forward for Prometheus, Grafana, and javao11y..."
#kubectl port-forward service/prometheus-server 9090:80 &
#kubectl port-forward service/grafana 3000:80 &
##kubectl port-forward service/javao11y 8080:80 &
#
#echo "Access the services at the following URLs:"
#echo "Prometheus: http://localhost:9090"
#echo "Grafana: http://localhost:3000"
#echo "javao11y: http://localhost:8080"
#
## Keep the script running to maintain the port-forward active
#wait
#!/bin/sh
set -o errexit

# 1. Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# 2. Create kind cluster with containerd registry config dir enabled
# TODO: kind will eventually enable this by default and this patch will
# be unnecessary.
#
# See:
# https://github.com/kubernetes-sigs/kind/issues/2875
# https://github.com/containerd/containerd/blob/main/docs/cri/config.md#registry-configuration
# See: https://github.com/containerd/containerd/blob/main/docs/hosts.md
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
EOF

# 3. Add the registry config to the nodes
#
# This is necessary because localhost resolves to loopback addresses that are
# network-namespace local.
# In other words: localhost in the container is not localhost on the host.
#
# We want a consistent name that works from both ends, so we tell containerd to
# alias localhost:${reg_port} to the registry container when pulling images
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
done

# 4. Connect the registry to the cluster network if not already connected
# This allows kind to bootstrap the network but ensures they're on the same network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# 5. Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"