#!/bin/bash

echo "Testing Nginx + Keycloak + Express Setup"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test health endpoints
echo -e "${YELLOW}1. Testing health endpoints...${NC}"

echo "Nginx health:"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Nginx gateway is healthy${NC}"
else
    echo -e "${RED}✗ Nginx gateway health check failed (HTTP $response)${NC}"
fi

echo "App health (direct):"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Express app is healthy${NC}"
else
    echo -e "${RED}✗ Express app health check failed (HTTP $response)${NC}"
fi

echo "Keycloak health:"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health/ready)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Keycloak is healthy${NC}"
else
    echo -e "${RED}✗ Keycloak health check failed (HTTP $response)${NC}"
fi

echo ""

# Test public endpoint
echo -e "${YELLOW}2. Testing public endpoint (no auth required)...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Public endpoint is accessible${NC}"
else
    echo -e "${RED}✗ Public endpoint failed (HTTP $response)${NC}"
fi

echo ""

# Test protected endpoint without auth
echo -e "${YELLOW}3. Testing protected endpoint without authentication...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/data)
if [ "$response" = "401" ]; then
    echo -e "${GREEN}✓ Protected endpoint correctly rejects unauthenticated requests${NC}"
else
    echo -e "${RED}✗ Protected endpoint should return 401 (got HTTP $response)${NC}"
fi

echo ""

# Test with JWT token
echo -e "${YELLOW}4. Testing with JWT authentication...${NC}"

# Get token
echo "Getting JWT token..."
token_response=$(bash get-jwt-token.sh testuser testpass 2>/dev/null | grep "Access Token:" -A 1 | tail -n 1)

if [ -n "$token_response" ] && [ "$token_response" != "Access Token:" ]; then
    echo -e "${GREEN}✓ Successfully obtained JWT token${NC}"
    
    # Test authenticated endpoint
    echo "Testing authenticated API endpoint..."
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token_response" http://localhost:8000/api/data)
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ Authenticated API endpoint works${NC}"
    else
        echo -e "${RED}✗ Authenticated API endpoint failed (HTTP $response)${NC}"
    fi
    
    # Test user endpoint
    echo "Testing user info endpoint..."
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token_response" http://localhost:8000/user)
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ User info endpoint works${NC}"
    else
        echo -e "${RED}✗ User info endpoint failed (HTTP $response)${NC}"
    fi
    
else
    echo -e "${RED}✗ Failed to get JWT token${NC}"
    echo "This may be normal if Keycloak is still starting up..."
fi

echo ""

# Test admin endpoint
echo -e "${YELLOW}5. Testing admin endpoint...${NC}"

# Get admin token
echo "Getting admin JWT token..."
admin_token=$(bash get-jwt-token.sh admin adminpass 2>/dev/null | grep "Access Token:" -A 1 | tail -n 1)

if [ -n "$admin_token" ] && [ "$admin_token" != "Access Token:" ]; then
    echo -e "${GREEN}✓ Successfully obtained admin JWT token${NC}"
    
    # Test admin endpoint
    echo "Testing admin endpoint..."
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $admin_token" http://localhost:8000/admin)
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ Admin endpoint works${NC}"
    else
        echo -e "${RED}✗ Admin endpoint failed (HTTP $response)${NC}"
    fi
    
    # Test user trying to access admin
    if [ -n "$token_response" ] && [ "$token_response" != "Access Token:" ]; then
        echo "Testing user access to admin endpoint (should fail)..."
        response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token_response" http://localhost:8000/admin)
        if [ "$response" = "403" ]; then
            echo -e "${GREEN}✓ Regular user correctly denied admin access${NC}"
        else
            echo -e "${RED}✗ Regular user should be denied admin access (got HTTP $response)${NC}"
        fi
    fi
else
    echo -e "${RED}✗ Failed to get admin JWT token${NC}"
fi

echo ""
echo -e "${YELLOW}Setup Testing Complete!${NC}"
echo "================================================"
echo "Service URLs:"
echo "- Nginx Gateway: http://localhost:8000"
echo "- Keycloak Admin: http://localhost:8080 (admin/admin)"
echo "- Express App: http://localhost:3000"
echo ""
echo "Test users:"
echo "- testuser / testpass (user role)"
echo "- admin / adminpass (admin role)"
echo ""
echo "Use 'make get-token' to get JWT tokens for testing"
echo "Use 'make urls' to see all available endpoints"
