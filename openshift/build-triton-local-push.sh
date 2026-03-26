#!/bin/bash
# Build Triton image locally and push to the OpenShift internal registry (bypasses cluster
# binary build + "wait for build pod to run" API timeout). Requires: podman or docker, oc login.
set -euo pipefail

if [[ -z "${NAMESPACE:-}" ]]; then
  NAMESPACE=$(oc project -q 2>/dev/null) || true
fi
if [[ -z "${NAMESPACE:-}" ]]; then
  echo "ERROR: Set NAMESPACE or: oc project <namespace>"
  exit 1
fi

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)

if ! oc whoami &>/dev/null; then
  echo "ERROR: Not logged in. Run oc login."
  exit 1
fi

REGISTRY=$(oc registry info --public 2>/dev/null || oc registry info)
if [[ -z "$REGISTRY" ]]; then
  echo "ERROR: Could not resolve registry (oc registry info)."
  exit 1
fi

echo "Registry: $REGISTRY"
echo "Logging in to registry..."
oc registry login

IMAGE="${REGISTRY}/${NAMESPACE}/fraud-triton:latest"
echo "Building: $IMAGE"
echo "Context: $REPO_ROOT/triton"

if command -v podman &>/dev/null; then
  podman build -t "$IMAGE" "$REPO_ROOT/triton"
  podman push "$IMAGE"
elif command -v docker &>/dev/null; then
  docker build -t "$IMAGE" "$REPO_ROOT/triton"
  docker push "$IMAGE"
else
  echo "ERROR: Install podman or docker."
  exit 1
fi

echo ""
echo "Push complete: $IMAGE"
echo "Verify: oc get imagestream fraud-triton -n $NAMESPACE"
