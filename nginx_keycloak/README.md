# Nginx + Keycloak + Express Authentication Setup

This setup provides a complete authentication system using nginx as a reverse proxy with Keycloak for JWT token validation and a simple Express application as the backend.

## Architecture

- **PostgreSQL**: Database for Keycloak (internal)
- **Keycloak** (Port 8080): Authentication server providing JWT tokens
- **nginx** (Port 8000): Reverse proxy with JWT authentication
- **Express App** (Port 3000): Backend application (internal)

## Features

### nginx Gateway
- JWT token validation with Keycloak
- Rate limiting on API endpoints
- Security headers
- Error handling with JSON responses
- Health check endpoints

### Authentication Levels
- **Public routes** (`/`): Accessible without authentication
- **API routes** (`/api/*`): Require valid JWT token
- **Admin routes** (`/admin`): Require JWT token with admin role

### Express Application
- Multiple endpoints with different authentication requirements
- User information extraction from nginx headers
- Role-based access control
- Comprehensive logging

## Prerequisites

- Docker and Docker Compose

## Quick Start

1. **Start all services:**
   ```bash
   cd nginx_keycloak
   make start
   ```

2. **Wait for services to start** (90-120 seconds for Keycloak):
   ```bash
   # Check service health
   make health
   
   # Watch Keycloak startup logs
   make keycloak-logs
   ```

3. **Get a JWT token:**
   ```bash
   # For regular user
   make get-token
   
   # For admin user
   make get-admin-token
   ```

4. **Test the setup:**
   ```bash
   make test
   ```

## Service URLs

- **nginx Gateway**: http://localhost:8000
- **Keycloak Admin**: http://localhost:8080 (admin/admin)
- **Express App** (direct): http://localhost:3000

## Available Endpoints

### Through nginx Gateway (http://localhost:8000)

#### Public Endpoints (No Authentication)
- `GET /` - Main application endpoint
- `GET /health` - nginx health check
- `GET /nginx-status` - nginx status

#### Protected Endpoints (Require JWT Token)
- `GET /api/data` - API endpoint returning sample data
- `GET /user` - User information endpoint
- `GET /debug` - Debug information with all headers

#### Admin Endpoints (Require Admin Role)
- `GET /admin` - Admin-only endpoint

### Authentication Headers

When authenticated, nginx passes user information to the backend via headers:
- `X-User-Info` - Base64 encoded user information
- `X-User-Email` - User email
- `X-User-Name` - User display name  
- `X-User-Roles` - Comma-separated list of roles

## Test Users

The setup includes pre-configured test users:

| Username | Password | Roles | Description |
|----------|----------|-------|-------------|
| testuser | testpass | user | Regular user |
| admin | adminpass | user, admin | Administrator |

## Testing Examples

### 1. Test Public Endpoint
```bash
curl http://localhost:8000/
```

### 2. Test Protected Endpoint (will fail without token)
```bash
curl http://localhost:8000/api/data
# Returns: 401 Unauthorized
```

### 3. Get JWT Token and Test
```bash
# Get token for regular user
make get-token

# Use the token (replace TOKEN with actual token)
curl -H "Authorization: Bearer TOKEN" http://localhost:8000/api/data
```

### 4. Test Admin Access
```bash
# Get admin token
make get-admin-token

# Test admin endpoint
curl -H "Authorization: Bearer ADMIN_TOKEN" http://localhost:8000/admin
```

## Management Commands

```bash
# Service management
make start          # Build and start all services
make stop           # Stop all services
make restart        # Restart all services
make clean          # Stop and remove volumes
make status         # Show service status

# Logging
make logs           # Follow all logs
make nginx-logs     # nginx logs only
make keycloak-logs  # Keycloak logs only
make app-logs       # Express app logs only

# Testing
make test           # Run complete test suite
make test-auth      # Test user authentication
make test-admin     # Test admin authentication
make health         # Check all service health

# Tokens
make get-token      # Get token for testuser
make get-admin-token # Get token for admin user

# Information
make urls           # Show all service URLs
make keycloak-admin # Show Keycloak admin info
make help           # Show all commands
```

## Configuration

### Keycloak Configuration
- **Realm**: `test`
- **Client ID**: `nginx-gateway`
- **Client Secret**: `nginx-secret`

The realm configuration is automatically imported from `keycloak-init/test-realm.json`.

### nginx Configuration
The nginx configuration includes:
- JWT validation using Keycloak's userinfo endpoint
- Rate limiting (10 req/s for API, 1 req/s for login)
- Security headers
- Custom error pages with JSON responses

### Express App Configuration
The Express app:
- Extracts user information from nginx headers
- Provides role-based access control
- Logs all requests with headers
- Returns JSON responses

## Development

### Adding New Users
1. Access Keycloak admin console: http://localhost:8080
2. Login with admin/admin
3. Go to Users → Add user
4. Set password in Credentials tab
5. Assign roles in Role Mappings tab

### Adding New Endpoints
1. Add route to Express app (`app/index.js`)
2. Configure nginx location block if needed (`nginx/conf.d/default.conf`)
3. Update authentication requirements as needed

### Customizing Authentication
- Modify `nginx/conf.d/default.conf` for different auth requirements
- Update Keycloak realm configuration in `keycloak-init/test-realm.json`
- Adjust Express app user extraction logic in `app/index.js`

## Troubleshooting

### Common Issues

1. **Services not starting**: Check Docker resources and ports
   ```bash
   make status
   make logs
   ```

2. **Keycloak not ready**: Keycloak takes 60-90 seconds to start
   ```bash
   make keycloak-logs
   make health
   ```

3. **JWT token errors**: Verify Keycloak is running and realm is imported
   ```bash
   curl http://localhost:8080/health/ready
   ```

4. **nginx authentication errors**: Check nginx configuration and Keycloak connectivity
   ```bash
   make nginx-logs
   ```

### Reset Everything
```bash
make force-clean
make start
```

### Check Service Health
```bash
make health
```

## Security Considerations

### Development vs Production

This setup is configured for development. For production:

1. **Change default passwords**
2. **Use proper SSL certificates**
3. **Configure proper CORS policies**
4. **Set up proper logging and monitoring**
5. **Use environment variables for secrets**
6. **Configure proper network segmentation**

### Rate Limiting

nginx includes rate limiting:
- API endpoints: 10 requests/second
- Login endpoints: 1 request/second

Adjust in `nginx/conf.d/default.conf` as needed.

## License

MIT License
