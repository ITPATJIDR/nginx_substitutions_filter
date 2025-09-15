#!/bin/bash

echo "🔧 Fixing Docker Compose ContainerConfig error..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Stop all containers
echo -e "${YELLOW}1. Stopping all containers...${NC}"
docker-compose down -v --remove-orphans 2>/dev/null || true

# Step 2: Remove dangling containers
echo -e "${YELLOW}2. Cleaning up containers...${NC}"
docker container prune -f

# Step 3: Remove unused images
echo -e "${YELLOW}3. Cleaning up images...${NC}"
docker image prune -f

# Step 4: Remove unused volumes
echo -e "${YELLOW}4. Cleaning up volumes...${NC}"
docker volume prune -f

# Step 5: Remove unused networks
echo -e "${YELLOW}5. Cleaning up networks...${NC}"
docker network prune -f

# Step 6: Rebuild and start
echo -e "${YELLOW}6. Rebuilding and starting services...${NC}"
docker-compose build --no-cache
docker-compose up -d

# Step 7: Check status
echo -e "${YELLOW}7. Checking service status...${NC}"
sleep 5
docker-compose ps

# Step 8: Test health
echo -e "${YELLOW}8. Testing health endpoints...${NC}"
sleep 10

echo "Gateway health:"
curl -s http://localhost:8000/gateway-health && echo -e " ${GREEN}✓${NC}" || echo -e " ${RED}✗${NC}"

echo "App health through gateway:"
curl -s http://localhost:8000/health && echo -e " ${GREEN}✓${NC}" || echo -e " ${RED}✗${NC}"

echo -e "\n${GREEN}🎉 Fix complete!${NC}"
echo "================================================"
echo "Gateway: http://localhost:8000"
echo "App: http://localhost:3000"
echo "Use 'make logs' to view logs"
