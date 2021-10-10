#!/bin/bash

set -eux

# Map Tekton statuses to GitHub statuses
function tekton_status_to_github_status {
    tekton_status=$1
    case "$tekton_status" in
        Completed)
            echo 'success'
            ;;
        Failed)
            echo 'failure'
            ;;
        None)
            echo 'pending'
            ;;
        Succeeded)
            echo 'success'
            ;;
        *)
            "Error: unable to interpret Tekton pipeline status '$tekton_status'." >2
            exit 1
    esac
}

github_status=$(tekton_status_to_github_status "$TEKTON_PIPELINE_STATUS")

set +x
token=$(
    kubectl get secret "$GITHUB_TOKEN_SECRET_NAME" \
        -n "$GITHUB_TOKEN_SECRET_NAMESPACE" \
        -o jsonpath='{.data.password}' \
    | base64 -d
)
curl \
    -X POST \
    -u "${GITHUB_USERNAME}:${token}" \
    "$GITHUB_STATUS_URL" \
    -d "{\"context\":\"tekton\",\"state\":\"${github_status}\"}"
set -x
