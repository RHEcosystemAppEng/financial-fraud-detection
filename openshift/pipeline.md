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

2. Install preliminary resources

> ./openshift/deploy-init-pipeline.sh

```bash
fax@fercoli-mac financial-fraud-detection % oc get pvc fraud-data fraud-models -n "$NAMESPACE"
oc get configmap fraud-kfp-training-config -n "$NAMESPACE"
oc get secret ngc-secret -n "$NAMESPACE"
NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
fraud-data     Pending                                      gp3-csi        <unset>                 69s
fraud-models   Pending                                      gp3-csi        <unset>                 69s
NAME                        DATA   AGE
fraud-kfp-training-config   1      70s
NAME         TYPE                             DATA   AGE
ngc-secret   kubernetes.io/dockerconfigjson   1      70s
```