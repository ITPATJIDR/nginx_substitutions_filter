FROM openresty/openresty:1.25.3.2-0-alpine-fat

RUN mkdir -p /var/log/nginx /etc/nginx/conf.d

# Install dependencies including gettext for envsubst
RUN apk update && apk add --no-cache bash openssl-dev git gcc gettext

# Install lua-resty-openidc (much more robust than our custom implementation)
RUN luarocks install lua-resty-openidc

# Copy nginx template
COPY nginx.conf.template /etc/nginx/conf.d/nginx.conf.template

# Expose ports
EXPOSE 80 443

# Use environment substitution to generate config at runtime
CMD /bin/bash -c "envsubst < /etc/nginx/conf.d/nginx.conf.template > /etc/nginx/conf.d/default.conf && /usr/local/openresty/nginx/sbin/nginx -g 'daemon off;'"
