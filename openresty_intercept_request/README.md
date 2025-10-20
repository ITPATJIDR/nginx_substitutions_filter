# OpenResty Request Interceptor with Kafka

This project demonstrates how to use OpenResty with Lua to intercept failed backend requests and produce them to Kafka for later processing.

## Architecture

```
Client → OpenResty (Lua) → Express Backend
                ↓
             (on error)
                ↓
              Kafka
```

### Components

1. **Express Backend (API)**: Simple Node.js/Express API server
2. **OpenResty**: Nginx with Lua module for request interception
3. **Kafka + Zookeeper**: Message broker for storing failed requests
4. **Lua Scripts**:
   - `intercept_request.lua`: Pre-processes incoming requests
   - `handle_error.lua`: Intercepts failed requests and produces to Kafka

## How It Works

1. Requests come into OpenResty on port 8080
2. OpenResty attempts to proxy the request to the Express backend
3. If the backend is unavailable (502, 503, 504 errors):
   - The Lua script intercepts the request
   - Captures request details (method, URI, headers, body)
   - Produces a message to Kafka topic `failed-requests`
   - Returns a friendly error message to the client
4. Failed requests can be consumed from Kafka for retry or analysis

## Prerequisites

- Docker
- Docker Compose

## Setup and Run

### 1. Start all services

```bash
docker-compose up --build
```

This will start:
- Zookeeper (port 2181)
- Kafka (ports 9092 internal, 29092 external)
- Express API (port 3000)
- OpenResty (port 8080)

### 2. Test normal requests

```bash
# Health check
curl http://localhost:8080/health

# API endpoint (backend available)
curl http://localhost:8080/api/health
curl http://localhost:8080/api/users
curl http://localhost:8080/api/data
```

### 3. Test failed request interception

Stop the backend to simulate failure:

```bash
docker-compose stop api
```

Now make requests - they will be intercepted and sent to Kafka:

```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

### 4. Consume messages from Kafka

To see the failed requests in Kafka:

```bash
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning
```

### 5. Restart backend

```bash
docker-compose start api
```

## Kafka Message Format

Failed requests are sent to Kafka with the following JSON structure:

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
  "body": "{\"name\":\"John Doe\",\"email\":\"john@example.com\"}",
  "remote_addr": "172.18.0.1",
  "backend_url": "http://api:3000",
  "error_reason": "Backend unavailable (502/503/504)"
}
```

## Configuration

### Environment Variables

You can customize the setup by modifying environment variables in `docker-compose.yml`:

**OpenResty:**
- `KAFKA_BROKER`: Kafka broker address (default: `kafka:9092`)
- `BACKEND_URL`: Backend API URL (default: `http://api:3000`)

**Express API:**
- `PORT`: API server port (default: `3000`)
- `NODE_ENV`: Node environment (default: `production`)

## Project Structure

```
openresty_intercept_request/
├── docker-compose.yml          # Docker Compose configuration
├── api/                        # Express backend
│   ├── Dockerfile
│   ├── package.json
│   └── index.js
├── openresty/                  # OpenResty configuration
│   ├── Dockerfile
│   ├── nginx.conf
│   └── lua/
│       ├── intercept_request.lua
│       └── handle_error.lua
└── README.md
```

## Troubleshooting

### Check service logs

```bash
# OpenResty logs
docker-compose logs -f openresty

# Kafka logs
docker-compose logs -f kafka

# API logs
docker-compose logs -f api
```

### Verify Kafka topics

```bash
docker-compose exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --list
```

### Check OpenResty configuration

```bash
docker-compose exec openresty cat /usr/local/openresty/nginx/conf/nginx.conf
```

## Cleanup

```bash
docker-compose down -v
```

## Use Cases

This pattern is useful for:

1. **Request Buffering**: Store requests when backend is temporarily unavailable
2. **Async Processing**: Queue requests for background processing
3. **Audit Trail**: Log all failed requests for analysis
4. **Retry Mechanism**: Consume from Kafka and retry failed requests
5. **Circuit Breaking**: Implement circuit breaker patterns with Kafka as buffer

## Next Steps

- Implement a Kafka consumer to retry failed requests
- Add authentication/authorization
- Implement request rate limiting
- Add metrics and monitoring (Prometheus/Grafana)
- Implement request deduplication
- Add multiple backend servers with load balancing

