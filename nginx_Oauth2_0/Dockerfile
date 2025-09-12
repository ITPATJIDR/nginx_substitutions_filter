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
    tar \
    readline-dev

# Install luarocks from source (latest version 3.12.2)
RUN wget https://luarocks.github.io/luarocks/releases/luarocks-3.12.2.tar.gz && \
    tar -xzvf luarocks-3.12.2.tar.gz && \
    cd luarocks-3.12.2/ && \
    ./configure --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit/ \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
        --with-lua-lib=/usr/local/openresty/luajit/lib \
        --with-lua-interpreter=luajit && \
    make && \
    make install && \
    cd .. && \
    rm -rf luarocks-3.12.2*

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
