#!/bin/bash
NGINX_ID=$(sudo docker ps --filter name=nginx -q | head -1)
cat /tmp/nginx-default.conf | sudo docker exec -i $NGINX_ID dd of=/etc/nginx/conf.d/default.conf 2>/dev/null
sudo docker exec $NGINX_ID nginx -t
sudo docker exec $NGINX_ID nginx -s reload
echo "Done"
sudo docker exec $NGINX_ID grep location /etc/nginx/conf.d/default.conf
