# OpenResty Keycloak Gateway with Express App

This setup provides an OpenResty-based API gateway that authenticates requests using Keycloak JWT tokens and forwards them to a simple Express application.

## Architecture

- **OpenResty Gateway** (Port 8000): Validates JWT tokens from Keycloak and adds user information to headers
- **Express App** (Port 3000): Simple backend application that receives and displays user information

## Prerequisites

- Docker and Docker Compose
- A running Keycloak instance (configured in nginx.conf)

## Configuration

The gateway is configured to work with Keycloak at `https://sso.keycloak.test` with:
- Client ID: `test`
- Realm: `test`

Update these values in `nginx.conf` if needed:

```lua
local keycloak_base_url = "https://sso.keycloak.test"
local client_id = "test"
local realm = "test"
```

## Quick Start

1. **Build and start the services:**
   ```bash
   docker-compose up --build
   ```

2. **Access the application:**
   - Gateway: http://localhost:8000
   - Direct app access: http://localhost:3000

## Testing

### Without Authentication (will fail)
```bash
curl http://localhost:8000/
```
Response: 401 Unauthorized

### With Valid JWT Token
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8000/
```

### Test Endpoints

The Express app provides several endpoints:

- `GET /` - Main endpoint with user information
- `GET /health` - Health check
- `GET /user` - User information only
- `GET /debug` - Debug information including all headers

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

## Production Considerations

- Set `ssl_verify = "yes"` in nginx.conf
- Use proper SSL certificates
- Configure proper logging
- Set up monitoring and health checks
- Use environment variables for configuration