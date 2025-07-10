# Use a lightweight Nginx image to serve static files
FROM nginx:stable-alpine

# Copy your static files into the Nginx public directory
COPY . /usr/share/nginx/html

# Expose port 80 (default for HTTP)
EXPOSE 80

# Command to run Nginx (default in base image)
CMD ["nginx", "-g", "daemon off;"]