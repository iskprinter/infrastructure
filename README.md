# infrastructure
Terraform-deployed Kubernetes cluster, Hashicorp vault, and Jenkins X controller

# Create the backend bucket
I've created it with this command
```
gsutil mb gs://iskprinter-terraform-state --location=US
```

Then, I enabled versioning
```
gsutil versioning set on gs://iskprinter-terraform-state
```

After that, you should be able to run `terraform init`.
