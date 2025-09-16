## OpenResty + OAuth2-Proxy + Keycloak + Express API (docker-compose)

Reverse-proxy stack where OpenResty protects routes via `auth_request` to `oauth2-proxy`, which authenticates users against Keycloak (OIDC). On success, JWT tokens are passed to the Express API for verification.

### What runs where
- OpenResty: http://localhost
- Keycloak: http://localhost:8080 (realm `myrealm`)
- OAuth2-Proxy: http://localhost:4180 (only for callback and debugging)
- Express API: http://localhost:3000 (behind OpenResty)

### Files
- `docker-compose.yml` – defines services
- `keycloak-realm.json` – imports realm `myrealm` and client `oauth2-proxy-client`
- `openresty/nginx.conf` – Nginx with `auth_request` integration
- `api/` – simple Express API

### Setup
1) Create `.env` in this folder with:
```
OAUTH2_PROXY_CLIENT_SECRET=<Keycloak client secret for oauth2-proxy-client>
OAUTH2_PROXY_COOKIE_SECRET=<base64 32-byte secret>
```

2) Start the stack:
```bash
docker compose up -d --build
```

Wait for Keycloak health to pass (compose waits on it).

### Test the flow
1) Open http://localhost in a browser.
2) You’ll be redirected to OAuth2-Proxy/Keycloak login.
3) Use the dev user from `keycloak-realm.json`:
   - username: `testuser`
   - password: `password`
4) After login, you’ll be redirected back to the Express API via OpenResty.

### Notes
- Ensure the Keycloak client `oauth2-proxy-client` secret matches both `.env` and `keycloak-realm.json`.
- `OAUTH2_PROXY_COOKIE_SECRET` must be base64-encoded 32 bytes (e.g. `openssl rand -base64 32`).
- OpenResty forwards JWT tokens via `Authorization: Bearer` and `X-Access-Token` headers.
- Express API verifies JWT tokens using Keycloak's public keys.
- Protected endpoints use JWT verification instead of cookie-based auth.

### References
- oauth2-proxy integration: https://oauth2-proxy.github.io/oauth2-proxy/configuration/integration
- Keycloak OIDC provider: https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/keycloak_oidc
