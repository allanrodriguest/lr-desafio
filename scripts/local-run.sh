#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${1:-lr-app-kind}"
IMAGE="${2:-allanrodriguest/lr-infra:latest}"

# 1) create kind config with 1 control-plane and 2 workers
cat > /tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF

echo "Creating kind cluster..."
kind create cluster --name "$CLUSTER_NAME" --config /tmp/kind-config.yaml

# 2) install ingress-nginx (controller)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml

# 3) build image locally and load into kind
docker build -t "$IMAGE" .
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

# 5) deploy manifests
kubectl -n posts-app apply -f k8s/0-namespace.yaml || true
kubectl -n posts-app apply -f k8s/02-deployment.yaml
kubectl -n posts-app apply -f k8s/03-service.yaml
kubectl -n posts-app apply -f k8s/reverse-proxy.yaml

# 6) wait for pods ready
kubectl -n posts-app wait --for=condition=available deployment/posts-deployment --timeout=120s || true
kubectl -n posts-app rollout status deployment/posts-deployment

# 7) run smoke tests against nginx-proxy NodePort/LoadBalancer
# get service IP/port (kind uses NodePort + cluster nodes)
PROXY_PORT=$(kubectl -n posts-app get svc nginx-proxy-svc -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CLUSTER_NAME-control-plane" || echo "127.0.0.1")

BASE_URL="http://${NODE_IP}:${PROXY_PORT}"
echo "Running smoke tests against $BASE_URL"
./tests/smoke.sh "$BASE_URL"


echo "Local run complete. To delete cluster: kind delete cluster --name $CLUSTER_NAME"
