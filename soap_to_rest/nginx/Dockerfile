FROM openresty/openresty:latest

# Install dependencies (using apt-get for Debian-based image)
RUN apt-get update && apt-get install -y \
    luarocks \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install xml2lua
RUN luarocks install xml2lua

# Copy configuration
COPY conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Copy Lua scripts
COPY lua/ /usr/local/openresty/nginx/lua/

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

