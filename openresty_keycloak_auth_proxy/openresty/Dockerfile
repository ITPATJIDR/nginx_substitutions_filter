FROM openresty/openresty:1.21.4.3-alpine

RUN apk add --no-cache ca-certificates bash curl && update-ca-certificates

# No lua-resty-openidc needed when using oauth2-proxy

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]


