resource "kubernetes_manifest" "task_github_get_pr_sha" {
  manifest = {
    apiVersion = "tekton.dev/v1"
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
          type        = "string"
        },
        {
          name        = "github-username"
          description = "The GitHub username of the CICD bot"
          type        = "string"
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
          type        = "string"
        }
      ]
      steps = [
        {
          computeResources = {}
          name             = "github-get-pr-sha"
          image            = "alpine:3.14"
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
  }
}
