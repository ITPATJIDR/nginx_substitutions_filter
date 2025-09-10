# Express.js + Nginx with Lua Body Transformation

This project demonstrates how to use Nginx with Lua scripting to transform both request and response bodies, with Express.js as the backend application. The setup transforms `username` to `name` in requests and back to `username` in responses.

## Project Structure

```
nginx-express-docker/
├── app/
│   ├── index.js          # Express.js application
│   └── package.json      # Node.js dependencies
├── nginx/
│   ├── Dockerfile        # Custom Nginx with Lua support (OpenResty)
│   ├── default.conf      # Nginx configuration with Lua scripting
│   └── body_transform.lua # Lua transformation logic
├── docker-compose.yml    # Docker Compose orchestration
├── Dockerfile           # Express app container
├── test_transformation.sh # Test script
└── README.md           # This file
```

## Features

- **Express.js Backend**: Simple REST API with JSON endpoints
- **Custom Nginx**: Built with Lua support using OpenResty
- **Request Body Transformation**: Transforms `username` to `name` before sending to Express
- **Response Body Transformation**: Transforms `name` back to `username` in responses
- **Docker Compose**: Easy orchestration of services
- **Bidirectional Transformation**: Full request/response body modification

## Quick Start

1. **Build and run the services:**
   ```bash
   docker-compose up --build
   ```

2. **Test the API:**
   ```bash
   # Run the comprehensive test script
   chmod +x test_transformation.sh
   ./test_transformation.sh
   
   # Or test individual endpoints:
   # Test POST endpoint with username (will be transformed to name)
   curl -X POST http://localhost:8080/api \
     -H "Content-Type: application/json" \
     -d '{"username":"World"}'
   
   # Test GET endpoint
   curl http://localhost:8080/api
   
   # Test health check
   curl http://localhost:8080/health
   ```

## Expected Results

### Request Transformation Flow:
1. **Client sends**: `{"username":"World"}`
2. **Nginx transforms to**: `{"name":"World"}` (before sending to Express)
3. **Express receives**: `{"name":"World"}` and responds with `{"message":"Hello, World","receivedField":"name","timestamp":"..."}`
4. **Nginx transforms response to**: `{"message":"Hello, World","receivedField":"username","timestamp":"..."}` (before sending to client)
5. **Client receives**: `{"message":"Hello, World","receivedField":"username","timestamp":"..."}`

### Key Transformations:
- **Request**: `username` → `name` (before reaching Express)
- **Response**: `name` → `username` (before reaching client)
- **Message text**: Any occurrence of "name" in message text becomes "username"

## Configuration Details

### Nginx Lua Configuration

The Nginx configuration uses Lua scripting:
- `access_by_lua_file /etc/nginx/lua/body_transform.lua` - Transforms request bodies
- `body_filter_by_lua_file /etc/nginx/lua/body_transform.lua` - Transforms response bodies
- `lua_need_request_body on` - Enables reading request body in Lua

### Lua Transformation Logic

The `body_transform.lua` script handles:
- **Request transformation**: Converts `username` field to `name` field
- **Response transformation**: Converts `name` field back to `username` field
- **Text replacement**: Replaces "name" with "username" in message text
- **Error handling**: Graceful handling of malformed JSON

### Ports

- **Nginx**: Exposed on port 8080 (host) → 80 (container)
- **Express**: Internal port 3000 (not exposed to host)

## Stopping the Services

```bash
docker-compose down
```

## Notes

- The Lua scripting enables both request and response body transformation
- This approach is more powerful than basic `sub_filter` as it allows complex JSON manipulation
- The setup includes gzip compression for better performance
- OpenResty (Nginx + Lua) is used for Lua scripting support
- Error handling ensures the service continues working even with malformed JSON
