#!/bin/bash

echo "Testing Nginx + Express API with Request/Response Transformation"
echo "=============================================================="

# Test 1: POST request with username field
echo -e "\n1. Testing POST request with username field:"
echo "Sending: {\"username\":\"PAT\"}"
echo "Expected transformation: username -> name (request), name -> username (response)"

curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"username":"PAT"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s

echo -e "\n" 

# Test 2: POST request with name field (should still work)
echo "2. Testing POST request with name field:"
echo "Sending: {\"name\":\"JOHN\"}"
echo "Expected: No transformation needed"

curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"email_address":"JOHN"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s

echo -e "\n"

# Test 3: GET request
echo "3. Testing GET request:"
curl -X GET http://localhost:8080/api \
  -w "\nHTTP Status: %{http_code}\n" \
  -s

echo -e "\n"

# Test 4: Health check
echo "4. Testing health check:"
curl -X GET http://localhost:8080/health \
  -w "\nHTTP Status: %{http_code}\n" \
  -s

echo -e "\n"
echo "Test completed!"
