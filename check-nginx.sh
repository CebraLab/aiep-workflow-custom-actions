#!/bin/bash
# Check nginx config in Docker
NGINX_ID=$(sudo docker ps --filter name=nginx -q | head -1)
echo "Nginx container: $NGINX_ID"
echo "=== Config ==="
sudo docker exec $NGINX_ID cat /etc/nginx/conf.d/default.conf 2>/dev/null
echo "=== Sites ==="
sudo docker exec $NGINX_ID ls /etc/nginx/conf.d/ 2>/dev/null
