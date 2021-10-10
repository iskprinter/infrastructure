# infrastructure

Deploys a Kubernetes cluster and supporting resources

# How to deploy

1. Create a GCS bucket for use as a terraform backend.
    ```bash
    gsutil mb gs://iskprinter-terraform-state --location=US
    ```

1. Enable versioning on the bucket.
    ```bash
    gsutil versioning set on gs://iskprinter-terraform-state
    ```

1. Export the pre-encoded SSH key and the pre-encoded `known_hosts` content that the service account will use to pull from GitHub.
    ```bash
    export TF_VAR_cicd_bot_ssh_private_key_base_64=$(cat "${HOME}/.ssh/IskprinterGitBot.id_rsa" | base64)
    export TF_VAR_github_known_hosts_base_64=$(cat "${HOME}/.ssh/known_hosts" | grep 'github' | base64)
    ```

1. Export the unencoded SSH key that the service account will use to push to Docker Hub.
    ```bash
    export TF_VAR_cicd_bot_container_registry_access_token='<access-token>'
    ```

1. Initialize and deploy.
    ```bash
    terraform init
    terraform apply
    ```

1. Configure your local `~/.kube/config` so that you can use kubectl with the cluster.
    ```bash
    
    ```

# How to make the application live

1. List the nameservers of the managed zone
    ```bash
    gcloud dns managed-zones describe iskprinter-com
    ```
    

1. Set the nameservers on your DNS registrar to point to the GCP nameservers.

1. At this point, you should be able to go to https://iskprinter.com and/or https://dashboard-jx.iskprinter.com and get content.

# Local environment setup

1. Add the cluster to your kubeconfig.
    ```bash
    gcloud container clusters get-credentials \
        iskprinter \
        --project cameronhudson8 \
        --zone us-west1-a
    ```

1. Rename the kube context for convenience.
    ```bash
    kubectl config rename-context \
        gke_cameronhudson8_us-west1-a_iskprinter \
        iskprinter
    ```
