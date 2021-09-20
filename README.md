# infrastructure

Deploys a Kubernetes cluster and supporting resources

# How to deploy

1. Create a GCS bucket for use as a terraform backend.
    ```
    gsutil mb gs://iskprinter-terraform-state --location=US
    ```

1. Enable versioning on the bucket.
    ```
    gsutil versioning set on gs://iskprinter-terraform-state
    ```

1. After that, you should be able to deploy.
    ```
    terraform init
    terraform apply
    ```

1. Configure your local `~/.kube/config` so that you can use kubectl with the cluster.
    ```
    
    ```

# How to make the application live

1. List the nameservers of the managed zone
    ```
    gcloud dns managed-zones describe iskprinter-com
    ```
    

1. Set the nameservers on your DNS registrar to point to the GCP nameservers.

1. At this point, you should be able to go to https://iskprinter.com and/or https://dashboard-jx.iskprinter.com and get content.

# Local environment setup

1. Add the cluster to your kubeconfig.
    ```
    gcloud container clusters get-credentials \
        iskprinter \
        --project cameronhudson8 \
        --zone us-west1-a
    ```

1. Rename the kube context for convenience.
    ```
    kubectl config rename-context \
        gke_cameronhudson8_us-west1-a_iskprinter \
        iskprinter
    ```
