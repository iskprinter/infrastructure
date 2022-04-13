# infrastructure

Deploys a Kubernetes cluster and supporting resources

# How to deploy

1. Create a GCS bucket for use as a terraform backend.
    ```bash
    gsutil mb -l US gs://iskprinter-tf-state-prod
    ```

1. Enable versioning on the bucket.
    ```bash
    gsutil versioning set on gs://iskprinter-tf-state-prod
    ```

1. Initialize and deploy.
    ```bash
    terraform init
    terraform apply
    ```
