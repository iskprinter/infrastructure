#!/bin/bash

set -eux

# Clean up derelict pods left in Shutdown status from node preemption
namespaces=($(
    kubectl get namespaces -o json \
    | jq -r '.items[].metadata.name'
))
for namespace in "${namespaces[@]}"; do
    echo "Deleting pods in shutdown state in namespace ${namespace}..."
    derelict_pods=($(
        kubectl -n "${namespace}" get pods -o json \
        | jq -r '
            .items[] 
            | select(.status.reason=="Shutdown")
            | .metadata.name
        '
    ))
    if [ ${#derelict_pods[@]} -gt 0 ]; then
        kubectl -n "${namespace}" delete pods "${derelict_pods[@]}"
    fi
done
