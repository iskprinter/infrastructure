# infrastructure

Deploys a Kubernetes cluster and supporting resources

# How to deploy

## Create a GCP bucket for terraform state management

1. Create a GCS bucket for use as a terraform backend.
    ```bash
    gsutil mb -l US gs://iskprinter-prod-tf-state
    ```

1. Enable versioning on the bucket.
    ```bash
    gsutil versioning set on gs://iskprinter-prod-tf-state
    ```

## Create a Kubernetes cluster

### Locally, with Minikube

1. Install prerequisites, including `minikube`, and start it.
    ```
    brew install minikube
    brew install --cask docker
    brew install helm
    minikube start \
        --kubernetes-version=v1.26.1 \
        --cpus 4 \
        --memory 7951
    ```

1. Enable the ingress extension.
    ```
    minikube addons enable ingress
    minikube tunnel
    ```

1. Set your `/etc/hosts` file as shown below.
   ```
   127.0.0.1 iskprinter-dev.com
   127.0.0.1 www.iskprinter-dev.com
   127.0.0.1 api.iskprinter-dev.com
   ```

### In the Cloud (Google Cloud Platform, GCP)

1. Initialize and deploy the production cluster.
    ```bash
    terragrunt apply --terragrunt-working-dir ./config/prod/cluster
    ```

## Deploy the remaining modules into the cluster

### Locally, with Minikube

1. Initialize and deploy the remaining modules, in the following order:
    1. `./config/dev/cert-manager`
    1. `./config/dev/mongodb-operator`

### In the Cloud (Google Cloud Platform, GCP)

1. Initialize and deploy the remaining modules, in the following order:
    1. `./config/prod/backups`
    1. `./config/prod/cert-manager-operator`
    1. `./config/prod/cert-manager-cluster-issuer`
    1. `./config/prod/container-registries`
    1. `./config/prod/external-dns`
    1. `./config/prod/external-secrets-operator`
    1. `./config/prod/hashicorp-vault`
    1. `./config/prod/ingress-nginx`
    1. `./config/prod/mongodb-operator`
    1. `./config/prod/tekton-pipeline-crds`
    1. `./config/prod/tekton-dashboard-crds`
    1. `./config/prod/tekton-triggers-crds`
    1. `./config/prod/tekton-triggers-interceptors-crds`
    1. `./config/prod/tekton-pipelines`
    1. `./config/prod/user-accounts`

## Annotate the Kubernetes service account `tekton-pipelines-controller` (Cloud only)

Annotating this service account will link it to a Google service account with permission to pull images.

1. Annotate the Kubernetes service account.
    ```
    kubectl annotate serviceaccount \
      tekton-pipelines-controller \
      'iam.gke.io/gcp-service-account'='tekton-pipelines-controller@cameronhudson8.iam.gserviceaccount.com' \
      --context gcp \
      -n tekton-pipelines
    ```

## Set up Hashicorp Vault (Cloud only)

1. Install the hashicorp vault cli
    ```
    brew tap hashicorp/tap
    brew install hashicorp/tap/vault
    ```

1. Port-forward the hashicorp vault to your local machine.
    ```
    kubectl --context gcp -n hashicorp-vault port-forward svc/hashicorp-vault 8200:8200
    ```

1. Set the vault address in a shell.
    ```
    export VAULT_ADDR='http://localhost:8200'
    ```

1. Initialize the vault. **Save the printed recovery keys initial root token.**
    ```
    vault operator init
    ```

1. Set the vault token in your shell.
    ```
    export VAULT_TOKEN='<initial-root-token>'
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
    ' >/tmp/admin-policy.hcl
    vault policy write admin /tmp/admin-policy.hcl
    rm /tmp/admin-policy.hcl
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
    ' >/tmp/secret-reader-policy.hcl
    vault policy write secret-reader /tmp/secret-reader-policy.hcl
    rm /tmp/secret-reader-policy.hcl
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
    cat <<EOF | kubectl --context gcp apply -f -
    apiVersion: v1
    kind: Secret
    metadata:
      namespace: external-secrets-operator
      name: approle-secret
    stringData:
      secretId: $(
          vault write -f auth/approle/role/external-secrets/secret-id \
              -format=json \
          | jq -r '.data.secret_id'
      )
    EOF
    
    cat <<EOF | kubectl --context gcp apply -f -
    apiVersion: external-secrets.io/v1beta1
    kind: ClusterSecretStore
    metadata:
      namespace: external-secrets-operator
      name: hashicorp-vault-kv
    spec:
      provider:
        vault:
          server: http://hashicorp-vault-internal.hashicorp-vault.svc.cluster.local:8200
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
                namespace: external-secrets-operator
                name: approle-secret
                key: secretId
    EOF
    ```

1. Enable the key-value secret store.
    ```
    vault secrets enable \
        -version=2 \
        -path=secret \
        kv
    ```

## Create Secrets

1. **Local** Create the `iskprinter` namespace.
    ```
    kubectl --context minikube create namespace iskprinter
    ```

1. Create the Eve API credentials. (From https://developers.eveonline.com/applications.)

    1. **Local** (You will have to deindent the following code block if you are viewing this file in a text editor.)
        ```
        cat <<EOF | kubectl --context minikube apply -f -
        apiVersion: v1
        kind: Secret
        metadata:
          namespace: iskprinter
          name: api-client-credentials
        stringData:
          id: <api-client-id>
          secret: <api-client-secret>
        EOF
        ```

    1. **Prod**
        ```
        vault kv put secret/api-client-credentials \
            id=<client-id> \
            secret=<client-secret>
        ```

1. Create the JWT private and public keys. If you need to create these from scratch, use `openssl`.
    ```
    openssl ecparam \
        -name secp521r1 \
        -genkey \
        -noout \
        -out <path-to-private-key>
    openssl ec \
        -in <path-to-private-key> \
        -pubout \
        -out <path-to-public-key>
    ```

    1. **Local** (You will have to deindent the following code block if you are viewing this file in a text editor.)
        ```
        cat <<EOF | kubectl --context minikube apply -f -
        apiVersion: v1
        kind: Secret
        metadata:
          namespace: iskprinter
          name: iskprinter-jwt-keys
        stringData:
          private-key: $(cat <path-to-private-key> | base64)
          public-key: $(cat <path-to-public-key> | base64)
        EOF
        ```

    1. **Prod**
        ```
        vault kv put secret/iskprinter-jwt-keys \
            public-key=@<path-to-public-key> \
            private-key=@<path-to-private-key>
        ```

1. **Prod** Add a personal access token so the CICD bot can update the Github build status.
    ```
    vault kv put secret/cicd-bot-personal-access-token \
        username=IskprinterGitBot \
        password=<cicd-bot-personal-access-token>
    ```

1. **Prod** Add a Github webhook secret so that the Github status webhook is protected.
    ```
    vault kv put secret/github-webhook-secret \
        secret=<github-webhook-secret>
    ```

1. **Prod** Add an SSH private key and a `known_hosts` file for Github so that the CICD bot can pull code.
    ```
    vault kv put secret/cicd-bot-ssh-key \
        ssh-privatekey="$(cat ~/.ssh/IskprinterGitBot.id_rsa)" \
        known_hosts="$(ssh-keyscan github.com)"
    ```
