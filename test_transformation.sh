#!/bin/bash

echo "=== Testing Nginx JavaScript Body Transformation ==="
echo ""

echo "1. Testing POST request with username -> name transformation"
echo "Sending: {\"username\":\"World\"}"
echo "Expected: Nginx transforms username->name before sending to Express, then transforms name->username in response"
echo ""

curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"username":"World"}' \
  -w "\n\nHTTP Status: %{http_code}\n" \
  -s

echo ""
echo "2. Testing GET request (no transformation needed)"
echo ""

curl http://localhost:8080/api \
  -w "\n\nHTTP Status: %{http_code}\n" \
  -s

echo ""
echo "3. Testing health check (no transformation needed)"
echo ""

curl http://localhost:8080/health \
  -w "\n\nHTTP Status: %{http_code}\n" \
  -s

echo ""
echo "=== Test Complete ==="
