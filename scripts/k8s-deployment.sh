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
    echo "Updating image for ${deploymentName} to ${imageName}"
    kubectl -n devsecops set image deploy "${deploymentName}" "${containerName}"="${imageName}" --record=true
fi
