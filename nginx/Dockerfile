# Use nginx with Lua support
FROM openresty/openresty:alpine

# Install additional Lua modules for JSON handling
RUN apk add --no-cache lua-json4

# Copy our custom configuration and Lua scripts
COPY default.conf /etc/nginx/conf.d/default.conf
COPY body_transform.lua /etc/nginx/lua/body_transform.lua
COPY response_transform.lua /etc/nginx/lua/response_transform.lua

# Create lua directory
RUN mkdir -p /etc/nginx/lua

EXPOSE 80

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]