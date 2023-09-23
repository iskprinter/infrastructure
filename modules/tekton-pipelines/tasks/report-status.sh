#!/bin/sh

set -eux

apk update
apk add --no-cache \
    curl

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
curl \
    -X POST \
    -u "${GITHUB_USERNAME}:${GITHUB_TOKEN}" \
    "$GITHUB_STATUS_URL" \
    -H 'Accept: application/vnd.github.v3+json' \
    -d "{\"context\":\"tekton\",\"state\":\"${github_status}\"}"
set -x
