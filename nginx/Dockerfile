# Use OpenResty which includes nginx with Lua and JavaScript modules
FROM openresty/openresty:1.25.3.1-alpine

# Copy our custom configuration
COPY default.conf /usr/local/openresty/nginx/conf/conf.d/default.conf
COPY body_transform.js /usr/local/openresty/nginx/conf/body_transform.js

EXPOSE 80

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]