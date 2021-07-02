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

Set the nameservers on your DNS registrar

After that, you should be able to deploy.
```
terraform init
terraform apply
```
