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

# Find all YAML files in the manifest directory
yaml_files=$(find "$MANIFEST_DIR" -name "*.yml" -o -name "*.yaml" | head -10)

if [[ -z "$yaml_files" ]]; then
  echo "❌ No YAML files found in $MANIFEST_DIR"
  exit 1
fi

echo "📋 Found YAML files:"
echo "$yaml_files"

# Scan each YAML file
for file in $yaml_files; do
  echo "🔍 Scanning: $file"
  docker run --rm \
    -v "$HOME/.cache/trivy":/root/.cache/ \
    -v "$(pwd)":/workspace \
    aquasec/trivy:latest \
    -q k8s \
    --exit-code 1 \
    --severity HIGH,CRITICAL \
    "/workspace/$file"
  
  if [[ $? -ne 0 ]]; then
    echo "❌ Security issues found in $file"
    exit 1
  fi
done

exit_code=$?
echo "🛑 Exit Code: $exit_code"

if [[ $exit_code -ne 0 ]]; then
  echo '❌ Kubernetes manifest scanning failed: High/Critical security issues found'
  echo '💡 Review the security recommendations above'
  exit 1
else
  echo '✅ Kubernetes manifest scanning passed: No high/critical issues'
fi
