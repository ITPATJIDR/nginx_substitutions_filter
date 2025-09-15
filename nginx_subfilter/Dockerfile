# Use nginx with sub_filter support (without headers-more module)
FROM nginx:1.25-alpine

# Copy our custom configuration
COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]