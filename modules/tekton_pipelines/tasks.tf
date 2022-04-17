resource "kubectl_manifest" "task_report_status" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "report-status"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "github-status-url"
          description = "The GitHub status URL"
        },
        {
          name        = "github-token"
          description = "The GitHub personal access token of the CICD bot"
        },
        {
          name        = "github-username"
          description = "The GitHub username of the CICD bot"
        },
        {
          name        = "tekton-pipeline-status"
          description = "The Tekton pipeline status"
        }
      ]
      steps = [
        {
          image = "alpine:3.14"
          name  = "report-status"
          env = [
            {
              name  = "GITHUB_STATUS_URL"
              value = "$(params.github-status-url)"
            },
            {
              name  = "GITHUB_TOKEN"
              value = "$(params.github-token)"
            },
            {
              name  = "GITHUB_USERNAME"
              value = "$(params.github-username)"
            },
            {
              name  = "TEKTON_PIPELINE_STATUS"
              value = "$(params.tekton-pipeline-status)"
            }
          ]
          command = ["/bin/sh"]
          args = [
            "-c",
            file("${path.module}/report_status.sh")
          ]
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_get_secret" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "get-secret"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "secret-key"
          description = "The key of the secret to fetch"
        },
        {
          name        = "secret-name"
          description = "The name of the secret to fetch"
        },
        {
          name        = "secret-namespace"
          description = "The namespace of the secret to fetch"
        }
      ]
      results = [
        {
          name        = "secret-value"
          description = "The value of the secret"
        }
      ]
      steps = [
        {
          image = "alpine/k8s:${var.alpine_k8s_version}"
          name  = "get-secret"
          env = [
            {
              name  = "SECRET_KEY"
              value = "$(params.secret-key)"
            },
            {
              name  = "SECRET_NAME"
              value = "$(params.secret-name)"
            },
            {
              name  = "SECRET_NAMESPACE"
              value = "$(params.secret-namespace)"
            }
          ]
          script = <<-EOF
            #!/bin/bash
            set -euxo pipefail
            secret_value=$(
                kubectl get secret "$SECRET_NAME" \
                    -n "$SECRET_NAMESPACE" \
                    -o jsonpath="{.data.$${SECRET_KEY}}" \
                | base64 -d
            )
            set +x
            echo -n "$secret_value" > $(results.secret-value.path)
            set -x
            EOF
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_github_get_pr_sha" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      "namespace" = "tekton-pipelines"
      "name"      = "github-get-pr-sha"
    }
    spec = {
      params = [
        {
          name        = "github-token"
          description = "The GitHub personal access token of the CICD bot"
        },
        {
          name        = "github-username"
          description = "The GitHub username of the CICD bot"
        },
        {
          name        = "pr-number"
          description = "PR number to check out."
          type        = "string"
        },
        {
          name        = "repo-name"
          description = "The name of the repository for which to find the PR SHA."
          type        = "string"
        }
      ]
      results = [
        {
          name        = "revision"
          description = "The git commit hash"
        }
      ]
      steps = [
        {
          name  = "github-get-pr-sha"
          image = "alpine:3.14"
          env = [
            {
              name  = "GITHUB_USERNAME"
              value = "$(params.github-username)"
            },
            {
              name  = "GITHUB_TOKEN"
              value = "$(params.github-token)"
            },
            {
              name  = "PR_NUMBER"
              value = "$(params.pr-number)"
            },
            {
              name  = "REPO_NAME"
              value = "$(params.repo-name)"
            }
          ]
          script = <<-EOF
            #!/bin/sh
            set -eux
            TIMEOUT_SECONDS=30
            apk update
            apk add --no-cache \
                curl \
                jq
            pr_response=''
            mergeable=''
            i=0
            while [ $i -lt $TIMEOUT_SECONDS ]; do
                echo '---'
                echo "$i"
                pr_response=$(
                    curl \
                        -X GET \
                        -u "$${GITHUB_USERNAME}:$${GITHUB_TOKEN}" \
                        -H 'Accept: application/vnd.github.v3+json' \
                        "https://api.github.com/repos/iskprinter/$${REPO_NAME}/pulls/$${PR_NUMBER}"
                )
                mergeable=$(echo "$pr_response" | jq -r '.mergeable')
                if [ "$mergeable" = 'true' ]; then
                    break;
                fi
                sleep 1
                i=$(expr $i + 1)
            done
            if [ $i -gte 30 ]; then
                echo "Unable to get merge commit from GitHub within $${TIMEOUT_SECONDS}. 'mergeable' status was $${mergeable}." >2
            fi
            merge_commit_sha=$(echo "$pr_response" | jq -r '.merge_commit_sha')
            echo -n "$merge_commit_sha" | tee $(results.revision.path)
            EOF
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_github_checkout_commit" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      "namespace" = "tekton-pipelines"
      "name"      = "github-checkout-commit"
    }
    spec = {
      params = [
        {
          name        = "repo-url"
          description = "Repository URL to clone from."
          type        = "string"
        },
        {
          name        = "revision"
          description = "Revision to checkout. (branch, tag, sha, ref, etc...)"
          type        = "string"
        }
      ]
      "workspaces" = [
        {
          name      = "default"
          mountPath = "/workspace"
        }
      ]
      steps = [
        {
          name       = "github-checkout"
          image      = "alpine/git:v2.32.0"
          workingDir = "$(workspaces.default.path)"
          env = [
            {
              name  = "REPO_URL"
              value = "$(params.repo-url)"
            },
            {
              name  = "REVISION"
              value = "$(params.revision)"
            }
          ]
          script = <<-EOF
            #!/bin/sh
            set -eux
            git init
            git remote add origin "$${REPO_URL}"
            git fetch origin "$${REVISION}" --depth=1
            git reset --hard FETCH_HEAD
            EOF
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_build_and_push_image" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "build-and-push-image"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          description = "The name of the image to build"
          name        = "image-name"
        },
        {
          description = "The tag of the image to build"
          name        = "image-tag"
        }
      ]
      steps = [
        {
          name = "build-and-push-image"
          env = [
            {
              name  = "IMAGE_NAME"
              value = "$(params.image-name)"
            },
            {
              name  = "IMAGE_TAG"
              value = "$(params.image-tag)"
            }
          ]
          image      = "gcr.io/kaniko-project/executor:v${var.kaniko_version}"
          workingDir = "$(workspaces.default.path)"
          args = [
            "--destination=${var.region}-docker.pkg.dev/${var.project}/iskprinter/$(IMAGE_NAME):$(IMAGE_TAG)",
            "--cache=true"
          ]
          resources = {
            limits = {
              memory = "2Gi"
            }
          }
        }
      ]
      workspaces = [
        {
          mountPath = "/workspace"
          name      = "default"
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_terragrunt_plan" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "terragrunt-plan"
      namespace = "tekton-pipelines"
    }
    spec = {
      steps = [
        {
          name       = "terragrunt-plan"
          image      = "alpine/terragrunt:${var.terraform_version}"
          workingDir = "$(workspaces.default.path)"
          script     = <<-EOF
            #!/bin/sh
            set -eux
            terragrunt plan --terragrunt-working-dir ./config/prod
            EOF
        }
      ]
      workspaces = [
        {
          mountPath = "/workspace"
          name      = "default"
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_terragrunt_apply" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "terragrunt-apply"
      namespace = "tekton-pipelines"
    }
    spec = {
      steps = [
        {
          name = "terragrunt-apply"
          image      = "alpine/terragrunt:${var.terraform_version}"
          workingDir = "$(workspaces.default.path)"
          script     = <<-EOF
            #!/bin/sh
            set -eux
            if ! terragrunt apply -auto-approve -backup=./backup.tfstate --terragrunt-non-interactive --terragrunt-working-dir ./config/prod; then
              echo 'Reverting to prior state' >2
              terragrunt apply -auto-approve -state=./backup.tfstate --terragrunt-non-interactive --terragrunt-working-dir ./config/prod
              exit 1
            fi
            EOF
        }
      ]
      workspaces = [
        {
          mountPath = "/workspace"
          name      = "default"
        }
      ]
    }
  })
}
