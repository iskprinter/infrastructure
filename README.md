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

1. Export the pre-encoded SSH key and the pre-encoded `known_hosts` content that the service account will use to pull from GitHub.
    ```bash
    export TF_VAR_cicd_bot_ssh_private_key_base64=$(cat "${HOME}/.ssh/IskprinterGitBot.id_rsa" | base64)
    export TF_VAR_github_known_hosts_base64=$(cat "${HOME}/.ssh/known_hosts" | grep 'github' | base64)
    export TF_VAR_cicd_bot_personal_access_token_base64=$(echo -n '<token>' | base64) # Use for GitHub API access only
    export TF_VAR_api_client_secret_base64=$(echo -n '<secret>' | base64)
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

1. Since the `data` source for `PersistentVolume`s is not yet supported in Terraform, manually set the backup policy for each of the database volumes.
    ```
    # Get the PV names
    mongodb_pv=$(
        kubectl -n database get pvc data-volume-mongodb-0 -o json \
       | jq -r '.spec.volumeName'
    )
    neo4j_pv=$(
        kubectl -n database get pvc datadir-neo4j-neo4j-core-0 -o json \
        | jq -r '.spec.volumeName'
    )

    # Get the GCE Persistent Disk names
    mongodb_pd_name=$(
        kubectl -n database get pv "$mongodb_pv" -o json \
        | jq -r '.spec.gcePersistentDisk.pdName'
    )
    neo4j_pd_name=$(
        kubectl -n database get pv "$neo4j_pv" -o json \
        | jq -r '.spec.gcePersistentDisk.pdName'
    )

    # Attach the backup policy
    gcloud compute disks add-resource-policies "$mongodb_pd_name" \
        --project cameronhudson8 \
        --zone us-west1-a \
        --resource-policies 'backup'
    gcloud compute disks add-resource-policies "$neo4j_pd_name" \
        --project cameronhudson8 \
        --zone us-west1-a \
        --resource-policies 'backup'
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
