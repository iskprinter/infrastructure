# infrastructure
Terraform-deployed Kubernetes cluster, Hashicorp vault, and Jenkins X controller

# Setup

Create a GCS bucket for use as a terraform backend.
```
gsutil mb gs://iskprinter-terraform-state --location=US
```

Enabled versioning on the bucket.
```
gsutil versioning set on gs://iskprinter-terraform-state
```

Create a DNS managed zone.
```
gcloud dns managed-zones create \
    iskprinter-com \
    --dns-name=iskprinter.com \
    --description='Managed zone for iskprinter hosts'
```

Add some records.
```
gcloud dns record-sets create \
    iskprinter.com. \
    --zone=iskprinter-com \
    --type=A \
    --rrdatas=34.82.161.184
```

List the nameservers.
```
gcloud dns managed-zones describe iskprinter-com
```

Set the nameservers on your DNS registrar.

Export environment variables
```
export TF_VAR_jx_bot_username='my-bots-username'
export TF_VAR_jx_bot_token='my-bots-personal-access-token'
````

After that, you should be able to deploy.
```
terraform init
terraform apply
```

Add the cluster to your kubeconfig.
```
gcloud container clusters get-credentials \
    iskprinter \
    --project cameronhudson8 \
    --zone us-west1-a
```

Rename the kube context for convenience.
```
kubectl config rename-context \
    gke_cameronhudson8_us-west1-a_iskprinter \
    iskprinter
```

Find the external IP of the nginx ingress.
```
kubectl get \
    --context iskprinter \
    -n nginx \
    svc
```

Find the external IP of the nginx ingress.
```
kubectl get \
    --context iskprinter \
    -n nginx \
    svc
```

Create a DNS record for Jenkins-X.
```
gcloud dns record-sets create \
    jenkins-x.iskprinter.com. \
    --zone=jenkins-x-iskprinter-com-sub \
    --type=A \
    --rrdatas=35.197.93.149
```