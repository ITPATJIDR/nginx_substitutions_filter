#!/bin/bash

echo "=== Testing Request Body and Headers Logging to Kafka ==="
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
echo -e "${YELLOW}Step 2: Testing with API running (should log 4xx errors with body/headers)...${NC}"

echo ""
echo -e "${YELLOW}Step 3: Testing GET request with custom headers...${NC}"
curl -s -X GET "http://localhost:8082/api/nonexistent?param1=value1&param2=value2" \
  -H "X-Custom-Header: test-value" \
  -H "X-User-ID: 12345" \
  -H "X-Request-ID: req-$(date +%s)" \
  -H "Authorization: Bearer fake-token-123" | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 4: Testing POST request with JSON body...${NC}"
curl -s -X POST http://localhost:8082/api/users \
  -H "Content-Type: application/json" \
  -H "X-Custom-Header: post-test" \
  -H "X-User-ID: 67890" \
  -H "Authorization: Bearer fake-token-456" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "profile": {
      "firstName": "John",
      "lastName": "Doe",
      "age": 30,
      "city": "Bangkok"
    },
    "preferences": {
      "theme": "dark",
      "language": "en"
    }
  }' | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 5: Testing PUT request with large body...${NC}"
curl -s -X PUT http://localhost:8082/api/users/123 \
  -H "Content-Type: application/json" \
  -H "X-Custom-Header: put-test" \
  -H "X-User-ID: 11111" \
  -H "If-Match: \"etag-value\"" \
  -d '{
    "username": "updateduser",
    "email": "updated@example.com",
    "data": "'$(python3 -c "print('X' * 10000)")'",
    "metadata": {
      "updated_by": "admin",
      "updated_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
      "version": "2.0"
    }
  }' | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 6: Testing DELETE request...${NC}"
curl -s -X DELETE http://localhost:8082/api/users/123 \
  -H "X-Custom-Header: delete-test" \
  -H "X-User-ID: 22222" \
  -H "Authorization: Bearer fake-token-789" | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 7: Testing with form data...${NC}"
curl -s -X POST http://localhost:8082/api/form-test \
  -H "X-Custom-Header: form-test" \
  -H "X-User-ID: 33333" \
  -F "username=formuser" \
  -F "email=form@example.com" \
  -F "description=This is a test form submission with some additional content" \
  -F "file=@/dev/null;filename=test.txt;type=text/plain" | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 8: Testing with XML content...${NC}"
curl -s -X POST http://localhost:8082/api/xml-test \
  -H "Content-Type: application/xml" \
  -H "X-Custom-Header: xml-test" \
  -H "X-User-ID: 44444" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<root>
  <user>
    <id>123</id>
    <name>XML User</name>
    <email>xml@example.com</email>
    <data>This is XML content for testing</data>
  </user>
</root>' | jq . || echo "Request failed or no jq installed"

echo ""
echo -e "${YELLOW}Step 9: Waiting for Kafka producer to flush...${NC}"
sleep 3

echo ""
echo -e "${GREEN}Step 10: Checking Kafka messages (last 10 messages)...${NC}"
echo "Note: Look for 'log_type': 'response_log' with request_body and request_headers"
docker-compose exec -T kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning \
  --max-messages 10 \
  --timeout-ms 10000 2>/dev/null | jq 'select(.log_type == "response_log")' || echo "No new messages or jq not installed"

echo ""
echo -e "${GREEN}Step 11: Checking specific request details...${NC}"
echo "Request bodies:"
docker-compose exec -T kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning \
  --max-messages 10 \
  --timeout-ms 10000 2>/dev/null | jq 'select(.log_type == "response_log" and .request_body != null) | {method: .request_method, uri: .request_uri, body_length: (.request_body | length), body_preview: (.request_body | .[0:100])}' || echo "No messages with body"

echo ""
echo "Request headers:"
docker-compose exec -T kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning \
  --max-messages 10 \
  --timeout-ms 10000 2>/dev/null | jq 'select(.log_type == "response_log" and .request_headers != null) | {method: .request_method, uri: .request_uri, headers: .request_headers}' || echo "No messages with headers"

echo ""
echo -e "${GREEN}=== Test Complete ===${NC}"
echo "Check Kafka consumer for messages with:"
echo "  docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic failed-requests --from-beginning"
echo ""
echo "Filter by log type:"
echo "  docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic failed-requests --from-beginning | jq 'select(.log_type == \"response_log\")'"
echo ""
echo "Check request bodies:"
echo "  docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic failed-requests --from-beginning | jq 'select(.request_body != null) | {method: .request_method, body: .request_body}'"
