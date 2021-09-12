# infrastructure
Terraform-deployed Kubernetes cluster, Hashicorp vault, and Jenkins X controller

# About

This repo is based on [jx3-gitops-repositories/jx3-terraform-gke](https://github.com/jx3-gitops-repositories/jx3-terraform-gke) (main branch).

# How to deploy

1. Create a GCS bucket for use as a terraform backend.
    ```
    gsutil mb gs://iskprinter-terraform-state --location=US
    ```

1. Enable versioning on the bucket.
    ```
    gsutil versioning set on gs://iskprinter-terraform-state
    ```

1. Export the GitHub personal access token of the bot that will mediate between Jenkins X and the cluster repository.
    ```
    export TF_VAR_jx_bot_token='my-bots-personal-access-token'
    ````

1. After that, you should be able to deploy.
    ```
    terraform init
    terraform apply
    ```

1. 

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
