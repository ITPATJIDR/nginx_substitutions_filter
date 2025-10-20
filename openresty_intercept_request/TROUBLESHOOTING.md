# Troubleshooting Guide

## Build Issues

### npm ci Error: No package-lock.json

**Error:**
```
npm error The `npm ci` command can only install with an existing package-lock.json
```

**Solution:**
```bash
# Option 1: Use npm install instead (temporary fix)
# Edit api/Dockerfile and change:
# RUN npm ci --only=production
# to:
# RUN npm install --only=production

# Option 2: Generate package-lock.json (recommended)
cd api
npm install
# This will create package-lock.json
# Then use npm ci in Dockerfile
```

**Status:** ✅ Fixed - `package-lock.json` has been created

### Docker Build Fails

**Error:**
```
ERROR: Service 'api' failed to build : Build failed
```

**Solutions:**
```bash
# 1. Clean build
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 2. Check logs
docker-compose logs api

# 3. Build specific service
docker-compose build api
```

## Runtime Issues

### OpenResty Not Starting

**Check logs:**
```bash
docker-compose logs openresty
```

**Common issues:**
- Lua script syntax errors
- Missing dependencies
- Port conflicts

**Solutions:**
```bash
# Check nginx config
docker-compose exec openresty nginx -t

# Check Lua syntax
docker-compose exec openresty lua /usr/local/openresty/nginx/lua/kafka_logger.lua
```

### Kafka Connection Issues

**Error:**
```
Failed to send log to Kafka: connection refused
```

**Solutions:**
```bash
# 1. Check Kafka is running
docker-compose ps kafka

# 2. Check Kafka logs
docker-compose logs kafka

# 3. Test Kafka connectivity
docker-compose exec openresty ping kafka

# 4. Check environment variables
docker-compose exec openresty env | grep KAFKA
```

### No Messages in Kafka

**Check:**
```bash
# 1. Verify topic exists
docker-compose exec kafka kafka-topics --list --bootstrap-server localhost:9092

# 2. Check if messages are being sent
docker-compose logs openresty | grep -i kafka

# 3. Test with a simple request
curl http://localhost:8082/api/nonexistent
```

## Testing Issues

### Test Script Fails

**Error:**
```
./test_backend_unavailable.sh: Permission denied
```

**Solution:**
```bash
chmod +x test_backend_unavailable.sh
./test_backend_unavailable.sh
```

### jq Command Not Found

**Error:**
```
jq: command not found
```

**Solutions:**
```bash
# Install jq
# Ubuntu/Debian:
sudo apt-get install jq

# macOS:
brew install jq

# Or run without jq (raw JSON output)
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning
```

## Performance Issues

### High Memory Usage

**Check:**
```bash
docker stats
```

**Solutions:**
- Reduce `client_body_buffer_size` in nginx.conf
- Increase Kafka producer batch size
- Monitor request body sizes

### Slow Response Times

**Check:**
```bash
# Check nginx access logs
docker-compose exec openresty tail -f /usr/local/openresty/nginx/logs/access.log

# Check Kafka producer logs
docker-compose logs openresty | grep -i "kafka"
```

**Solutions:**
- Use async Kafka producer (already configured)
- Increase timeouts
- Check network latency

## Security Issues

### Sensitive Data in Logs

**Warning:** Request bodies may contain passwords, tokens, etc.

**Solutions:**
```lua
-- Add field masking in error_handler.lua
local function maskSensitiveData(data)
    if data.request_body then
        -- Mask passwords, tokens, etc.
        data.request_body = data.request_body:gsub('"password":"[^"]*"', '"password":"***"')
        data.request_body = data.request_body:gsub('"token":"[^"]*"', '"token":"***"')
    end
    return data
end
```

## Common Commands

### Debug Commands
```bash
# Check all services
docker-compose ps

# View all logs
docker-compose logs -f

# Check specific service logs
docker-compose logs -f openresty
docker-compose logs -f kafka
docker-compose logs -f api

# Execute commands in containers
docker-compose exec openresty bash
docker-compose exec kafka bash
docker-compose exec api sh
```

### Reset Everything
```bash
# Stop and remove everything
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Start fresh
docker-compose up -d
```

### Check Configuration
```bash
# Test nginx config
docker-compose exec openresty nginx -t

# Check Lua scripts
docker-compose exec openresty lua /usr/local/openresty/nginx/lua/kafka_logger.lua

# Test Kafka connectivity
docker-compose exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

## Getting Help

1. **Check logs first:** `docker-compose logs -f`
2. **Verify configuration:** Run test script
3. **Check this guide:** Look for your specific error
4. **Review documentation:** README.md, KAFKA_LOGGING.md

## Quick Fixes

### Most Common Issues

1. **Build fails:** `docker-compose build --no-cache`
2. **No Kafka messages:** Check if API is stopped for testing
3. **Permission denied:** `chmod +x test_backend_unavailable.sh`
4. **Port conflicts:** Check if ports 8082, 9092 are free
5. **Memory issues:** Increase Docker memory limits

### Emergency Reset
```bash
# Nuclear option - reset everything
docker-compose down -v --rmi all
docker system prune -f
docker-compose up -d
```
