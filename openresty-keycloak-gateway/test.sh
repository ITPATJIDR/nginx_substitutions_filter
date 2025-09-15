#!/bin/bash

echo "Testing OpenResty Keycloak Gateway Setup"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test direct app access
echo -e "${YELLOW}1. Testing direct app access...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Express app is running${NC}"
else
    echo -e "${RED}✗ Express app is not accessible (HTTP $response)${NC}"
fi

# Test gateway without authentication
echo -e "${YELLOW}2. Testing gateway without authentication...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/)
if [ "$response" = "401" ]; then
    echo -e "${GREEN}✓ Gateway correctly rejects unauthenticated requests${NC}"
else
    echo -e "${RED}✗ Gateway should return 401 for unauthenticated requests (got HTTP $response)${NC}"
fi

# Test gateway health (if accessible)
echo -e "${YELLOW}3. Testing gateway health endpoint...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
if [ "$response" = "401" ]; then
    echo -e "${YELLOW}! Gateway health endpoint requires authentication${NC}"
elif [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Gateway health endpoint is accessible${NC}"
else
    echo -e "${RED}✗ Gateway health endpoint returned HTTP $response${NC}"
fi

# Test with sample JWT (this will fail but shows the error message)
echo -e "${YELLOW}4. Testing with sample JWT token...${NC}"
echo "Expected: This should fail with JWT verification error"
curl -s -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c" http://localhost:8000/ | head -n 3

echo -e "\n${YELLOW}Setup Complete!${NC}"
echo "================================================"
echo "Gateway URL: http://localhost:8000"
echo "App URL: http://localhost:3000"
echo ""
echo "To test with a real JWT token:"
echo "curl -H \"Authorization: Bearer YOUR_JWT_TOKEN\" http://localhost:8000/"
echo ""
echo "For more information, see README.md"
