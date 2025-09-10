#!/bin/bash

echo "=== Testing HTTP Substitutions Filter Module ==="
echo

echo "1. Testing POST endpoint (basic substitution):"
curl -X POST http://localhost:8080/api \
    -H "Content-Type: application/json" \
    -d '{"name":"World"}'
echo -e "\nExpected: 'Hello' → 'Hi', 'Express' → 'Nginx-Express'\n"

echo "2. Testing GET endpoint (multiple substitutions):"
curl http://localhost:8080/api
echo -e "\nExpected: 'Hello' → 'Hi', 'Express' → 'Nginx-Express'\n"

echo "3. Testing regex endpoint (numbers should be replaced if regex is enabled):"
curl http://localhost:8080/test-regex
echo -e "\nExpected: 'Hello' → 'Hi', 'Express' → 'Nginx-Express'\n"

echo "4. Testing case variations:"
curl http://localhost:8080/test-case
echo -e "\nExpected: 'Hello' → 'Hi', 'Express' → 'Nginx-Express'\n"

echo "5. Testing health check:"
curl http://localhost:8080/health
echo -e "\nExpected: 'Hello' → 'Hi', 'Express' → 'Nginx-Express'\n"

echo "=== Test completed ==="