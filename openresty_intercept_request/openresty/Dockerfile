FROM openresty/openresty:alpine

# Install lua-resty-kafka and dependencies
RUN apk add --no-cache git && \
    opm get doubaokun/lua-resty-kafka && \
    apk del git

# Copy nginx configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Create lua directory
RUN mkdir -p /usr/local/openresty/nginx/lua

# Copy lua scripts
COPY lua/ /usr/local/openresty/nginx/lua/

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

