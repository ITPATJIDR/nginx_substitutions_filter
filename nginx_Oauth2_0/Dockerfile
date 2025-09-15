FROM openresty/openresty:1.25.3.2-0-alpine-fat

RUN mkdir -p /var/log/nginx /etc/nginx/conf.d

# Install dependencies including gettext for envsubst
RUN apk update && apk add --no-cache bash openssl-dev git gcc gettext curl unzip

# Install lua-resty-openidc directly from GitHub (bypass luarocks manifest issues)
RUN cd /tmp && \
    curl -L https://github.com/zmartzone/lua-resty-openidc/archive/refs/tags/v1.7.6.tar.gz -o lua-resty-openidc.tar.gz && \
    tar -xzf lua-resty-openidc.tar.gz && \
    cd lua-resty-openidc-1.7.6 && \
    cp -r lib/resty/* /usr/local/openresty/lualib/resty/ && \
    rm -rf /tmp/lua-resty-openidc*

# Install lua-resty-http (dependency for openidc)
RUN cd /tmp && \
    curl -L https://github.com/ledgetech/lua-resty-http/archive/refs/tags/v0.16.1.tar.gz -o lua-resty-http.tar.gz && \
    tar -xzf lua-resty-http.tar.gz && \
    cd lua-resty-http-0.16.1 && \
    cp -r lib/resty/* /usr/local/openresty/lualib/resty/ && \
    rm -rf /tmp/lua-resty-http*

# Install lua-resty-jwt (another dependency)
RUN cd /tmp && \
    curl -L https://github.com/SkyLothar/lua-resty-jwt/archive/refs/tags/v0.2.3.tar.gz -o lua-resty-jwt.tar.gz && \
    tar -xzf lua-resty-jwt.tar.gz && \
    cd lua-resty-jwt-0.2.3 && \
    cp -r lib/resty/* /usr/local/openresty/lualib/resty/ && \
    rm -rf /tmp/lua-resty-jwt*

# Install lua-resty-session (another dependency)
RUN cd /tmp && \
    curl -L https://github.com/bungle/lua-resty-session/archive/refs/tags/v4.0.5.tar.gz -o lua-resty-session.tar.gz && \
    tar -xzf lua-resty-session.tar.gz && \
    cd lua-resty-session-4.0.5 && \
    cp -r lib/resty/* /usr/local/openresty/lualib/resty/ && \
    rm -rf /tmp/lua-resty-session*

# Copy nginx template
COPY nginx.conf.template /etc/nginx/conf.d/nginx.conf.template

# Expose ports
EXPOSE 80 443

# Use environment substitution to generate config at runtime
CMD /bin/bash -c "envsubst < /etc/nginx/conf.d/nginx.conf.template > /etc/nginx/conf.d/default.conf && /usr/local/openresty/nginx/sbin/nginx -g 'daemon off;'"
