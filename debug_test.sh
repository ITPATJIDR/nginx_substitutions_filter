#!/bin/bash

echo "=== Debug Test for Response Transformation ==="
echo ""

echo "1. Testing with username field:"
echo "Expected: username -> name (request), name -> username (response)"
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"username":"DEBUG_TEST"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s

echo ""
echo "2. Testing with email_address field:"
echo "Expected: email_address -> email (request), email -> email_address (response)"
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"email_address":"test@example.com"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s

echo ""
echo "3. Testing with name field (should not transform):"
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"name":"DIRECT_NAME"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s

echo ""
echo "Debug test completed!"
