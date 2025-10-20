#!/bin/bash

# Test script for OpenResty Request Interceptor

set -e

echo "======================================"
echo "OpenResty Request Interceptor Test"
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local description=$4
    
    echo -e "\n${YELLOW}Testing: ${description}${NC}"
    echo "Method: $method"
    echo "URL: $url"
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" -H "Content-Type: application/json" -d "$data")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "HTTP Status: $http_code"
    echo "Response: $body"
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ Test passed${NC}"
        return 0
    elif [ "$http_code" -eq 503 ]; then
        echo -e "${YELLOW}✓ Test passed (expected 503 - request intercepted)${NC}"
        return 0
    else
        echo -e "${RED}✗ Test failed${NC}"
        return 1
    fi
}

echo -e "\n${GREEN}Step 1: Testing with backend available${NC}"
echo "========================================"

test_endpoint "GET" "http://localhost:8080/health" "" "Health check endpoint"
test_endpoint "GET" "http://localhost:8080/api/health" "" "API health endpoint"
test_endpoint "GET" "http://localhost:8080/api/users" "" "Get users"
test_endpoint "GET" "http://localhost:8080/api/data" "" "Get data"
test_endpoint "POST" "http://localhost:8080/api/users" '{"name":"Test User","email":"test@example.com"}' "Create user"

echo -e "\n${YELLOW}Step 2: Stop the API backend${NC}"
echo "========================================"
echo "Run: docker-compose stop api"
echo "Then press Enter to continue..."
read -r

echo -e "\n${RED}Step 3: Testing with backend unavailable${NC}"
echo "========================================"

test_endpoint "GET" "http://localhost:8080/api/health" "" "API health (should be intercepted)"
test_endpoint "POST" "http://localhost:8080/api/users" '{"name":"John Doe","email":"john@example.com"}' "Create user (should be intercepted)"

echo -e "\n${YELLOW}Step 4: Check Kafka messages${NC}"
echo "========================================"
echo "Run the following command to see messages in Kafka:"
echo "docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic failed-requests --from-beginning"

echo -e "\n${GREEN}Step 5: Restart the API${NC}"
echo "========================================"
echo "Run: docker-compose start api"

echo -e "\n${GREEN}All tests completed!${NC}"

