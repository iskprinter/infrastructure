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

1. Install `minikube`, start it, and enable the ingress extension
    ```
    brew install minikube
    brew install --cask docker
    brew install helm
    minikube start \
        --kubernetes-version=v1.21.9 \
        --cpus 4 \
        --memory 7951
    minikube addons enable ingress
    ```

1. Initialize and deploy the production cluster.
    ```bash
    terragrunt apply --terragrunt-working-dir ./config/prod/clusters
    ```

1. Initialize and deploy the remaining resources.
    ```bash
    terragrunt run-all apply --terragrunt-working-dir ./config
    ```
