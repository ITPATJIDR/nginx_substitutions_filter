# OpenResty with Kafka Interceptor

This project demonstrates how to use OpenResty with Lua to intercept failed backend requests and send them to Kafka for processing/analysis.

## Architecture

- **Express API**: Simple Node.js backend that sometimes fails (for testing)
- **OpenResty**: Nginx-based reverse proxy with Lua scripting
- **Kafka + Zookeeper**: Message broker for collecting failed requests
- **Lua Scripts**:
  - `kafka_logger.lua`: Logs all failed responses (4xx, 5xx) to Kafka
  - `error_handler.lua`: Intercepts backend connection failures and sends to Kafka

## Features

- Intercepts requests that can't reach the backend (502, 503, 504 errors)
- Logs all failed responses (4xx, 5xx status codes) to Kafka
- Captures full request details including headers, body, and metadata
- Asynchronous Kafka producer for minimal performance impact
- Graceful error handling with user-friendly responses

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. **Build and start all services:**
   ```bash
   make up
   # or
   docker-compose up -d
   ```

2. **Check logs:**
   ```bash
   make logs
   # or
   docker-compose logs -f
   ```

3. **Test the API:**
   ```bash
   # Health check
   curl http://localhost:8082/health

   # Successful request
   curl http://localhost:8082/api/status

   # Random endpoint (30% failure rate)
   curl http://localhost:8082/api/random

   # Test backend unavailability (stop backend first)
   docker-compose stop api
   curl http://localhost:8082/api/status
   docker-compose start api
   ```

## Kafka Consumer Test

To view messages in Kafka:

```bash
# Connect to Kafka container
docker-compose exec kafka bash

# Consume messages from the failed-requests topic
kafka-console-consumer --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning \
  --property print.timestamp=true
```

## Message Format

Failed requests are sent to Kafka with the following structure:

```json
{
  "timestamp": 1697845200,
  "iso_timestamp": "2024-10-20T12:00:00Z",
  "error_type": "backend_unavailable",
  "client_ip": "172.18.0.1",
  "request_method": "GET",
  "request_uri": "/api/status",
  "request_path": "/api/status",
  "query_string": null,
  "request_body": null,
  "user_agent": "curl/7.81.0",
  "referer": null,
  "upstream_addr": "172.18.0.2:3000",
  "server_name": "_",
  "log_type": "backend_error",
  "request_headers": {
    "host": "localhost:8082",
    "user-agent": "curl/7.81.0"
  }
}
```

## Configuration

Environment variables can be modified in `docker-compose.yml`:

- `KAFKA_BROKERS`: Kafka broker addresses (default: `kafka:9092`)
- `KAFKA_TOPIC`: Topic name for failed requests (default: `failed-requests`)

## Cleanup

```bash
make clean
# or
docker-compose down -v
```

## Development

To rebuild after code changes:

```bash
make rebuild
# or
docker-compose build --no-cache
docker-compose up -d
```

## Project Structure

```
.
├── api/                    # Express backend
│   ├── src/
│   │   └── index.js       # API implementation
│   ├── Dockerfile
│   └── package.json
├── openresty/             # OpenResty configuration
│   ├── lua/
│   │   ├── kafka_logger.lua      # Logs failed responses
│   │   └── error_handler.lua     # Handles backend errors
│   ├── Dockerfile
│   └── nginx.conf
├── docker-compose.yml
├── Makefile
└── README.md
```

## Troubleshooting

1. **Kafka connection issues**: Make sure all services are running with `docker-compose ps`
2. **Backend connection errors**: Check API logs with `docker-compose logs api`
3. **Lua script errors**: Check OpenResty logs with `docker-compose logs openresty`

## Next Steps

- Add authentication/authorization
- Implement request retry logic
- Add metrics and monitoring
- Create a consumer service to process failed requests from Kafka
- Add dead letter queue for persistent failures

