## OpenResty + oauth2-proxy + Keycloak + Express API (docker-compose)

This stack secures an Express API behind OpenResty using `oauth2-proxy` as an auth proxy against Keycloak. Nginx uses `auth_request` to delegate authentication to `oauth2-proxy` and forwards identity headers to the API.

Services:
- Keycloak (realm import: `example` with client `openresty`, user `test/test123`)
- oauth2-proxy (Keycloak OIDC provider)
- OpenResty gateway (auth_request to oauth2-proxy, forwards to API)
- Express API (simple JSON endpoints)

### Quick start

Prereqs: Docker Desktop 4.24+, make optional.

1. Start stack:
   - `docker compose -f openresty_keycloak_auth_proxy/docker-compose.yml up -d --build`
2. Browse `http://localhost:8082/api/hello` → you will be redirected to Keycloak on port 8081.
3. Login with `test / test123`.
4. You should receive JSON: `{ message: "Hello, test!", ... }`.

### Implementation details

- Nginx exposes `/oauth2/*` to `oauth2-proxy` and protects `/api/protected/*` and `/api/hello` via `auth_request`.
- `oauth2-proxy` is configured with `keycloak-oidc` provider, issuer `http://keycloak:8080/realms/example`, client `openresty`.
- Identity headers exposed to upstream:
  - `X-User` from `X-Auth-Request-User`
  - `X-Email` from `X-Auth-Request-Email`
  - `X-Groups` from `X-Auth-Request-Groups`

### Notes

- For production, set a strong `OAUTH2_PROXY_COOKIE_SECRET`, enable TLS, and configure trusted `REDIRECT_URL` and hostnames.


