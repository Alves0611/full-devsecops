#!/bin/bash

# Environment variables (set by GitHub Actions)
deploymentName=${DEPLOYMENT_NAME:-devsecops}

echo "Monitoring rollout for deployment: $deploymentName"

# Allow pods to initialize
echo "Waiting 30 seconds for pods to initialize..."
sleep 30s

# Check if deployment exists and is ready
echo "Checking deployment status..."
kubectl -n devsecops get deployment "${deploymentName}" -o wide

# Monitor rollout with a 3-minute timeout
echo "Checking rollout status..."
if ! kubectl -n devsecops rollout status deploy "${deploymentName}" --timeout=180s; then
    echo "Rollout FAILED; checking pod status..."
    kubectl -n devsecops get pods -l app=devsecops
    echo "Rolling back ${deploymentName}..."
    kubectl -n devsecops rollout undo deploy "${deploymentName}"
    echo "Rollback completed"
    exit 1
else
    echo "Rollout SUCCESSFUL for ${deploymentName}"
    kubectl -n devsecops get pods -l app=devsecops
    exit 0
fi
