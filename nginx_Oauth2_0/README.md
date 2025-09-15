# Nginx OpenResty with Keycloak OAuth 2.0 Integration

This setup provides an nginx (OpenResty) reverse proxy with Keycloak OAuth 2.0 authentication for your Express.js API.

## Features

- **OAuth 2.0 Authentication**: Secure authentication using Keycloak
- **Token Validation**: Automatic token validation and user info extraction
- **Request/Response Transformation**: Transform request and response bodies
- **User Context**: Pass user information to your API
- **Session Management**: Cookie-based session management
- **Caching**: Token validation caching for better performance

## Architecture

```
Client → Nginx (OpenResty) → Keycloak (Auth) → Express App (API)
```

## Setup Instructions

### 1. Configure Keycloak

1. Start the services: `docker-compose up -d`
2. Access Keycloak admin console at `http://localhost:8080`
3. Login with admin/admin123
4. Create a new client:
   - Client ID: `nginx-client`
   - Client Protocol: `openid-connect`
   - Access Type: `confidential`
   - Valid Redirect URIs: `http://localhost/callback`
   - Web Origins: `http://localhost`

### 2. Update Configuration

1. Copy `env.example` to `.env`
2. Update the `KEYCLOAK_CLIENT_SECRET` with the secret from your Keycloak client
3. Adjust other settings as needed

### 3. Start Services

```bash
docker-compose up -d
```

## API Endpoints

- `GET /` - Home page (shows login or user info)
- `GET /login` - Redirects to Keycloak login
- `GET /callback` - OAuth callback handler
- `GET /logout` - Logout and clear session
- `GET /api/*` - Protected API endpoints (requires authentication)
- `GET /health` - Health check (public)

## Usage

1. Visit `http://localhost`
2. Click "Login with Keycloak"
3. Authenticate with Keycloak
4. Access protected API endpoints at `http://localhost/api`

## Request/Response Transformation

The nginx configuration automatically:
- Transforms `username` to `name` in request bodies
- Transforms `name` back to `username` in response bodies
- Adds user context (`user_id`, `user_email`, `user_name`) to requests
- Adds authentication status to responses

## Environment Variables

- `KEYCLOAK_URL`: Keycloak server URL
- `KEYCLOAK_REALM`: Keycloak realm name
- `KEYCLOAK_CLIENT_ID`: OAuth client ID
- `KEYCLOAK_CLIENT_SECRET`: OAuth client secret
- `APP_URL`: Backend application URL

## Security Features

- Token validation with Keycloak
- HttpOnly cookies for token storage
- CSRF protection via state parameter
- Request/response body sanitization
- User context injection
