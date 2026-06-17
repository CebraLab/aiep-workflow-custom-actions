#!/bin/bash
NGINX_ID=$(sudo docker ps --filter name=nginx -q | head -1)
sudo docker cp $NGINX_ID:/etc/nginx/conf.d/default.conf /tmp/nginx-default.conf.bak

if grep -q '/api/hubspot' /tmp/nginx-default.conf.bak; then
  echo "Route already exists, reloading..."
  sudo docker cp /tmp/nginx-default.conf.bak $NGINX_ID:/etc/nginx/conf.d/default.conf
  sudo docker exec $NGINX_ID nginx -t && sudo docker exec $NGINX_ID nginx -s reload
  echo "Done"
  exit 0
fi

# Insert new location block before SPA fallback
sed -i '/# SPA (fallback/i\
    # AIEP Custom Workflow Actions (NestJS)\
    location /api/hubspot/ {\
        proxy_pass http://172.18.0.1:3000/api/hubspot/;\
        proxy_set_header Host \$host;\
        proxy_set_header X-Real-IP \$remote_addr;\
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto \$scheme;\
        proxy_read_timeout 30s;\
    }\
' /tmp/nginx-default.conf.bak

sudo docker cp /tmp/nginx-default.conf.bak $NGINX_ID:/etc/nginx/conf.d/default.conf
sudo docker exec $NGINX_ID nginx -t && sudo docker exec $NGINX_ID nginx -s reload
echo "Nginx reloaded with /api/hubspot route"
