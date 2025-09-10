# Use OpenResty which includes nginx with Lua module
FROM openresty/openresty:1.25.3.1-alpine

# Copy our custom configuration and Lua script
COPY default.conf /usr/local/openresty/nginx/conf/conf.d/default.conf
COPY body_transform.lua /usr/local/openresty/nginx/conf/body_transform.lua

EXPOSE 80

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]