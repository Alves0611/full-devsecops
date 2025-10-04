#!/usr/bin/env bash
set -o errexit

# Trivy Kubernetes manifests scan script
# Usage: ./trivy-k8s-scan.sh [manifest-directory]

MANIFEST_DIR="${1:-kubernetes}"

echo "🔍 Scanning Kubernetes manifests in: $MANIFEST_DIR"

# Check if directory exists
if [[ ! -d "$MANIFEST_DIR" ]]; then
  echo "❌ Error: Directory $MANIFEST_DIR not found"
  exit 1
fi

# Create cache directory if it doesn't exist
mkdir -p "$HOME/.cache/trivy"

# Scan Kubernetes manifests for security issues
echo "📊 Scanning Kubernetes manifests for security issues..."
docker run --rm \
  -v "$HOME/.cache/trivy":/root/.cache/ \
  -v "$(pwd)":/workspace \
  aquasec/trivy:latest \
  -q k8s \
  --exit-code 1 \
  --severity HIGH,CRITICAL \
  /workspace/$MANIFEST_DIR

exit_code=$?
echo "🛑 Exit Code: $exit_code"

if [[ $exit_code -ne 0 ]]; then
  echo '❌ Kubernetes manifest scanning failed: High/Critical security issues found'
  echo '💡 Review the security recommendations above'
  exit 1
else
  echo '✅ Kubernetes manifest scanning passed: No high/critical issues'
fi
