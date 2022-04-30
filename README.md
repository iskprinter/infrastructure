# infrastructure

Deploys a Kubernetes cluster and supporting resources

# How to deploy

## Create a GCP bucket for terraform state management

1. Create a GCS bucket for use as a terraform backend.
    ```bash
    gsutil mb -l US gs://iskprinter-tf-state-prod
    ```

1. Enable versioning on the bucket.
    ```bash
    gsutil versioning set on gs://iskprinter-tf-state-prod
    ```

## Create a local cluster and ingress

1. Install prerequisites, including minikube, `minikube`, and start it.
    ```
    brew install minikube
    brew install --cask docker
    brew install helm
    minikube start \
        --kubernetes-version=v1.21.9 \
        --cpus 4 \
        --memory 7951
    ```

1. Enable the ingress extension.
    ```
    minikube addons enable ingress
    ```

1. Set your `/etc/hosts` file as shown below.
   ```
   127.0.0.1 iskprinter-test.com
   127.0.0.1 www.iskprinter-test.com
   127.0.0.1 api.iskprinter-test.com
   ```

## Create a production cluster

1. Initialize and deploy the production cluster.
    ```bash
    terragrunt apply --terragrunt-working-dir ./config/prod/clusters
    ```

## Deploy remaining local and prod infrastructure

1. Initialize and deploy the remaining resources.
    ```bash
    terragrunt run-all apply --terragrunt-working-dir ./config
    ```

## Annotate the Kubernetes service account `tekton-pipelines-controller`

Annotating this service account will link it to a Google service account with permission to pull images.

1. Annotate the Kubernetes service account.
    ```
    kubectl annotate serviceaccount \
      tekton-pipelines-controller \
      'iam.gke.io/gcp-service-account'='tekton-pipelines-controller@cameronhudson8.iam.gserviceaccount.com' \
      --context gcp \
      -n tekton-pipelines
    ```

## Set secrets in Hashicorp Vault

1. Install the hashicorp vault cli
    ```
    brew tap hashicorp/tap
    brew install hashicorp/tap/vault
    ```

1. Set the vault address in a shell.
    ```
    export VAULT_ADDR='https://vault.iskprinter.com'
    ```

1. Initialize the vault. **Save the printed unseal key and root token.**
    ```
    vault operator init \
        -key-shares=1 \
        -key-threshold=1
    ```

1. Unseal the vault using the unseal key.
    ```
    vault operator unseal
    ```

1. Set the vault token in your shell.
    ```
    export VAULT_TOKEN='<vault-token>'
    ```

1. Create an entity for yourself.
    ```
    vault write identity/entity name=cameron-hudson
    ```

1. Enable the `userpass` login method.
    ```
    vault auth enable userpass
    ```

1. Create a user.
    ```
    vault write auth/userpass/users/cameron-hudson \
        password='<password>'
    ```

1. Link the user to the entity by adding an entity-alias.
    ```
    vault write identity/entity-alias name="cameron-hudson" \
        canonical_id=$(
            vault read identity/entity/name/cameron-hudson \
                -format=json \
            | jq -r '.data.id'
        ) \
        mount_accessor=$(
            vault auth list \
                -format=json \
            | jq -r '.["userpass/"].accessor'
        )
    ```

1. Create an `admin` policy.
    ```
    echo '
        # Read system health check
        path "sys/health"
        {
            capabilities = ["read", "sudo"]
        }

        # Create and manage ACL policies broadly across Vault

        # List existing policies
        path "sys/policies/acl"
        {
            capabilities = ["list"]
        }

        # Create and manage ACL policies
        path "sys/policies/acl/*"
        {
            capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }

        # Enable and manage authentication methods broadly across Vault

        # Manage auth methods broadly across Vault
        path "auth/*"
        {
            capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }

        # Create, update, and delete auth methods
        path "sys/auth/*"
        {
            capabilities = ["create", "update", "delete", "sudo"]
        }

        # List auth methods
        path "sys/auth"
        {
            capabilities = ["read"]
        }

        # Enable and manage the key/value secrets engine at `secret/` path

        # Manage key-value secrets
        path "secret"
        {
            capabilities = ["list"]
        }
        path "secret/*"
        {
            capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }

        # Manage secrets engines
        path "sys/mounts/*"
        {
            capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }

        # List existing secrets engines.
        path "sys/mounts"
        {
            capabilities = ["read"]
        }

        # Manage identities
        path "identity/*"
        {
            capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }
    ' > /tmp/admin-policy.hcl
    vault policy write admin /tmp/admin-policy.hcl
    ```

1. Create an `admins` group.
    ```
    vault write identity/group name="admins" \
        policies=admin \
        member_entity_ids=$(
            vault read identity/entity/name/cameron-hudson \
                -format=json \
            | jq -r '.data.id'
        )
    ```

1. Sign in with the new user.
    ```
    unset VAULT_TOKEN
    vault login -method=userpass username=cameron-hudson
    ```

1. Create an entity for external-secrets service.
    ```
    vault write identity/entity name=external-secrets
    ```

1. Enable the `approle` login method.
    ```
    vault auth enable approle
    ```

1. Create a `secret-reader` policy.
    ```
    echo '
        # Read secrets
        path "secret/*"
        {
            capabilities = ["read"]
        }
    ' > /tmp/secret-reader-policy.hcl
    vault policy write secret-reader /tmp/secret-reader-policy.hcl
    ```

1. Create an approle that belongs to the `secret-readers` group.
    ```
    vault write auth/approle/role/external-secrets \
        token_ttl=20m \
        token_max_ttl=30m \
        policies=secret-reader
    ```

1. Create a Secret and ClusterSecretStore resource. (You will have to deindent the following code block if you are viewing this file in a text editor.)
    ```
    for context in gcp minikube; do
    cat <<EOF | kubectl --context "$context" apply -f -
    apiVersion: v1
    kind: Secret
    metadata:
      namespace: external-secrets
      name: approle-secret
    stringData:
      secretId: $(
          vault write -f auth/approle/role/external-secrets/secret-id \
              -format=json \
          | jq -r '.data.secret_id'
      )
    EOF
    done
    
    for context in gcp minikube; do
    cat <<EOF | kubectl --context "$context" apply -f -
    apiVersion: external-secrets.io/v1beta1
    kind: ClusterSecretStore
    metadata:
      namespace: external-secrets
      name: hashicorp-vault-kv
    spec:
      provider:
        vault:
          server: https://vault.iskprinter.com
          path: secret
          version: v2
          auth:
            appRole:
              path: approle
              roleId: $(
                  vault read auth/approle/role/external-secrets/role-id \
                      -format=json \
                  | jq -r '.data.role_id'
              )
              secretRef:
                namespace: external-secrets
                name: approle-secret
                key: secretId
    EOF
    done
    ```

1. Enable the key-value secret store.
    ```
    vault secrets enable \
        -version=2 \
        -path=secret \
        kv
    ```

1. Add the following secrets. You can do this at https://vault.iskprinter.com if it's more comfortable.

    1. Add the Eve API credentials for the eve application. Do this for env=prod, env=test, and env=dev.
        ```
        vault kv put secret/<env>/api-client-credentials \
            id=<client-id> \
            secret=<client-secret>
        ```

    1. Add a personal access token so the CICD bot can update the Github build status.
        ```
        vault kv put secret/prod/cicd-bot-personal-access-token \
            username=IskprinterGitBot \
            password=<cicd-bot-personal-access-token>
        ```

    1. Add a Github webhook secret so that the Github status webhook is protected.
        ```
        vault kv put secret/prod/github-webhook-secret \
            secret=<github-webhook-secret>
        ```

1. Add an SSH private key and known_hosts content so that the CICD bot can pull code. (You will have to deindent the following code block if you are viewing this file in a text editor.)
    ```
    cat <<EOF | kubectl --context gcp apply -f -
    apiVersion: v1
    kind: Secret
    type: kubernetes.io/ssh-auth
    metadata:
      namespace: tekton-pipelines
      name: cicd-bot-ssh-key
      annotations:
        "tekton.dev/git-0": "github.com"
    data: 
      ssh-privatekey: $(cat ~/.ssh/IskprinterGitBot.id_rsa | base64)
      known_hosts: $(ssh-keyscan github.com | base64)
    EOF
    ```

1. Create a `docker-registry` secret to allow image pulling from GCP Artifact Registry.
    ```
    gcloud iam service-accounts keys create \
            /tmp/minikube-image-puller-key.json \
            --iam-account=minikube-image-puller@cameronhudson8.iam.gserviceaccount.com
    kubectl create secret docker-registry image-pull-secret \
        --context minikube \
        -n iskprinter \
        --docker-server='https://us-west1-docker.pkg.dev' \
        --docker-email='minikube-image-puller@cameronhudson8.iam.gserviceaccount.com' \
        --docker-username='_json_key' \
        --docker-password="$(cat /tmp/minikube-image-puller-key.json)"
    ```

1. Patch the default serviceaccount in the `iskprinter` namespace.
    ```
    kubectl patch serviceaccount default \
        --context minikube \
        -n iskprinter \
        -p '{"imagePullSecrets": [{"name": "image-pull-secret"}]}'
    ```
