#!/usr/bin/env bash
set -euo pipefail

# Kubesec scan script for Kubernetes manifests
# Usage: ./kubesec-scan.sh [manifest-file]

MANIFEST_FILE="${1:-kubernetes/deployment.yml}"
TEMP_FILE="/tmp/kubesec-scan-$(date +%s).yml"

echo "🔍 Running Kubesec scan on: $MANIFEST_FILE"

# Check if file exists
if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "❌ Error: $MANIFEST_FILE not found"
  exit 1
fi

# Create temporary file with placeholders replaced for Kubesec scan
echo "🔄 Creating temporary manifest with real values for Kubesec scan..."
sed -e "s|_{_NAMESPACE_}_|default|g" \
    -e "s|_{_REPLICAS_}_|2|g" \
    -e "s|_{_K8S_IMAGE_}_|nginx:latest|g" \
    "$MANIFEST_FILE" > "$TEMP_FILE"

# Run Kubesec scan via HTTP API
echo "📡 Sending manifest to Kubesec API..."
scan_result=$(curl -sSX POST --data-binary @"$TEMP_FILE" https://v2.kubesec.io/scan)

# Clean up temporary file
rm -f "$TEMP_FILE"

# Extract score and message
scan_score=$(echo "$scan_result" | jq -r '.[0].score // 0')
scan_message=$(echo "$scan_result" | jq -r '.[0].message // "No message"')

echo "📊 Scan Score: $scan_score"
echo "📝 Message: $scan_message"

# Display detailed results
echo "📋 Detailed Results:"
echo "$scan_result" | jq '.[0]'

# Check if score meets threshold (5 points minimum)
if [[ "$scan_score" -ge 5 ]]; then
  echo "✅ Kubesec Scan Passed: $scan_message"
  exit 0
else
  echo "❌ Kubesec Scan Failed: $scan_message (score $scan_score < 5)"
  echo "💡 Consider implementing the security recommendations above"
  exit 1
fi
