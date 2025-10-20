#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:8082"

echo -e "${YELLOW}=== OpenResty Kafka Interceptor Test Script ===${NC}\n"

# Function to make request and show result
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local expected_status=$4
    
    echo -e "${YELLOW}Test: ${description}${NC}"
    echo "  ${method} ${BASE_URL}${endpoint}"
    
    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X ${method} ${BASE_URL}${endpoint})
    http_body=$(echo "$response" | sed -e 's/HTTP_STATUS\:.*//g')
    http_status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')
    
    echo "  Status: ${http_status}"
    echo "  Response: ${http_body}"
    
    if [ "$http_status" == "$expected_status" ]; then
        echo -e "  ${GREEN}✓ PASS${NC}\n"
    else
        echo -e "  ${RED}✗ FAIL (expected ${expected_status})${NC}\n"
    fi
}

# Test 1: Health check
test_endpoint "GET" "/health" "Health Check" "200"

# Test 2: Root endpoint
test_endpoint "GET" "/" "Root Endpoint" "200"

# Test 3: Status endpoint
test_endpoint "GET" "/api/status" "API Status" "200"

# Test 4: Hello endpoint
test_endpoint "GET" "/api/hello" "Hello Endpoint" "200"

# Test 5: Random endpoint (may fail)
echo -e "${YELLOW}Test: Random Endpoint (30% failure rate)${NC}"
echo "  Running 5 requests to see failures..."
for i in {1..5}; do
    status=$(curl -s -o /dev/null -w "%{http_code}" ${BASE_URL}/api/random)
    if [ "$status" == "503" ]; then
        echo -e "  Request $i: ${RED}503 Failed${NC} (logged to Kafka)"
    else
        echo -e "  Request $i: ${GREEN}200 Success${NC}"
    fi
done
echo ""

# Test 6: Backend unavailability simulation
echo -e "${YELLOW}=== Testing Backend Unavailability ===${NC}"
echo "This will test the error interceptor when backend is down"
echo ""
echo "To test manually:"
echo "  1. Stop the backend: docker-compose stop api"
echo "  2. Make request: curl ${BASE_URL}/api/status"
echo "  3. Check Kafka messages"
echo "  4. Start backend: docker-compose start api"
echo ""

# Test 7: 404 endpoint
test_endpoint "GET" "/api/nonexistent" "Non-existent Endpoint (404)" "404"

echo -e "${YELLOW}=== Kafka Messages ===${NC}"
echo "To view messages in Kafka, run:"
echo "  docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic failed-requests --from-beginning"
echo ""
echo "Or use the consumer script:"
echo "  ./consume_kafka.sh"

