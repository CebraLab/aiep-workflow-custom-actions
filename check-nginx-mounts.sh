#!/bin/bash
NGINX_ID=$(sudo docker ps --filter name=nginx -q | head -1)
sudo docker inspect $NGINX_ID | python3 -c "import sys,json; c=json.load(sys.stdin)[0]; [print(m['Source'], '->', m['Destination']) for m in c['Mounts']]"
