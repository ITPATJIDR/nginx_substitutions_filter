# Quick Start Guide

## 1. Start Everything

```bash
docker-compose up --build -d
```

Wait 10-15 seconds for all services to start.

## 2. Test Normal Operation

```bash
# Check OpenResty health
curl http://localhost:8080/health

# Test API through OpenResty
curl http://localhost:8080/api/health
curl http://localhost:8080/api/users
```

## 3. Simulate Backend Failure

```bash
# Stop the backend API
docker-compose stop api

# Make a request - it will be intercepted and sent to Kafka
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

You should see a 503 response like:
```json
{
  "error": "Backend service unavailable",
  "message": "Your request has been queued for processing",
  "request_id": "unknown",
  "timestamp": 1697812345.678
}
```

## 4. View Failed Requests in Kafka

```bash
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning
```

Press Ctrl+C to exit the consumer.

## 5. Restart Backend

```bash
docker-compose start api
```

## Using Make Commands

If you have `make` installed:

```bash
# Start everything
make up

# Test normal requests
make test

# Stop API to simulate failure
make stop-api

# Test failed request
make test-fail

# View Kafka messages
make consume-kafka

# Restart API
make start-api

# Stop everything
make down
```

## Architecture Flow

```
1. Client Request → http://localhost:8080/api/users
                      ↓
2. OpenResty receives request
                      ↓
3. Try to proxy to Backend (http://api:3000)
                      ↓
           ┌──────────┴──────────┐
           │                     │
       ✓ Success            ✗ Failure (502/503/504)
           │                     │
    Return response      handle_error.lua
                                 │
                        1. Capture request data
                        2. Send to Kafka topic "failed-requests"
                        3. Return 503 to client
```

## Port Reference

- **8080**: OpenResty (main entry point)
- **3000**: Express API (backend)
- **9092**: Kafka (internal Docker network)
- **29092**: Kafka (external access from host)
- **2181**: Zookeeper

## Troubleshooting

### Check logs
```bash
docker-compose logs -f openresty
docker-compose logs -f api
docker-compose logs -f kafka
```

### List Kafka topics
```bash
docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### Restart everything
```bash
docker-compose restart
```

### Clean up
```bash
docker-compose down -v
```

