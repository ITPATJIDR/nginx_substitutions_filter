FROM openresty/openresty:1.21.4.3-alpine

RUN apk add --no-cache ca-certificates bash curl perl git unzip \
    && update-ca-certificates

# Install lua-resty-kafka for Kafka integration
RUN /usr/local/openresty/bin/opm get \
      doujiang24/lua-resty-kafka \
      ledgetech/lua-resty-http

# Copy nginx configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Copy Lua scripts
COPY lua/ /usr/local/openresty/nginx/lua/

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

