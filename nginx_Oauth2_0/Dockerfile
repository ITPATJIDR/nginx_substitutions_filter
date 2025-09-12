FROM openresty/openresty:alpine

# Install required packages
RUN apk add --no-cache curl

# Install Lua dependencies
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-jwt
RUN /usr/local/openresty/luajit/bin/luarocks install lua-cjson

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
