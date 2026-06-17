#!/bin/bash
FILE=/home/ec2-user/aiep-integration-hub/nginx.conf
NGINX_ID=$(sudo docker ps --filter name=nginx -q | head -1)

if grep -q '/api/hubspot' $FILE; then
  echo "Route already exists, reloading..."
  sudo docker exec $NGINX_ID nginx -s reload
  exit 0
fi

# Backup
sudo cp $FILE /tmp/nginx.conf.bak

# Read existing file, find the SPA location, insert BEFORE it using awk
awk '
/^[[:space:]]*# SPA \(fallback/ {
    print "    # AIEP Custom Workflow Actions (NestJS)";
    print "    location /api/hubspot/ {";
    print "        proxy_pass http://172.18.0.1:3000/api/hubspot/;";
    print "        proxy_set_header Host $host;";
    print "        proxy_set_header X-Real-IP $remote_addr;";
    print "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;";
    print "        proxy_set_header X-Forwarded-Proto $scheme;";
    print "        proxy_read_timeout 30s;";
    print "    }";
    print "";
}
{ print }
' /tmp/nginx.conf.bak | sudo tee $FILE > /dev/null

echo "=== Updated ==="
grep -A6 'AIEP' $FILE

sudo docker exec $NGINX_ID nginx -t && sudo docker exec $NGINX_ID nginx -s reload
echo "Done"
