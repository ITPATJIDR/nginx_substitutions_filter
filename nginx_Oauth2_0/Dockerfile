FROM openresty/openresty:alpine

# Install required packages including luarocks
RUN apk add --no-cache curl luarocks

# Install Lua dependencies
RUN luarocks install lua-resty-http
RUN luarocks install lua-resty-jwt
RUN luarocks install lua-cjson

# Create directories
RUN mkdir -p /etc/nginx/lua
RUN mkdir -p /etc/nginx/conf.d

# Copy nginx configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# Copy Lua scripts
COPY lua/ /etc/nginx/lua/

# Create logs directory
RUN mkdir -p /var/log/nginx

# Expose ports
EXPOSE 80 443

# Start nginx
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
