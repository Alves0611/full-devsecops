#!/bin/bash

# Environment variables (set by GitHub Actions)
deploymentName=${DEPLOYMENT_NAME:-devsecops}
containerName=${CONTAINER_NAME:-devsecops-container}
imageName=${IMAGE_NAME:-gabriel/devsecops:latest}

echo "Deployment: $deploymentName"
echo "Container: $containerName"
echo "Image: $imageName"

# Replace placeholder with real image name in kubernetes manifests
sed -i "s|_{_K8S_IMAGE_}_|${imageName}|g" kubernetes/deployment.yml

# Check if deployment exists
if ! kubectl -n devsecops get deployment "${deploymentName}" > /dev/null 2>&1; then
    echo "Creating deployment ${deploymentName}"
    kubectl -n devsecops apply -f kubernetes/
else
    echo "Updating deployment ${deploymentName} with new configuration..."
    kubectl -n devsecops apply -f kubernetes/
    echo "Forcing rollout restart to ensure new configuration is used..."
    kubectl -n devsecops rollout restart deploy "${deploymentName}"
fi
