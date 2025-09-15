FROM openresty/openresty:1.21.4.3-alpine

RUN apk add --no-cache ca-certificates bash curl \
    && update-ca-certificates

# Install required OpenResty packages (openidc + deps)
RUN /usr/local/openresty/bin/opm get \
      zmartzone/lua-resty-openidc \
      bungle/lua-resty-session \
      ledgetech/lua-resty-http

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]


