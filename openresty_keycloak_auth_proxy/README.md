## OpenResty + oauth2-proxy + Keycloak + Express API (docker-compose)

This example wires a simple Express API behind OpenResty (Nginx). Authentication is enforced via `auth_request` to `oauth2-proxy`, which delegates login to Keycloak (OIDC).

- OpenResty listens on http://localhost:8080
- Keycloak (dev) on http://localhost:8081
- oauth2-proxy runs internally, exposed via OpenResty at `/oauth2/*`

### Components
- Express API: `api/` with public and protected routes
- OpenResty: `openresty/nginx.conf` uses `auth_request` to oauth2-proxy
- oauth2-proxy: configured for Keycloak OIDC
- Keycloak: preloaded realm `example` with a test user and an `oauth2-proxy` confidential client

### Quick start
```bash
cd openresty_keycloak_auth_proxy
docker compose up -d --build
```

Wait ~10-20s for Keycloak to boot the first time.

### Test
- Public route (no auth):
  - http://localhost:8080/api/public/hello

- Protected route (triggers login):
  - http://localhost:8080/api/protected/hello
  - You will be redirected to oauth2-proxy sign-in and then to Keycloak

Keycloak credentials (dev):
- Username: `test`
- Password: `test123`

After login, the API receives headers set by oauth2-proxy (when `--set-xauthrequest` is enabled) such as `X-User` and `X-Email`.

### Notes
- `oauth2-proxy` is configured via env vars (see `docker-compose.yml`). Key flags reflect the docs:
  - `--reverse-proxy`
  - `--set-xauthrequest`
  - `--pass-access-token`
  - Provider: Keycloak OIDC with issuer URL of the realm
  - `--redirect-url=http://localhost:8080/oauth2/callback`
- Cookie secret must be base64-encoded and of correct length (example value included for local use only).

### References
- oauth2-proxy Nginx auth_request integration: https://oauth2-proxy.github.io/oauth2-proxy/configuration/integration
- oauth2-proxy Keycloak OIDC provider: https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/keycloak_oidc


