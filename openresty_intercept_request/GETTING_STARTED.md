# Getting Started with OpenResty Request Interceptor

## 🎯 What You'll Learn

In this guide, you'll set up a complete fault-tolerant request interception system that:
- Captures failed backend requests
- Queues them to Kafka
- Provides retry mechanisms
- Ensures no request data is lost

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ Docker installed (version 20.10+)
- ✅ Docker Compose installed (version 2.0+)
- ✅ At least 2GB free RAM
- ✅ Ports 8080, 3000, 9092, 29092, 2181 available

### Verify Prerequisites

```bash
# Check Docker
docker --version

# Check Docker Compose
docker-compose --version

# Check available ports (PowerShell on Windows)
netstat -an | findstr "8080 3000 9092 2181"
# Should return nothing if ports are free
```

## 🚀 Step-by-Step Setup

### Step 1: Navigate to Project Directory

```bash
cd openresty_intercept_request
```

### Step 2: Build and Start Services

```bash
# Build all Docker images
docker-compose build

# Start all services in detached mode
docker-compose up -d

# Wait for services to be ready (about 15-20 seconds)
# Check status
docker-compose ps
```

You should see 4 services running:
- `openresty_intercept_request_zookeeper_1`
- `openresty_intercept_request_kafka_1`
- `openresty_intercept_request_api_1`
- `openresty_intercept_request_openresty_1`

### Step 3: Verify Services Are Running

```bash
# Check OpenResty
curl http://localhost:8080/health
# Expected: "OpenResty is running"

# Check API through OpenResty
curl http://localhost:8080/api/health
# Expected: {"status":"ok","message":"API is running"}

# Check direct API access
curl http://localhost:3000/api/health
# Expected: {"status":"ok","message":"API is running"}
```

If all three commands succeed, your setup is working! 🎉

## 🧪 Testing the System

### Test 1: Normal Request Flow

When the backend is running, requests should pass through normally.

```bash
# Get users
curl http://localhost:8080/api/users

# Get data
curl http://localhost:8080/api/data

# Create a user
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'
```

**Expected Result**: All requests succeed with 200/201 status codes.

### Test 2: Backend Failure Interception

Now let's simulate a backend failure.

```bash
# Stop the backend API
docker-compose stop api

# Verify backend is stopped
curl http://localhost:3000/api/health
# Expected: Connection refused or timeout
```

Now make a request through OpenResty:

```bash
curl -v -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Bob","email":"bob@example.com"}'
```

**Expected Result**:
- HTTP Status: 503 (Service Unavailable)
- Response body:
  ```json
  {
    "error": "Backend service unavailable",
    "message": "Your request has been queued for processing",
    "request_id": "unknown",
    "timestamp": 1697812345.678
  }
  ```

✅ **Success!** The request was intercepted and queued to Kafka.

### Test 3: View Intercepted Requests in Kafka

```bash
# Open Kafka consumer
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning
```

**Expected Result**: You should see JSON messages like:

```json
{
  "timestamp": 1697812345.678,
  "method": "POST",
  "uri": "/api/users",
  "path": "/api/users",
  "query_string": "",
  "headers": {
    "content-type": "application/json",
    "host": "localhost:8080"
  },
  "body": "{\"name\":\"Bob\",\"email\":\"bob@example.com\"}",
  "remote_addr": "172.18.0.1",
  "backend_url": "http://api:3000",
  "error_reason": "Backend unavailable (502/503/504)"
}
```

Press `Ctrl+C` to exit the consumer.

### Test 4: Backend Recovery

Restart the backend and verify normal operation resumes:

```bash
# Restart API
docker-compose start api

# Wait a few seconds
sleep 5

# Test request
curl http://localhost:8080/api/health
```

**Expected Result**: Request succeeds normally.

## 🎓 Understanding What Happened

### Normal Flow
```
Client → OpenResty (8080) → Backend (3000) → Response
```

### Failure Flow
```
Client → OpenResty (8080) → Backend (3000) ❌ Failed
                                ↓
                         Lua Script Executes
                                ↓
                         Captures Request Data
                                ↓
                         Produces to Kafka
                                ↓
                         Returns 503 to Client
```

## 🔍 Monitoring and Debugging

### View Logs

```bash
# All services
docker-compose logs -f

# OpenResty only
docker-compose logs -f openresty

# API only
docker-compose logs -f api

# Kafka only
docker-compose logs -f kafka
```

### Check Service Health

```bash
# List running containers
docker-compose ps

# Check OpenResty nginx configuration
docker-compose exec openresty nginx -t

# List Kafka topics
docker-compose exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --list
```

### Common Issues

#### Port Already in Use

```bash
# On Windows (PowerShell)
netstat -ano | findstr "8080"
# Kill process if needed

# Change ports in docker-compose.yml
# For example: "8081:8080" instead of "8080:8080"
```

#### Services Not Starting

```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart

# Rebuild and restart
docker-compose down
docker-compose up --build -d
```

#### Kafka Connection Issues

```bash
# Wait longer (Kafka takes 10-15 seconds to start)
sleep 15

# Check Kafka is running
docker-compose ps kafka

# Check Kafka logs
docker-compose logs kafka | tail -50
```

## 📦 Optional: Set Up the Consumer

The consumer processes failed requests and can retry them.

```bash
# Navigate to consumer directory
cd consumer-example

# Install dependencies (requires Node.js)
npm install

# Run consumer
npm start
```

The consumer will:
1. Connect to Kafka
2. Read failed requests
3. Display request details
4. Automatically retry requests to the backend
5. Log success or failure

### Test the Consumer

1. Keep the consumer running
2. In another terminal, stop the API: `docker-compose stop api`
3. Make some requests to generate failures
4. Restart the API: `docker-compose start api`
5. Watch the consumer automatically retry and succeed!

## 🧹 Cleanup

### Stop Services

```bash
# Stop all services (keeps data)
docker-compose stop

# Stop and remove containers (keeps volumes)
docker-compose down

# Remove everything including volumes
docker-compose down -v
```

## 🎯 Next Steps

Now that you have the basics working:

1. **Explore the Code**:
   - Check `openresty/lua/handle_error.lua` to see Kafka integration
   - Review `openresty/nginx.conf` to understand routing
   - Look at `consumer-example/consumer.js` for retry logic

2. **Customize**:
   - Add authentication
   - Implement rate limiting
   - Add custom business logic
   - Create multiple backend services

3. **Production Ready**:
   - Add TLS/SSL
   - Increase Kafka replication
   - Set up monitoring (Prometheus/Grafana)
   - Implement proper logging
   - Add health checks

4. **Read Documentation**:
   - `README.md` - Detailed documentation
   - `ARCHITECTURE.md` - System design details
   - `QUICKSTART.md` - Quick reference
   - `SUMMARY.md` - Project overview

## 💡 Pro Tips

### Use Make Commands (if available)

```bash
make up              # Start everything
make test            # Run tests
make stop-api        # Stop API
make test-fail       # Test failure
make consume-kafka   # View Kafka messages
make down            # Stop everything
```

### Monitor in Real-Time

```bash
# Terminal 1: OpenResty logs
docker-compose logs -f openresty

# Terminal 2: Kafka consumer
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning

# Terminal 3: Make requests
curl http://localhost:8080/api/users
```

### Test Different Scenarios

```bash
# Timeout scenario (slow response)
# Heavy load scenario (many requests)
# Different HTTP methods (GET, POST, PUT, DELETE)
# Large request bodies
# Different content types
```

## ✅ Verification Checklist

Before moving to production, verify:

- [ ] All services start successfully
- [ ] Normal requests work
- [ ] Failed requests are intercepted
- [ ] Messages appear in Kafka
- [ ] Consumer can process messages
- [ ] Backend recovery works
- [ ] Logs are accessible
- [ ] Health checks work
- [ ] Documentation is clear

## 🎉 Congratulations!

You've successfully set up a fault-tolerant request interception system!

You now have:
- ✅ Working OpenResty reverse proxy
- ✅ Request interception on failure
- ✅ Kafka message queue
- ✅ Example consumer for processing
- ✅ Complete monitoring and logging

## 📚 Additional Resources

- [OpenResty Documentation](https://openresty.org/en/)
- [Lua Nginx Module](https://github.com/openresty/lua-nginx-module)
- [lua-resty-kafka](https://github.com/doubaokun/lua-resty-kafka)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Express.js Documentation](https://expressjs.com/)

## 🆘 Need Help?

1. Check the logs: `docker-compose logs -f`
2. Review the documentation files
3. Verify prerequisites are met
4. Try rebuilding: `docker-compose down -v && docker-compose up --build -d`
5. Check service status: `docker-compose ps`

---

**Happy coding! 🚀**

