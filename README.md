# Express.js + Nginx with HTTP Substitutions Filter

This project demonstrates how to use Nginx's **HTTP Substitutions Filter** module (`ngx_http_subs_filter_module`) to replace text in HTTP response bodies using regular expressions and fixed strings, with Express.js as the backend application.

## Project Structure

```
nginx-express-docker/
├── app/
│   ├── index.js          # Express.js application
│   └── package.json      # Node.js dependencies
├── nginx/
│   ├── Dockerfile        # Custom Nginx with subs_filter module
│   └── default.conf      # Nginx configuration with subs_filter
├── docker-compose.yml    # Docker Compose orchestration
├── Dockerfile           # Express app container
├── test.sh              # Test script for all endpoints
└── README.md           # This file
```

## Features

- **Express.js Backend**: REST API with multiple test endpoints
- **Custom Nginx**: Built with HTTP Substitutions Filter module (`ngx_http_subs_filter_module`)
- **Advanced Text Replacement**: 
  - Fixed string replacements
  - Regular expression support
  - Case-sensitive and case-insensitive options
  - Global replacement (all occurrences)
- **Docker Compose**: Easy orchestration of services
- **Response Filtering**: Nginx replaces "Hello" with "Hi" and "Express" with "Nginx-Express"

## Quick Start

1. **Build and run the services:**
   ```bash
   docker-compose up --build
   ```

2. **Test the API:**
   ```bash
   # Run the comprehensive test script
   chmod +x test.sh
   ./test.sh
   
   # Or test individual endpoints:
   curl -X POST http://localhost:8080/api \
     -H "Content-Type: application/json" \
     -d '{"name":"World"}'
   
   curl http://localhost:8080/api
   curl http://localhost:8080/test-regex
   curl http://localhost:8080/test-case
   curl http://localhost:8080/health
   ```

## Expected Results

- **Original Express response**: `{"message":"Hello, World"}`
- **Nginx filtered response**: `{"message":"Hi, World"}`

- **Original Express response**: `{"message":"Hello from Express!"}`
- **Nginx filtered response**: `{"message":"Hi from Nginx-Express!"}`

## Configuration Details

### HTTP Substitutions Filter Configuration

The Nginx configuration uses the advanced `subs_filter` directive:
- `subs_filter 'Hello' 'Hi' g` - Replaces "Hello" with "Hi" (global replacement)
- `subs_filter 'Express' 'Nginx-Express' g` - Replaces "Express" with "Nginx-Express" (global replacement)
- `subs_filter_types *` - Applies to all content types

### Available subs_filter Options

- `g` - Global replacement (all occurrences)
- `i` - Case-insensitive matching
- `r` - Regular expression mode
- `o` - Replace only the first occurrence

### Example Advanced Configurations

```nginx
# Case-insensitive replacement
subs_filter 'hello' 'hi' gi;

# Regular expression replacement (replace all numbers with X)
subs_filter '(\d+)' 'X' r;

# Replace only first occurrence
subs_filter 'Hello' 'Hi' o;
```

### Ports

- **Nginx**: Exposed on port 8080 (host) → 80 (container)
- **Express**: Internal port 3000 (not exposed to host)

## Stopping the Services

```bash
docker-compose down
```

## Notes

- The HTTP Substitutions Filter module (`ngx_http_subs_filter_module`) only works on response bodies, not request bodies
- For request body modification, consider using the Lua module or Express middleware
- The setup includes gzip compression for better performance
- The custom Nginx image is built from source to include the subs_filter module
- This module provides more advanced features than the basic `sub_filter` directive
