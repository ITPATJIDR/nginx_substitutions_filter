FROM openresty/openresty:alpine

# Install dependencies and lua-resty-kafka
RUN apk add --no-cache git perl && \
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

