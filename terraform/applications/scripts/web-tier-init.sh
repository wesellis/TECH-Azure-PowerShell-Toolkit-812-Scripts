#!/bin/bash
# Web Tier Initialization Script

# Update system
apt-get update
apt-get install -y nginx curl

# Configure nginx
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Proxy to app tier
    location / {
        proxy_pass http://${app_lb_ip}:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Create simple health page
cat > /var/www/html/health << 'EOF'
healthy
EOF

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Configure logging
echo "Web tier initialized on $(hostname) at $(date)" >> /var/log/web-tier-init.log