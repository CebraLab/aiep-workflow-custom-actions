#!/bin/bash
SRC=/tmp/nginx-default.conf
DST=/home/ec2-user/aiep-integration-hub/nginx.conf
NGINX_ID=$(sudo docker ps --filter name=nginx -q | head -1)

echo "Source has hubspot: $(grep -c hubspot $SRC)"
sudo cp $SRC $DST
echo "Destination has hubspot: $(grep -c hubspot $DST)"
sudo docker exec $NGINX_ID nginx -t
sudo docker exec $NGINX_ID nginx -s reload
echo "Done. Routes:"
grep location $DST
