FROM openresty/openresty:alpine

# Install dependencies for building Lua modules
RUN apk add --no-cache \
    bash \
    curl \
    git \
    build-base \
    openssl-dev \
    unzip

# Install required Lua modules using the built-in luarocks
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-openidc

# Create directories
RUN mkdir -p /etc/nginx/conf.d

# Copy nginx configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# Copy Lua scripts to the proper OpenResty location
COPY lua/ /usr/local/openresty/lualib/

# Create logs directory
RUN mkdir -p /var/log/nginx

# Expose ports
EXPOSE 80 443

# Start nginx
CMD ["openresty", "-g", "daemon off;"]
