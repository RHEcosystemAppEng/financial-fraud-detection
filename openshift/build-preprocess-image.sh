#!/bin/bash
set -euo pipefail

if [[ -z "${NAMESPACE:-}" ]]; then
  NAMESPACE=$(oc project -q 2>/dev/null) || true
fi
if [[ -z "${NAMESPACE:-}" ]]; then
  echo "ERROR: Set NAMESPACE (e.g. export NAMESPACE=fraud-detection) or: oc project <namespace>"
  exit 1
fi

if [[ -z "${TABFORMER_DATA:-}" ]]; then
  echo "ERROR: Set TABFORMER_DATA to the path of card_transaction.v1.csv."
  echo "       e.g. export TABFORMER_DATA=/home/fax/data/transactions/card_transaction.v1.csv"
  exit 1
fi
if [[ ! -f "$TABFORMER_DATA" ]]; then
  echo "ERROR: File not found: $TABFORMER_DATA"
  exit 1
fi

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)

echo "Building Financial Fraud Detection images on OpenShift"
echo "Namespace: $NAMESPACE"
echo "Repo: $REPO_ROOT"
echo "TabFormer CSV: $TABFORMER_DATA"
echo ""

if ! oc whoami &>/dev/null; then
  echo "ERROR: Not logged in to OpenShift. Run 'oc login' first."
  exit 1
fi

oc project "$NAMESPACE" 2>/dev/null || oc new-project "$NAMESPACE"

echo "Building preprocess image..."
if ! oc get bc fraud-preprocess -n "$NAMESPACE" &>/dev/null; then
  oc new-build --name=fraud-preprocess --binary --strategy=docker -n "$NAMESPACE" || {
    echo "ERROR: Failed to create BuildConfig fraud-preprocess"
    exit 1
  }
fi

staging=$(mktemp -d)

mkdir -p "$staging/src" "$staging/raw"
cp "$REPO_ROOT/src/preprocess_TabFormer_lp.py" "$staging/src/"
cp "$TABFORMER_DATA" "$staging/raw/card_transaction.v1.csv"
cp "$REPO_ROOT/openshift/docker/preprocess.Dockerfile" "$staging/Dockerfile"

build=$(oc start-build fraud-preprocess -n "$NAMESPACE" --from-dir="$staging" -o name) || {
  echo "ERROR: start-build failed for fraud-preprocess"
  rm -rf "$staging"
  exit 1
}
rm -rf "$staging"

echo "Started $build — streaming logs..."
oc logs -f "$build" -n "$NAMESPACE" || {
  echo "ERROR: Build failed: fraud-preprocess"
  exit 1
}

echo ""
echo "Build complete."
echo "View images: oc get imagestream -n $NAMESPACE"
