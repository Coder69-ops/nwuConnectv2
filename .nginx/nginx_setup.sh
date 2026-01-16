#!/bin/bash
# NWU Connect NGINX & SSL Automated Setup
# Run this on your EC2 instance

sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

DOMAIN="api.nwuconnect.aixplore.me"

# Create NGINX Config
cat <<EOF | sudo tee /etc/nginx/sites-available/nwuconnect
server {
    listen 80;
    server_name $DOMAIN;

    # Backend API Proxy (Port 3000)
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Admin Panel Proxy (Port 3001)
    location / {
        proxy_pass http://localhost:3001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the config
sudo ln -sf /etc/nginx/sites-available/nwuconnect /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and Restart Nginx
sudo nginx -t && sudo systemctl restart nginx

echo "NGINX Setup Complete! Now getting SSL certificate..."

# Run Certbot for SSL (requires domain to be pointed to this IP already)
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m avijit@gmail.com --redirect

echo "HTTPS Setup Complete! 🚀"
echo "URL: https://$DOMAIN"
echo "API: https://$DOMAIN/api"
