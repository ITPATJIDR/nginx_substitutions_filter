# Use nginx with njs module
FROM nginx:1.25-alpine

# Install njs module
RUN apk add --no-cache nginx-mod-http-js

# Copy our custom configuration and JavaScript files
COPY default.conf /etc/nginx/conf.d/default.conf
COPY body_transform.js /etc/nginx/body_transform.js

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]