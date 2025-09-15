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
CLIENT_ID="nginx-gateway"
CLIENT_SECRET="nginx-secret"

# Default to testuser, but allow override
USERNAME=${1:-"testuser"}
PASSWORD=${2:-"testpass"}

echo "Using credentials: $USERNAME / $PASSWORD"
echo "Client: $CLIENT_ID"
echo ""

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
    echo "Make sure Keycloak is running: docker-compose up keycloak"
    echo "Check logs: docker-compose logs keycloak"
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
    echo -e "${BLUE}Test commands:${NC}"
    echo "# Test public endpoint (no auth required)"
    echo "curl http://localhost:8000/"
    echo ""
    echo "# Test with authentication"
    echo "curl -H \"Authorization: Bearer $access_token\" http://localhost:8000/"
    echo ""
    echo "# Test API endpoint (requires auth)"
    echo "curl -H \"Authorization: Bearer $access_token\" http://localhost:8000/api/data"
    echo ""
    echo "# Test user endpoint"
    echo "curl -H \"Authorization: Bearer $access_token\" http://localhost:8000/user"
    echo ""
    echo "# Test admin endpoint (requires admin role)"
    echo "curl -H \"Authorization: Bearer $access_token\" http://localhost:8000/admin"
    echo ""
    
    # Save token to file
    echo -e "${BLUE}Save token to file:${NC}"
    echo "$access_token" > jwt-token.txt
    echo "Token saved to jwt-token.txt"
    echo ""
    
    # Test the token automatically
    echo -e "${YELLOW}Testing the token with nginx...${NC}"
    
    echo "Testing public endpoint:"
    public_response=$(curl -s http://localhost:8000/ 2>/dev/null || echo "Gateway not accessible")
    if echo "$public_response" | grep -q "timestamp"; then
        echo -e "${GREEN}✓ Public endpoint accessible${NC}"
    else
        echo -e "${YELLOW}! Public endpoint response: $public_response${NC}"
    fi
    
    echo "Testing authenticated endpoint:"
    auth_response=$(curl -s -H "Authorization: Bearer $access_token" http://localhost:8000/api/data 2>/dev/null || echo "Gateway not accessible")
    if echo "$auth_response" | grep -q "timestamp"; then
        echo -e "${GREEN}✓ Authenticated endpoint accessible${NC}"
    else
        echo -e "${YELLOW}! Auth endpoint response: $auth_response${NC}"
    fi
    
else
    echo -e "${RED}✗ Failed to get JWT token${NC}"
    echo "Response: $response"
    echo ""
    echo "Common issues:"
    echo "1. Make sure Keycloak is running and accessible"
    echo "2. Check if the realm 'test' exists"
    echo "3. Verify client credentials are correct"
    echo "4. Check username/password"
    echo ""
    echo "Available users:"
    echo "- testuser / testpass (user role)"
    echo "- admin / adminpass (admin role)"
    echo ""
    echo "Usage: $0 [username] [password]"
    echo "Example: $0 admin adminpass"
fi
