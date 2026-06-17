#!/bin/bash
NGINX_ID=$(sudo docker ps --filter name=nginx -q | head -1)

sudo tee /tmp/nginx-default.conf > /dev/null << 'ENDOFFILE'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;
    client_max_body_size 50M;

    location /socket.io/ {
        proxy_pass http://queue:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/v1/ {
        proxy_pass http://queue:3001/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # AIEP Custom Workflow Actions (NestJS)
    location /api/hubspot/ {
        proxy_pass http://172.18.0.1:3000/api/hubspot/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
    }

    location /api/docs {
        proxy_pass http://query-service:3002/api/docs;
        proxy_set_header Host $host;
    }
    location /api/docs-json {
        proxy_pass http://query-service:3002/api/docs-json;
        proxy_set_header Host $host;
    }

    location /colegios/ {
        proxy_pass http://query-service:3002/colegios/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /search {
        proxy_pass http://query-service:3002/search;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
ENDOFFILE

sudo docker cp /tmp/nginx-default.conf $NGINX_ID:/etc/nginx/conf.d/default.conf
sudo docker exec $NGINX_ID nginx -t && sudo docker exec $NGINX_ID nginx -s reload
echo "OK"
