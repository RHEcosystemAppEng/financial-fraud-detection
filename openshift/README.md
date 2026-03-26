# OpenShift Deployment

This directory contains scripts and three Helm charts for deploying the financial fraud detection blueprint on OpenShift.

## Charts

| Chart | What it deploys | Input | Output |
|---|---|---|---|
| `fraud-preprocess` | `fraud-data` PVC + Preprocess Job | CSV baked into the image | Preprocessed graph data on `fraud-data` |
| `fraud-training` | Training Job + `fraud-models` PVC | `fraud-data` PVC | Trained model artifacts on `fraud-models` |
| `fraud-inference` | Triton Deployment + Service + Route | `fraud-models` PVC | Inference service live and ready |

## Scripts

- `build-preprocess-image.sh`: builds the `fraud-preprocess` OpenShift image.
- `build-triton-local-push.sh`: builds the Triton image locally and pushes it to the OpenShift internal registry.
- `deploy-preprocess.sh`: deploys the `fraud-preprocess` chart.
- `deploy-training.sh`: creates the NGC pull secret, detects GPU tolerations, deploys the `fraud-training` chart.
- `deploy-inference.sh`: detects GPU tolerations, deploys the `fraud-inference` chart.

## Workflow

```bash
export NAMESPACE=fraud-detection
export NGC_API_KEY=<your-ngc-key>
```

### 1. Build images

Download `card_transaction.v1.csv` from [IBM Box](https://ibm.ent.box.com/v/tabformer-data/file/770766751708), then build the preprocess image (the CSV is baked into the image):

```bash
export TABFORMER_DATA=/path/to/card_transaction.v1.csv
./openshift/build-preprocess-image.sh
./openshift/build-triton-local-push.sh
```

### 2. Preprocess

```bash
./openshift/deploy-preprocess.sh
oc wait --for=condition=complete job/fraud-preprocess -n $NAMESPACE --timeout=60m
```

### 3. Training

```bash
./openshift/deploy-training.sh
oc wait --for=condition=complete job/fraud-training -n $NAMESPACE --timeout=120m
```

### 4. Inference

```bash
./openshift/deploy-inference.sh

# Get the Triton endpoint
oc get route fraud-triton -n $NAMESPACE -o jsonpath='{.spec.host}'
```

Triton serves the `prediction_and_shapley` model via HTTP (port 8000) and gRPC (port 8001).
