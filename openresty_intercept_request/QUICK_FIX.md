# Quick Fix for Build Issues

## Problem
```
npm error notarget No matching version found for accepts@~1.3.9
```

## Solution

### Option 1: Use npm install (Recommended)
```bash
# The Dockerfile has been updated to use:
RUN npm install --omit=dev

# This should work now
docker-compose build api
docker-compose up -d
```

### Option 2: Clean Build
```bash
# Stop everything
docker-compose down

# Remove all images
docker-compose down --rmi all

# Build fresh
docker-compose build --no-cache
docker-compose up -d
```

### Option 3: Manual Fix
```bash
# Go to api directory
cd api

# Remove package-lock.json
rm package-lock.json

# Install dependencies locally to generate new lock file
npm install

# Build Docker
docker-compose build api
docker-compose up -d
```

## Current Dockerfile
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

## Test the Fix
```bash
# 1. Build and start
docker-compose up -d

# 2. Check services
docker-compose ps

# 3. Test API
curl http://localhost:8082/health

# 4. Test Kafka logging
docker-compose stop api
curl -X POST http://localhost:8082/api/test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# 5. Check Kafka
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning | jq 'select(.log_type == "backend_error")'

# 6. Restart API
docker-compose start api
```

## Why This Happened
- `npm ci` requires exact package versions from `package-lock.json`
- The generated `package-lock.json` had version conflicts
- `npm install` is more flexible and resolves dependencies automatically

## Alternative: Use Yarn
If you prefer Yarn over npm:
```dockerfile
FROM node:20-alpine

WORKDIR /app

# Install yarn
RUN npm install -g yarn

COPY package*.json ./
RUN yarn install --production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```
