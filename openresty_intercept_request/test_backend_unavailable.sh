#!/bin/bash

echo "=== Testing Backend Unavailable (502/503/504) Request Logging to Kafka ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if services are running
echo -e "${YELLOW}Step 1: Checking services...${NC}"
docker-compose ps

echo ""
echo -e "${YELLOW}Step 2: Testing with API running (should succeed)...${NC}"
curl -s http://localhost:8082/api/status | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 3: Stopping API service to simulate backend unavailability...${NC}"
docker-compose stop api
sleep 2

echo ""
echo -e "${YELLOW}Step 4: Testing GET request (should get 503 and log to Kafka)...${NC}"
curl -s http://localhost:8082/api/status | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 5: Testing POST request with JSON body (should get 503 and log to Kafka with body)...${NC}"
curl -s -X POST http://localhost:8082/api/users \
  -H "Content-Type: application/json" \
  -H "X-Custom-Header: test-value" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "data": {
      "age": 25,
      "city": "Bangkok"
    }
  }' | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 6: Testing POST request with large body...${NC}"
curl -s -X POST http://localhost:8082/api/upload \
  -H "Content-Type: application/json" \
  -d '{
    "file": "This is a simulated large file content that might be stored in temp file",
    "metadata": {
      "size": 1024,
      "type": "text/plain"
    }
  }' | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 7: Waiting for Kafka producer to flush...${NC}"
sleep 3

echo ""
echo -e "${GREEN}Step 8: Checking Kafka messages (last 5 messages)...${NC}"
echo "Note: Look for 'log_type': 'backend_error' with request_body field"
docker-compose exec -T kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning \
  --max-messages 5 \
  --timeout-ms 5000 2>/dev/null | jq . || echo "No new messages or jq not installed"

echo ""
echo -e "${YELLOW}Step 9: Restarting API service...${NC}"
docker-compose start api
sleep 2

echo ""
echo -e "${GREEN}Step 10: Verifying API is back up...${NC}"
curl -s http://localhost:8082/api/status | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${GREEN}=== Test Complete ===${NC}"
echo "Check Kafka consumer for messages with:"
echo "  docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic failed-requests --from-beginning"

