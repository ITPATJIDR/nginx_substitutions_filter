#!/bin/bash

# OpenResty + Keycloak + Express API Test Script
# This script tests the complete authentication flow and API endpoints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
KEYCLOAK_URL="http://localhost:8081"
OPENRESTY_URL="http://localhost:8082"
REALM="example"
CLIENT_ID="openresty"
CLIENT_SECRET="openresty-secret"
USERNAME="test"
PASSWORD="test123"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
print_test_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name: $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name: $message"
        ((TESTS_FAILED++))
    fi
}

# Function to check if services are running
check_services() {
    echo -e "${BLUE}🔍 Checking if services are running...${NC}"
    
    # Check Keycloak
    if curl -s -f "$KEYCLOAK_URL/realms/$REALM" > /dev/null 2>&1; then
        print_test_result "Keycloak Service" "PASS" "Keycloak is running on port 8081"
    else
        print_test_result "Keycloak Service" "FAIL" "Keycloak is not running on port 8081"
        echo -e "${RED}Please start the services with: docker compose up -d --build${NC}"
        return 1
    fi
    
    # Check OpenResty
    echo -e "${YELLOW}Testing OpenResty connection to $OPENRESTY_URL...${NC}"
    local openresty_response=$(curl -s -w "%{http_code}" "$OPENRESTY_URL" 2>/dev/null || echo "000")
    local openresty_status="${openresty_response: -3}"
    
    if [ "$openresty_status" = "200" ] || [ "$openresty_status" = "000" ]; then
        if [ "$openresty_status" = "200" ]; then
            print_test_result "OpenResty Service" "PASS" "OpenResty is running on port 8082"
        else
            print_test_result "OpenResty Service" "FAIL" "OpenResty is not running on port 8082 (connection refused)"
        fi
    else
        print_test_result "OpenResty Service" "FAIL" "OpenResty returned status $openresty_status"
    fi
    
    if [ "$openresty_status" != "200" ]; then
        echo -e "${RED}Please start the services with: docker compose up -d --build${NC}"
        echo -e "${YELLOW}Debug info: curl response was '$openresty_response'${NC}"
        return 1
    fi
}

# Function to get access token from Keycloak
get_access_token() {
    echo -e "${BLUE}🔐 Getting access token from Keycloak...${NC}"
    
    local token_response=$(curl -s -X POST \
        "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=password" \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET" \
        -d "username=$USERNAME" \
        -d "password=$PASSWORD")
    
    if echo "$token_response" | grep -q "access_token"; then
        ACCESS_TOKEN=$(echo "$token_response" | jq -r '.access_token')
        print_test_result "Token Retrieval" "PASS" "Successfully obtained access token"
        echo -e "${YELLOW}Token: ${ACCESS_TOKEN:0:50}...${NC}"
    else
        print_test_result "Token Retrieval" "FAIL" "Failed to get access token"
        echo -e "${RED}Response: $token_response${NC}"
        return 1
    fi
}

# Function to test public endpoints
test_public_endpoints() {
    echo -e "${BLUE}🌐 Testing public endpoints (no authentication required)...${NC}"
    
    # Test root endpoint
    local root_response=$(curl -s -w "%{http_code}" "$OPENRESTY_URL/")
    local root_status="${root_response: -3}"
    local root_body="${root_response%???}"
    
    if [ "$root_status" = "200" ] && [ "$root_body" = "OK" ]; then
        print_test_result "Root Endpoint" "PASS" "Returns 200 OK"
    else
        print_test_result "Root Endpoint" "FAIL" "Expected 200 OK, got $root_status"
    fi
    
    # Test public status endpoint
    local status_response=$(curl -s -w "%{http_code}" "$OPENRESTY_URL/api/public/status")
    local status_status="${status_response: -3}"
    local status_body="${status_response%???}"
    
    if [ "$status_status" = "200" ] && echo "$status_body" | grep -q "healthy"; then
        print_test_result "Public Status Endpoint" "PASS" "Returns 200 with health status"
    else
        print_test_result "Public Status Endpoint" "FAIL" "Expected 200 with health status, got $status_status"
    fi
    
    # Test public info endpoint
    local info_response=$(curl -s -w "%{http_code}" "$OPENRESTY_URL/api/public/info")
    local info_status="${info_response: -3}"
    local info_body="${info_response%???}"
    
    if [ "$info_status" = "200" ] && echo "$info_body" | grep -q "example-api"; then
        print_test_result "Public Info Endpoint" "PASS" "Returns 200 with API info"
    else
        print_test_result "Public Info Endpoint" "FAIL" "Expected 200 with API info, got $status_status"
    fi
}

# Function to test protected endpoints with valid token
test_protected_endpoints() {
    echo -e "${BLUE}🔒 Testing protected endpoints with valid JWT token...${NC}"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        echo -e "${RED}No access token available. Skipping protected endpoint tests.${NC}"
        return 1
    fi
    
    # Test /api/hello endpoint
    local hello_response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        "$OPENRESTY_URL/api/hello")
    local hello_status="${hello_response: -3}"
    local hello_body="${hello_response%???}"
    
    if [ "$hello_status" = "200" ] && echo "$hello_body" | grep -q "Hello"; then
        print_test_result "Protected Hello Endpoint" "PASS" "Returns 200 with greeting"
        echo -e "${YELLOW}Response: $hello_body${NC}"
    else
        print_test_result "Protected Hello Endpoint" "FAIL" "Expected 200 with greeting, got $hello_status"
    fi
    
    # Test /api/protected/profile endpoint
    local profile_response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        "$OPENRESTY_URL/api/protected/profile")
    local profile_status="${profile_response: -3}"
    local profile_body="${profile_response%???}"
    
    if [ "$profile_status" = "200" ] && echo "$profile_body" | grep -q "user"; then
        print_test_result "Protected Profile Endpoint" "PASS" "Returns 200 with user profile"
        echo -e "${YELLOW}Response: $profile_body${NC}"
    else
        print_test_result "Protected Profile Endpoint" "FAIL" "Expected 200 with user profile, got $profile_status"
    fi
    
    # Test /api/protected/admin endpoint
    local admin_response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        "$OPENRESTY_URL/api/protected/admin")
    local admin_status="${admin_response: -3}"
    local admin_body="${admin_response%???}"
    
    if [ "$admin_status" = "200" ] && echo "$admin_body" | grep -q "admin"; then
        print_test_result "Protected Admin Endpoint" "PASS" "Returns 200 with admin data"
        echo -e "${YELLOW}Response: $admin_body${NC}"
    else
        print_test_result "Protected Admin Endpoint" "FAIL" "Expected 200 with admin data, got $admin_status"
    fi
}

# Function to test error cases
test_error_cases() {
    echo -e "${BLUE}❌ Testing error cases...${NC}"
    
    # Test protected endpoint without token
    local no_token_response=$(curl -s -w "%{http_code}" "$OPENRESTY_URL/api/hello")
    local no_token_status="${no_token_response: -3}"
    
    if [ "$no_token_status" = "401" ]; then
        print_test_result "No Token Error" "PASS" "Returns 401 Unauthorized"
    else
        print_test_result "No Token Error" "FAIL" "Expected 401, got $no_token_status"
    fi
    
    # Test protected endpoint with invalid token
    local invalid_token_response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer invalid-token" \
        "$OPENRESTY_URL/api/hello")
    local invalid_token_status="${invalid_token_response: -3}"
    
    if [ "$invalid_token_status" = "401" ]; then
        print_test_result "Invalid Token Error" "PASS" "Returns 401 Unauthorized"
    else
        print_test_result "Invalid Token Error" "FAIL" "Expected 401, got $invalid_token_status"
    fi
    
    # Test protected endpoint with malformed authorization header
    local malformed_response=$(curl -s -w "%{http_code}" \
        -H "Authorization: InvalidFormat token" \
        "$OPENRESTY_URL/api/hello")
    local malformed_status="${malformed_response: -3}"
    
    if [ "$malformed_status" = "401" ]; then
        print_test_result "Malformed Auth Header" "PASS" "Returns 401 Unauthorized"
    else
        print_test_result "Malformed Auth Header" "FAIL" "Expected 401, got $malformed_status"
    fi
}

# Function to test JWT token validation
test_jwt_validation() {
    echo -e "${BLUE}🔍 Testing JWT token validation...${NC}"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        echo -e "${RED}No access token available. Skipping JWT validation tests.${NC}"
        return 1
    fi
    
    # Decode JWT token (header and payload)
    local header=$(echo "$ACCESS_TOKEN" | cut -d. -f1 | base64 -d 2>/dev/null || echo "{}")
    local payload=$(echo "$ACCESS_TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null || echo "{}")
    
    echo -e "${YELLOW}JWT Header: $header${NC}"
    echo -e "${YELLOW}JWT Payload: $payload${NC}"
    
    # Check if token contains expected claims
    if echo "$payload" | grep -q "preferred_username\|email\|sub"; then
        print_test_result "JWT Claims" "PASS" "Token contains user identification claims"
    else
        print_test_result "JWT Claims" "FAIL" "Token missing user identification claims"
    fi
}

# Function to test Keycloak endpoints
test_keycloak_endpoints() {
    echo -e "${BLUE}🔑 Testing Keycloak endpoints...${NC}"
    
    # Test realm discovery
    local discovery_response=$(curl -s -w "%{http_code}" "$KEYCLOAK_URL/realms/$REALM/.well-known/openid-configuration")
    local discovery_status="${discovery_response: -3}"
    
    if [ "$discovery_status" = "200" ]; then
        print_test_result "OIDC Discovery" "PASS" "Realm discovery endpoint accessible"
    else
        print_test_result "OIDC Discovery" "FAIL" "Realm discovery endpoint not accessible"
    fi
    
    # Test realm info
    local realm_response=$(curl -s -w "%{http_code}" "$KEYCLOAK_URL/realms/$REALM")
    local realm_status="${realm_response: -3}"
    
    if [ "$realm_status" = "200" ]; then
        print_test_result "Realm Info" "PASS" "Realm info endpoint accessible"
    else
        print_test_result "Realm Info" "FAIL" "Realm info endpoint not accessible"
    fi
}

# Function to print summary
print_summary() {
    echo -e "\n${BLUE}📊 Test Summary${NC}"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    
    local total=$((TESTS_PASSED + TESTS_FAILED))
    if [ $total -gt 0 ]; then
        local success_rate=$((TESTS_PASSED * 100 / total))
        echo -e "${BLUE}Success Rate: $success_rate%${NC}"
    fi
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
    else
        echo -e "${RED}⚠️  Some tests failed. Check the output above for details.${NC}"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting OpenResty + Keycloak + Express API Tests${NC}"
    echo -e "${BLUE}================================================${NC}\n"
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️  jq is not installed. Some JSON parsing features may not work.${NC}"
        echo -e "${YELLOW}   Install jq for better token handling: https://stedolan.github.io/jq/${NC}\n"
    fi
    
    if ! check_services; then
        echo -e "${RED}❌ Service check failed. Please ensure all services are running.${NC}"
        print_summary
        exit 1
    fi
    echo ""
    
    test_keycloak_endpoints
    echo ""
    
    get_access_token
    echo ""
    
    test_public_endpoints
    echo ""
    
    test_protected_endpoints
    echo ""
    
    test_error_cases
    echo ""
    
    test_jwt_validation
    echo ""
    
    print_summary
}

# Run main function
main "$@"
