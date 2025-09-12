FROM openresty/openresty:alpine

# Install dependencies for building Lua modules
RUN apk add --no-cache \
    bash \
    curl \
    git \
    build-base \
    openssl-dev \
    unzip \
    wget \
    tar

# Install luarocks from source
RUN wget http://luarocks.org/releases/luarocks-2.0.13.tar.gz && \
    tar -xzvf luarocks-2.0.13.tar.gz && \
    cd luarocks-2.0.13/ && \
    ./configure --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit/ \
        --lua-suffix=jit \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 && \
    make && \
    make install && \
    cd .. && \
    rm -rf luarocks-2.0.13*

# Install required Lua modules
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
