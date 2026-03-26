#!/bin/bash
set -euo pipefail

if [[ -z "${NAMESPACE:-}" ]]; then
  NAMESPACE=$(oc project -q 2>/dev/null) || true
fi
if [[ -z "${NAMESPACE:-}" ]]; then
  echo "ERROR: Set NAMESPACE (e.g. export NAMESPACE=fraud-detection) or: oc project <namespace>"
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

if ! oc whoami &>/dev/null; then
  echo "ERROR: Not logged in to OpenShift. Run 'oc login' first."
  exit 1
fi

oc project "$NAMESPACE" 2>/dev/null || oc new-project "$NAMESPACE"

if [ -z "${NGC_API_KEY:-}" ] && [ -z "${NVIDIA_API_KEY:-}" ]; then
  echo "ERROR: Set NGC_API_KEY (or NVIDIA_API_KEY) for nvcr.io image pulls."
  exit 1
fi

REGISTRY_KEY="${NGC_API_KEY:-${NVIDIA_API_KEY:-}}"

echo "Ensuring NGC image pull secret exists..."
oc delete secret ngc-secret -n "$NAMESPACE" --ignore-not-found
oc create secret docker-registry ngc-secret \
  --docker-server=nvcr.io \
  --docker-username='$oauthtoken' \
  --docker-password="$REGISTRY_KEY" \
  -n "$NAMESPACE"

echo "Deploying fraud-training..."
helm upgrade --install fraud-training "$SCRIPT_DIR/fraud-training" \
  --namespace "$NAMESPACE"

echo ""
echo "Done. Monitor with: oc get pods -n $NAMESPACE -w"
