# Nginx + Express + Keycloak Setup

This project provides a complete Docker Compose setup with Nginx reverse proxy, Express.js application, and Keycloak authentication.

## Architecture

```
Client → Nginx (Reverse Proxy) → Express App
                ↓
            Keycloak (Authentication)
```

## Features

- **Nginx Reverse Proxy**: Load balancing and SSL termination ready
- **Express.js API**: Simple REST API with authentication middleware
- **Keycloak Integration**: OAuth 2.0 / OpenID Connect authentication
- **Session Management**: Secure session handling with Express sessions
- **Health Checks**: Built-in health monitoring for all services
- **Rate Limiting**: Protection against abuse and DDoS
- **Security Headers**: OWASP recommended security headers

## Quick Start

### 1. Clone and Setup

```bash
cd nginx_keycloak
cp app/env.example app/.env
```

### 2. Start Services

```bash
# Using Docker Compose
docker-compose up -d

# Or using Makefile
make up
```

### 3. Configure Keycloak

1. Access Keycloak admin console: http://localhost:8080
2. Login with credentials: `admin` / `admin123`
3. Create a new client:
   - **Client ID**: `nginx-client`
   - **Client Protocol**: `openid-connect`
   - **Access Type**: `confidential`
   - **Valid Redirect URIs**: `http://localhost/callback`
   - **Web Origins**: `http://localhost`
4. Go to the **Credentials** tab and copy the client secret
5. Update the `KEYCLOAK_CLIENT_SECRET` in your `.env` file
6. Restart services: `docker-compose restart`

### 4. Test the Application

Visit http://localhost and you should see:
- Welcome page with login option
- Login redirects to Keycloak
- After authentication, access to protected API endpoints

## API Endpoints

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/` | GET | No | Home page with user info |
| `/health` | GET | No | Health check |
| `/login` | GET | No | Redirect to Keycloak login |
| `/callback` | GET | No | OAuth callback handler |
| `/logout` | GET | No | Logout and clear session |
| `/api` | GET | Yes | API overview |
| `/api/profile` | GET | Yes | User profile information |
| `/api/data` | GET | Yes | Sample data endpoint |
| `/api/data` | POST | Yes | Create data endpoint |

## Environment Variables

### Express App (`.env`)

```env
# Express Configuration
PORT=3000
NODE_ENV=production
SESSION_SECRET=your-secure-session-secret

# Keycloak Configuration
KEYCLOAK_URL=http://keycloak:8080
KEYCLOAK_REALM=master
KEYCLOAK_CLIENT_ID=nginx-client
KEYCLOAK_CLIENT_SECRET=your-client-secret-from-keycloak

# OAuth Configuration
REDIRECT_URI=http://localhost/callback
```

## Services

### Nginx (Port 80)
- Reverse proxy for Express app
- Proxies Keycloak authentication endpoints
- Rate limiting and security headers
- Health checks and error handling

### Express App (Port 3000)
- Node.js/Express.js application
- OAuth 2.0 integration with Keycloak
- Session-based authentication
- REST API endpoints

### Keycloak (Port 8080)
- Identity and access management
- OAuth 2.0 / OpenID Connect provider
- User management and authentication

## Development

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f nginx
docker-compose logs -f keycloak
```

### Rebuild Services
```bash
# Rebuild all
docker-compose build

# Rebuild specific service
docker-compose build app
```

### Access Containers
```bash
# Express app
docker-compose exec app sh

# Nginx
docker-compose exec nginx sh

# Keycloak
docker-compose exec keycloak bash
```

## Troubleshooting

### Common Issues

1. **Keycloak not ready**: Wait 30-60 seconds for Keycloak to fully start
2. **Client secret error**: Ensure you've updated the `.env` file with the correct client secret from Keycloak
3. **Redirect URI mismatch**: Check that the redirect URI in Keycloak matches `http://localhost/callback`
4. **Network issues**: Ensure no other services are running on ports 80, 3000, or 8080

### Health Checks

```bash
# Check all services
make status

# Individual health checks
curl http://localhost/health
curl http://localhost:3000/health
curl http://localhost:8080/health/ready
```

### Reset Everything

```bash
# Stop and remove all containers, networks, and volumes
make clean

# Start fresh
make up
```

## Security Considerations

- Change default Keycloak admin credentials in production
- Use strong session secrets
- Enable HTTPS in production
- Configure proper CORS settings
- Set up proper Keycloak realm and users
- Use environment-specific client secrets

## Production Deployment

For production deployment:

1. Use HTTPS/TLS certificates
2. Set up proper environment variables
3. Configure Keycloak with a database (PostgreSQL/MySQL)
4. Set up proper networking and firewall rules
5. Use Docker secrets for sensitive data
6. Configure monitoring and logging
7. Set up backup strategies

## Makefile Commands

```bash
make help          # Show available commands
make build         # Build all Docker images
make up           # Start all services
make down         # Stop all services
make logs         # Show logs for all services
make clean        # Clean up containers and volumes
make restart      # Restart all services
make status       # Show status of all services
make keycloak-setup # Show Keycloak setup instructions
```
