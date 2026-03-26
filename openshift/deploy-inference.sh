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

echo "Deploying fraud-inference..."
helm upgrade --install fraud-inference "$SCRIPT_DIR/fraud-inference" \
  --namespace "$NAMESPACE"

echo ""
echo "Done."
echo "Get Triton endpoint: oc get route fraud-triton -n $NAMESPACE -o jsonpath='{.spec.host}'"
