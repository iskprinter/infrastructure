#!/bin/bash

set -eux

# Clean up completed pipeline resources (pods and pvcs)
echo "Deleting tekton pods and pvcs in namespace tekton-pipelines..."
completed_tekton_pipelines_json=($(
    kubectl -n tekton-pipelines get pipelineruns -o json \
    | jq -cM '
        .items 
        | map(
            select(
                [.status.conditions[0].reason] 
                | inside(["Started", "Running"]) 
                | not
            ) | .metadata.name
        )
    '
))
completed_tekton_pods=($(
    kubectl -n tekton-pipelines get pods -o json \
        | jq -r --argjson completed_tekton_pipelines "$completed_tekton_pipelines_json" '
            .items[] 
            | select(
                [.metadata.labels["tekton.dev/pipelineRun"]] 
                | inside($completed_tekton_pipelines)
            )
            | .metadata.name
        '
))
completed_tekton_pvcs=($(
    kubectl -n tekton-pipelines get pvc -o json \
    | jq -r --argjson completed_tekton_pipelines "$completed_tekton_pipelines_json" '
        .items[]
        | select(
            [.metadata.ownerReferences[0].name] 
            | inside($completed_tekton_pipelines)
        ) 
        | .metadata.name
    '
))
if [ ${#completed_tekton_pvcs[@]} -gt 0 ]; then
    kubectl -n tekton-pipelines delete pvc "${completed_tekton_pvcs[@]}"
fi
if [ ${#completed_tekton_pods[@]} -gt 0 ]; then
    kubectl -n tekton-pipelines delete pods "${completed_tekton_pods[@]}"
fi
