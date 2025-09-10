#!/bin/bash

echo "Testing Nginx with Lua request body modification..."

# Test POST endpoint with username field
echo "1. Testing POST with username field:"
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"username":"World"}' \
  -w "\n\n"

# Test POST endpoint with name field (should work as-is)
echo "2. Testing POST with name field:"
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"name":"World"}' \
  -w "\n\n"

# Test GET endpoint
echo "3. Testing GET endpoint:"
curl http://localhost:8080/api \
  -w "\n\n"

# Test health check
echo "4. Testing health check:"
curl http://localhost:8080/health \
  -w "\n\n"