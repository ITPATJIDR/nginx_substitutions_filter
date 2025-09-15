# OpenResty Keycloak Gateway with Express App

This setup provides an OpenResty-based API gateway that authenticates requests using Keycloak JWT tokens and forwards them to a simple Express application.

## Architecture

- **Keycloak** (Port 8080): Authentication server providing JWT tokens
- **OpenResty Gateway** (Port 8000): Validates JWT tokens from Keycloak and adds user information to headers
- **Express App** (Port 3000): Simple backend application that receives and displays user information

## Prerequisites

- Docker and Docker Compose

## Configuration

The setup includes a complete Keycloak instance with pre-configured:
- **Realm**: `test`
- **Client ID**: `test-client`
- **Client Secret**: `test-secret`
- **Test User**: `testuser` / `testpass`
- **Roles**: `user`, `admin`

The realm configuration is automatically imported from `keycloak-init/test-realm.json`.

## Quick Start

1. **Build and start the services:**
   ```bash
   docker-compose up --build
   # OR using the Makefile
   make start
   ```

2. **Wait for services to start** (Keycloak takes ~60 seconds):
   ```bash
   # Check if all services are healthy
   make health
   ```

3. **Get a JWT token:**
   ```bash
   make get-token
   ```

4. **Access the application:**
   - **Keycloak Admin**: http://localhost:8080 (admin/admin)
   - **Gateway**: http://localhost:8000 (requires JWT token)
   - **Direct app**: http://localhost:3000
   - **Gateway health**: http://localhost:8000/gateway-health (no auth required)
   - **App health**: http://localhost:8000/health (no auth required)

## Testing

### Without Authentication (will fail)
```bash
curl http://localhost:8000/
```
Response: 401 Unauthorized

### With Valid JWT Token
```bash
# Get token and test automatically
make test-auth

# Or manually:
# 1. Get token
make get-token

# 2. Use the token (replace YOUR_JWT_TOKEN with actual token)
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8000/
```

### Test Endpoints

The system provides several endpoints:

**Through Gateway (http://localhost:8000):**
- `GET /` - Main endpoint with user information (requires auth)
- `GET /health` - App health check (no auth required)
- `GET /user` - User information only (requires auth)
- `GET /debug` - Debug information including all headers (requires auth)
- `GET /gateway-health` - Gateway status (no auth required)

**Direct App Access (http://localhost:3000):**
- All endpoints available without authentication

## How It Works

1. Client sends request with `Authorization: Bearer JWT_TOKEN` header
2. OpenResty gateway validates the JWT token with Keycloak
3. Gateway extracts user information and encodes it as base64 JSON
4. Gateway forwards request to Express app with `X-Real-Name` header containing user info
5. Express app decodes the user information and processes the request

## User Information Format

The `X-Real-Name` header contains a base64-encoded JSON object with:

```json
{
  "uuid": "user-uuid",
  "username": "username",
  "email": "user@example.com",
  "first_name": "First",
  "last_name": "Last",
  "roles": ["ROLE_USER", "ROLE_ADMIN"]
}
```

## Development

### Local Development
```bash
# Start only the app for development
cd app
npm install
npm run dev
```

### Logs
```bash
# View gateway logs
docker-compose logs -f gateway

# View app logs
docker-compose logs -f app
```

### Rebuild Services
```bash
# Rebuild and restart
docker-compose up --build

# Rebuild specific service
docker-compose build gateway
docker-compose up gateway
```

## Troubleshooting

1. **401 Unauthorized**: Check JWT token validity and Keycloak configuration
2. **502 Bad Gateway**: Ensure the Express app is running and accessible
3. **SSL Verification**: The gateway is configured with `ssl_verify = "no"` for development
4. **Health Check Failures**: 
   - Use `/gateway-health` for Docker health checks (no auth required)
   - Use `/health` to check the backend app through the gateway (no auth required)
   - Regular endpoints like `/` still require JWT authentication

## Production Considerations

- Set `ssl_verify = "yes"` in nginx.conf
- Use proper SSL certificates
- Configure proper logging
- Set up monitoring and health checks
- Use environment variables for configuration