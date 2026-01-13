FROM openresty/openresty:alpine

# Install dependencies
RUN apk add --no-cache gcc musl-dev luarocks

# Install xml2lua
RUN luarocks install xml2lua

# Copy configuration
COPY conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Copy Lua scripts
COPY lua/ /usr/local/openresty/nginx/lua/

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
