## OpenResty + Keycloak + Express API (docker-compose)

This stack secures an Express API behind OpenResty using Keycloak via lua-resty-openidc.

Services:
- Keycloak (realm import: `example` with client `openresty`, user `test/test123`)
- OpenResty gateway (OIDC auth, forwards to API)
- Express API (simple JSON endpoint)

### Quick start

Prereqs: Docker Desktop 4.24+, make optional.

1. Start stack:
   - `docker compose -f openresty_keycloak/docker-compose.yml up -d --build`
2. Browse `http://localhost:8080/api/hello` → you will be redirected to Keycloak on port 8081.
3. Login with `test / test123`.
4. You should receive JSON: `{ message: "Hello, test!", ... }`.

### Notes

- Based on patterns from:
  - Ed Hull: Securing Nginx with Keycloak [https://edhull.co.uk/blog/2018-06-06/keycloak-nginx]
  - Mohammed Aboullaite: Secure Kibana with Keycloak [https://aboullaite.me/secure-kibana-keycloak/]
  - EclipseSource: Authenticating reverse proxy with Keycloak [https://eclipsesource.com/blogs/2018/01/11/authenticating-reverse-proxy-with-keycloak/]

- The OpenResty config follows lua-resty-openidc best practices: discovery URL, confidential client, and shared dict caches.
- For production, enable TLS termination and set secure values for `SESSION_SECRET` and `OIDC_*`.


