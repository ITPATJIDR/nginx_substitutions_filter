# Use nginx with sub_filter support
FROM nginx:1.25-alpine

# Install additional modules if needed
RUN apk add --no-cache curl

# Copy our custom configuration
COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]