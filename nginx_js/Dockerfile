# Use Ubuntu base for nginx with njs module
FROM ubuntu:20.04

# Install required packages
RUN apt-get update && \
    apt-get install -y wget gnupg ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Add nginx signing key
RUN wget http://nginx.org/keys/nginx_signing.key -O nginx_signing.key && \
    apt-key add nginx_signing.key && \
    rm nginx_signing.key

# Add nginx repository
RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ focal nginx" >> /etc/apt/sources.list

# Update and install nginx with njs module
RUN apt-get update && \
    apt-get install -y nginx nginx-module-njs && \
    rm -rf /var/lib/apt/lists/*

# Create njs directory
RUN mkdir -p /etc/nginx/njs

# Copy our custom configuration and JavaScript files
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY body_transform.js /etc/nginx/njs/body_transform.js

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]