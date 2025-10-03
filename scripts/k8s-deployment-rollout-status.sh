#!/bin/bash

# Environment variables (set by GitHub Actions)
deploymentName=${DEPLOYMENT_NAME:-devsecops}

echo "Monitoring rollout for deployment: $deploymentName"

# Allow pods to initialize
echo "Waiting 60 seconds for pods to initialize..."
sleep 60s

# Monitor rollout with a 5-second timeout
echo "Checking rollout status..."
if ! kubectl -n default rollout status deploy "${deploymentName}" --timeout=5s | grep -q "successfully rolled out"; then
    echo "Rollout FAILED; rolling back ${deploymentName}"
    kubectl -n default rollout undo deploy "${deploymentName}"
    echo "Rollback completed"
    exit 1
else
    echo "Rollout SUCCESSFUL for ${deploymentName}"
    exit 0
fi
