#!/bin/bash

# Environment variables (set by GitHub Actions)
deploymentName=${DEPLOYMENT_NAME:-devsecops}

echo "Monitoring rollout for deployment: $deploymentName"

# Allow pods to initialize
echo "Waiting 30 seconds for pods to initialize..."
sleep 30s

# Monitor rollout with a 2-minute timeout
echo "Checking rollout status..."
if ! kubectl -n devsecops rollout status deploy "${deploymentName}" --timeout=120s; then
    echo "Rollout FAILED; rolling back ${deploymentName}"
    kubectl -n devsecops rollout undo deploy "${deploymentName}"
    echo "Rollback completed"
    exit 1
else
    echo "Rollout SUCCESSFUL for ${deploymentName}"
    exit 0
fi
