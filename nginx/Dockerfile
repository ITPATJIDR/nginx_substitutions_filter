# Use OpenResty which includes nginx with Lua module
FROM openresty/openresty:1.25.3.1-alpine

# Copy our custom configuration
COPY default.conf /usr/local/openresty/nginx/conf/conf.d/default.conf

EXPOSE 80

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]