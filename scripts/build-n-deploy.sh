#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-allanrodriguest/lr-infra:latest}"
K8S_NAMESPACE="${2:-lr-app}"
CHART_DIR="${3:-./chart/posts}"

# build
echo "Building image $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" .

# login (interactive) or ensure docker is logged in already
# docker login

# push
echo "Pushing image..."
docker push "$IMAGE_NAME"

# kubectl apply: using Helm if chart exists
if [ -d "$CHART_DIR" ]; then
  echo "Deploying with Helm..."
  helm upgrade --install posts "$CHART_DIR" \
    --namespace "$K8S_NAMESPACE" \
    --create-namespace \
    --set image.repository="${IMAGE_NAME%:*}" \
    --set image.tag="${IMAGE_NAME##*:}"
else
  echo "Applying k8s manifests..."
  kubectl apply -n "$K8S_NAMESPACE" -f k8s/
fi

echo "Done."
echo "You can now run the smoke tests: ./tests/smoke.sh http://localhost:3000"