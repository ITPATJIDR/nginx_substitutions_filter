#!/bin/bash

# Script to get JWT token from Keycloak for testing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔑 Getting JWT Token from Keycloak${NC}"
echo "=========================================="

# Configuration
KEYCLOAK_URL="http://localhost:8080"
REALM="test"
CLIENT_ID="test-client"
CLIENT_SECRET="test-secret"
USERNAME="testuser"
PASSWORD="testpass"

# Wait for Keycloak to be ready
echo -e "${YELLOW}Checking if Keycloak is ready...${NC}"
max_attempts=60
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s -f "$KEYCLOAK_URL/health/ready" > /dev/null; then
        echo -e "${GREEN}✓ Keycloak is ready!${NC}"
        break
    fi
    
    echo "Attempt $attempt/$max_attempts - Waiting for Keycloak..."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo -e "${RED}✗ Keycloak is not ready after $max_attempts attempts${NC}"
    echo "Make sure Keycloak is running: make start"
    echo "Check logs: make keycloak-logs"
    echo ""
    echo "Troubleshooting:"
    echo "1. PostgreSQL must be healthy first"
    echo "2. Keycloak startup can take 60-90 seconds"
    echo "3. Check for import errors in Keycloak logs"
    exit 1
fi

# Get token using password grant
echo -e "${YELLOW}Getting JWT token...${NC}"

response=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "grant_type=password" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD")

# Check if we got a token
access_token=$(echo "$response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$access_token" ]; then
    echo -e "${GREEN}✓ Successfully obtained JWT token!${NC}"
    echo ""
    echo -e "${BLUE}Access Token:${NC}"
    echo "$access_token"
    echo ""
    echo -e "${BLUE}Test the gateway with this token:${NC}"
    echo "curl -H \"Authorization: Bearer $access_token\" http://localhost:8000/"
    echo ""
    echo -e "${BLUE}Test user endpoint:${NC}"
    echo "curl -H \"Authorization: Bearer $access_token\" http://localhost:8000/user"
    echo ""
    echo -e "${BLUE}Save token to file:${NC}"
    echo "$access_token" > jwt-token.txt
    echo "Token saved to jwt-token.txt"
    echo ""
    
    # Test the token automatically
    echo -e "${YELLOW}Testing the token with the gateway...${NC}"
    gateway_response=$(curl -s -H "Authorization: Bearer $access_token" http://localhost:8000/ 2>/dev/null || echo "Gateway not accessible")
    
    if echo "$gateway_response" | grep -q "timestamp"; then
        echo -e "${GREEN}✓ Gateway accepted the token and returned valid response!${NC}"
    else
        echo -e "${YELLOW}! Gateway response: $gateway_response${NC}"
        echo "Make sure the gateway is running: docker-compose up gateway"
    fi
    
else
    echo -e "${RED}✗ Failed to get JWT token${NC}"
    echo "Response: $response"
    echo ""
    echo "Common issues:"
    echo "1. Make sure Keycloak is running and accessible"
    echo "2. Check if the realm 'test' exists"
    echo "3. Verify client credentials are correct"
    echo ""
    echo "To setup Keycloak:"
    echo "1. Go to http://localhost:8080"
    echo "2. Login with admin/admin"
    echo "3. Import the realm from keycloak-init/test-realm.json"
fi
