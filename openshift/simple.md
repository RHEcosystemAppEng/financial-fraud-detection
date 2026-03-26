0. Environment variables and login

> oc login --token=...

```bash
export NAMESPACE=fraud-detection
export NGC_API_KEY=<your-ngc-key>
```

1. Delete / create a project

> oc delete project $NAMESPACE
> oc new-project $NAMESPACE
> oc adm policy add-scc-to-user anyuid -z default -n $NAMESPACE

2. Run preprocessing

> ./openshift/deploy-preprocess.sh

To monitor:

> oc get pods -w -n $NAMESPACE

> oc get events --sort-by='.metadata.creationTimestamp'

> oc describe pods fraud-preprocess-xxxxx

> oc logs fraud-preprocess-xxxxx

3. Run training

> ./openshift/deploy-training.sh

4. Run inference server

> ./openshift/deploy-inference.sh 

# Update / Re-Run

To rerun if needed:

> helm uninstall fraud-preprocess -n $NAMESPACE

Check if the pvc is gone:
> oc get pvc -n $NAMESPACE

> ./openshift/deploy-preprocess.sh

# Undeploy

> helm uninstall fraud-inference -n $NAMESPACE

# Verifications

Verify that the PVC has the right file

## Data Preprocessing

``` bash
oc run verify-data --rm -it --restart=Never \
  --image=busybox \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "verify-data",
        "image": "busybox",
        "command": ["find", "/data/TabFormer", "-type", "f", "-exec", "ls", "-lh", "{}", ";"],
        "volumeMounts": [{"name": "data", "mountPath": "/data"}]
      }],
      "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "fraud-data"}}]
    }
  }'
``` 

Output should look like:

```bash
-rw-r--r--    1 root     root        4.2M Apr  9 12:58 /data/TabFormer/xgb/test.csv
-rw-r--r--    1 root     root       45.5M Apr  9 12:58 /data/TabFormer/xgb/training.csv
-rw-r--r--    1 root     root        3.3M Apr  9 12:58 /data/TabFormer/xgb/validation.csv
-rw-r--r--    1 root     root        2.0M Apr  9 12:58 /data/TabFormer/gnn/nodes/merchant.csv
-rw-r--r--    1 root     root      123.8K Apr  9 12:58 /data/TabFormer/gnn/nodes/user.csv
-rw-r--r--    1 root     root      317.7K Apr  9 12:58 /data/TabFormer/gnn/test_gnn/nodes/merchant.csv
-rw-r--r--    1 root     root      121.8K Apr  9 12:58 /data/TabFormer/gnn/test_gnn/nodes/user.csv
-rw-r--r--    1 root     root          48 Apr  9 12:58 /data/TabFormer/gnn/test_gnn/nodes/merchant_feature_mask.csv
-rw-r--r--    1 root     root          26 Apr  9 12:58 /data/TabFormer/gnn/test_gnn/nodes/user_feature_mask.csv
-rw-r--r--    1 root     root       50.4K Apr  9 12:58 /data/TabFormer/gnn/test_gnn/edges/user_to_merchant_label.csv
-rw-r--r--    1 root     root      214.0K Apr  9 12:58 /data/TabFormer/gnn/test_gnn/edges/user_to_merchant.csv
-rw-r--r--    1 root     root        2.3M Apr  9 12:58 /data/TabFormer/gnn/test_gnn/edges/user_to_merchant_attr.csv
-rw-r--r--    1 root     root          76 Apr  9 12:58 /data/TabFormer/gnn/test_gnn/edges/user_to_merchant_feature_mask.csv
-rw-r--r--    1 root     root      588.9K Apr  9 12:58 /data/TabFormer/gnn/edges/user_to_merchant_label.csv
-rw-r--r--    1 root     root        2.5M Apr  9 12:58 /data/TabFormer/gnn/edges/user_to_merchant.csv
-rw-r--r--    1 root     root       27.0M Apr  9 12:58 /data/TabFormer/gnn/edges/user_to_merchant_attr.csv
```

## Training

```bash
oc run verify-models --rm -it --restart=Never \
  --image=busybox \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "verify-models",
        "image": "busybox",
        "command": ["find", "/models", "-type", "f", "-exec", "ls", "-lh", "{}", ";"],
        "volumeMounts": [{"name": "models", "mountPath": "/models"}]
      }],
      "volumes": [{"name": "models", "persistentVolumeClaim": {"claimName": "fraud-models"}}]
    }
  }'
```

The output should look like:

```bash
-rw-r--r--    1 root     root        1.8K Apr  9 13:28 /models/python_backend_model_repository/prediction_and_shapley/config.pbtxt
-rw-r--r--    1 root     root        1.6K Apr  9 13:28 /models/python_backend_model_repository/prediction_and_shapley/1/json_loader_writer.py
-rw-r--r--    1 root     root         461 Apr  9 13:28 /models/python_backend_model_repository/prediction_and_shapley/1/meta.json
-rw-r--r--    1 root     root       63.9K Apr  9 13:28 /models/python_backend_model_repository/prediction_and_shapley/1/state_dict_gnn_model.pth
-rw-r--r--    1 root     root       23.4K Apr  9 13:28 /models/python_backend_model_repository/prediction_and_shapley/1/model.py
-rw-r--r--    1 root     root        3.0M Apr  9 13:28 /models/python_backend_model_repository/prediction_and_shapley/1/embedding_based_xgboost.json
```

# Optional Parts

## Build the preprocessing image (not-mandatory)

Download dataset:

* From the page: https://ibm.ent.box.com/v/tabformer-data/file/770766751708

Extract the CSV file and export the variable:

```bash
export TABFORMER_DATA=/home/fax/data/transactions/card_transaction.v1.csv
```

> ./openshift/build-preprocess-image.sh

## Build the inference image (not-mandatory)

```bash
# If pushing to quay.io:
podman build -t quay.io/fercoli/triton-fraud-detection:1.0.2 ./triton
podman push quay.io/fercoli/triton-fraud-detection:1.0.2
```