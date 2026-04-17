# Triton Server Notebook

1. Verify that the instance is working

```bash
oc get pods -w

oc get events --sort-by='.metadata.creationTimestamp'

# When started
oc logs fraud-triton-7b7df7bd54-lx2mn -f
```

2. Get the route

```bash
oc get routes
```

```bash
curl -s -o /dev/null -w "%{http_code}" https://fraud-triton-fraud-detection.apps.ai-dev04.kni.syseng.devcluster.openshift.com/v2/health/ready
```                                                   

3. Initialize a uv project (if not already done)

[openshift/notebooks]

```bash
# Initialize a uv project 
uv init --bare

# Add jupyter + your deps
uv add --dev ipykernel jupyter
uv add 'tritonclient[all]' requests numpy scikit-learn matplotlib pandas ipykernel
```

4. Install named kernel pointing to your .venv (if not already done)

```bash
uv sync

# Create a named kernel pointing to your .venv
uv run ipython kernel install --user --name=fraud-detection
```

5. Run the Jupyter Lab

```bash
uv sync

# Launch
uv run jupyter lab
```