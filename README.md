# Express.js + Nginx with HTTP Substitutions Filter

This project demonstrates how to use Nginx's `sub_filter` module to replace text in HTTP response bodies, with Express.js as the backend application.

## Project Structure

```
nginx-express-docker/
├── app/
│   ├── index.js          # Express.js application
│   └── package.json      # Node.js dependencies
├── nginx/
│   └── default.conf      # Nginx configuration with sub_filter
├── docker-compose.yml    # Docker Compose orchestration
├── Dockerfile           # Express app container
└── README.md           # This file
```

## Features

- **Express.js Backend**: Simple REST API with JSON endpoints
- **Nginx Proxy**: Acts as reverse proxy with text substitution
- **Docker Compose**: Easy orchestration of services
- **Response Filtering**: Nginx replaces "Hello" with "Hi" and "Express" with "Nginx-Express"

## Quick Start

1. **Build and run the services:**
   ```bash
   docker-compose up --build
   ```

2. **Test the API:**
   ```bash
   # Test POST endpoint
   curl -X POST http://localhost:8080/api \
     -H "Content-Type: application/json" \
     -d '{"name":"World"}'
   
   # Test GET endpoint
   curl http://localhost:8080/api
   
   # Test health check
   curl http://localhost:8080/health
   ```

## Expected Results

- **Original Express response**: `{"message":"Hello, World"}`
- **Nginx filtered response**: `{"message":"Hi, World"}`

- **Original Express response**: `{"message":"Hello from Express!"}`
- **Nginx filtered response**: `{"message":"Hi from Nginx-Express!"}`

## Configuration Details

### Nginx sub_filter Configuration

The Nginx configuration includes:
- `sub_filter 'Hello' 'Hi'` - Replaces "Hello" with "Hi"
- `sub_filter 'Express' 'Nginx-Express'` - Replaces "Express" with "Nginx-Express"
- `sub_filter_once off` - Replaces all occurrences, not just the first
- `sub_filter_types *` - Applies to all content types

### Ports

- **Nginx**: Exposed on port 8080 (host) → 80 (container)
- **Express**: Internal port 3000 (not exposed to host)

## Stopping the Services

```bash
docker-compose down
```

## Notes

- Nginx's `sub_filter` only works on response bodies, not request bodies
- For request body modification, consider using the Lua module or Express middleware
- The setup includes gzip compression for better performance
