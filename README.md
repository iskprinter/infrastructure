# infrastructure
Terraform-deployed Kubernetes cluster, Hashicorp vault, and Jenkins X controller

# Setup

1. Create a GCS bucket for use as a terraform backend.
    ```
    gsutil mb gs://iskprinter-terraform-state --location=US
    ```

1. Enabled versioning on the bucket.
    ```
    gsutil versioning set on gs://iskprinter-terraform-state
    ```

1. Export environment variables
    ```
    export TF_VAR_jx_bot_username='my-bots-username'
    export TF_VAR_jx_bot_token='my-bots-personal-access-token'
    ````

1. After that, you should be able to deploy.
    ```
    terraform init
    terraform apply
    ```

1. List the nameservers.
    ```
    gcloud dns managed-zones describe iskprinter-com
    ```

1. Set the nameservers on your DNS registrar.

1. At this point, you should be able to go to https://iskprinter.com or https://jenkins-x.iskprinter.com and get content.

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
