#!/usr/bin/env bash
set -euo pipefail

# Integration test script for Kubernetes deployment
# Tests HTTP endpoints and payload validation

# Environment variables (set by GitHub Actions)
deploymentEnv=${DEPLOYMENT_ENV:-devsecops}
containerName=${CONTAINER_NAME:-devsecops-container}
serviceName=${SERVICE_NAME:-devsecops}
applicationURL=${APPLICATION_URL:-http://localhost}
applicationURI=${APPLICATION_URI:-/increment/99}

echo "🧪 Starting Integration Tests"
echo "Deployment: $deploymentEnv"
echo "Service: $serviceName"
echo "Container: $containerName"

# Wait for pods to be ready
echo "⏳ Waiting 30 seconds for pods to be ready..."
sleep 30s

# Check if service exists
if ! kubectl -n devsecops get svc "${serviceName}" > /dev/null 2>&1; then
  echo "❌ Error: Service ${serviceName} not found in namespace devsecops"
  exit 1
fi

# Retrieve the NodePort for the service
echo "🔍 Getting NodePort for service ${serviceName}..."
PORT=$(kubectl -n devsecops get svc "${serviceName}" -o jsonpath='{.spec.ports[0].nodePort}')

if [[ -z "$PORT" ]]; then
  echo "❌ Error: Service ${serviceName} has no NodePort."
  exit 1
fi

echo "📡 Service NodePort: $PORT"

# Construct the full URL
URL="${applicationURL}:${PORT}${applicationURI}"
echo "🎯 Testing endpoint: $URL"

# Test 1: Check if service is responding (basic connectivity)
echo "🔗 Testing basic connectivity..."
if ! curl -s --connect-timeout 10 --max-time 30 "$URL" > /dev/null; then
  echo "❌ Connectivity Test Failed: Cannot reach $URL"
  exit 1
else
  echo "✅ Connectivity Test Passed"
fi

# Test 2: Validate payload increments 99 to 100
echo "📊 Testing payload validation..."
response=$(curl -s --connect-timeout 10 --max-time 30 "$URL")

if [[ "$response" != "100" ]]; then
  echo "❌ Payload Test Failed: expected 100, got '$response'"
  exit 1
else
  echo "✅ Payload Test Passed: got $response"
fi

# Test 3: Check HTTP status code 200
echo "📈 Testing HTTP status code..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "$URL")

if [[ "$http_code" != "200" ]]; then
  echo "❌ HTTP Status Test Failed: expected 200, got $http_code"
  exit 1
else
  echo "✅ HTTP Status Test Passed: got $http_code"
fi

# Test 4: Check response headers
echo "📋 Testing response headers..."
content_type=$(curl -s -I --connect-timeout 10 --max-time 30 "$URL" | grep -i "content-type" || echo "")

if [[ -n "$content_type" ]]; then
  echo "✅ Response Headers Test Passed: $content_type"
else
  echo "⚠️  Response Headers Test: No content-type header found"
fi

echo "🎉 All Integration Tests Passed!"
echo "✅ Service is healthy and responding correctly"
