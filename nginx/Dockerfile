FROM nginx:1.25-alpine

# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    libc-dev \
    make \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    libxslt-dev \
    gd-dev \
    geoip-dev

# Download and build nginx with js module
RUN cd /tmp && \
    curl -L -O http://nginx.org/download/nginx-1.25.3.tar.gz && \
    curl -L -O https://github.com/openresty/njs/archive/0.8.2.tar.gz && \
    tar -xzf nginx-1.25.3.tar.gz && \
    tar -xzf 0.8.2.tar.gz && \
    cd nginx-1.25.3 && \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-http_geoip_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-http_xslt_module=dynamic \
        --add-module=../njs-0.8.2/nginx && \
    make && make install && \
    cd / && \
    rm -rf /tmp/nginx-1.25.3* /tmp/njs-0.8.2* && \
    apk del .build-deps

# Copy our custom configuration
COPY default.conf /etc/nginx/conf.d/default.conf
COPY body_transform.js /etc/nginx/body_transform.js

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]