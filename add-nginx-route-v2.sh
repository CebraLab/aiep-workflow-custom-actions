#!/bin/bash
NGINX_ID=$(sudo docker ps --filter name=nginx -q | head -1)

# Check if route already exists
if sudo docker exec $NGINX_ID grep -q '/api/hubspot' /etc/nginx/conf.d/default.conf 2>/dev/null; then
  echo "Route already exists"
  exit 0
fi

# Read current config, insert route before SPA fallback, write back
sudo docker exec $NGINX_ID sh -c "sed -i '/# SPA (fallback/i\\
    # AIEP Custom Workflow Actions (NestJS)\\
    location /api/hubspot/ {\\
        proxy_pass http://172.18.0.1:3000/api/hubspot/;\\
        proxy_set_header Host \\\$host;\\
        proxy_set_header X-Real-IP \\\$remote_addr;\\
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;\\
        proxy_set_header X-Forwarded-Proto \\\$scheme;\\
        proxy_read_timeout 30s;\\
    }\\
' /etc/nginx/conf.d/default.conf"

# Test and reload
sudo docker exec $NGINX_ID nginx -t && sudo docker exec $NGINX_ID nginx -s reload
echo "=== Updated routes ==="
sudo docker exec $NGINX_ID grep 'location' /etc/nginx/conf.d/default.conf
