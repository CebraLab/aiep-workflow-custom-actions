#!/bin/bash
FILE=/home/ec2-user/aiep-integration-hub/nginx.conf
NGINX_ID=$(sudo docker ps --filter name=nginx -q | head -1)

sudo python3 << 'PYEOF'
content = open("/home/ec2-user/aiep-integration-hub/nginx.conf").read()

if "/api/hubspot/" in content:
    print("Route already exists")
else:
    new_location = (
        "    # AIEP Custom Workflow Actions (NestJS)\n"
        "    location /api/hubspot/ {\n"
        "        proxy_pass http://172.18.0.1:3000/api/hubspot/;\n"
        "        proxy_set_header Host $host;\n"
        "        proxy_set_header X-Real-IP $remote_addr;\n"
        "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n"
        "        proxy_set_header X-Forwarded-Proto $scheme;\n"
        "        proxy_read_timeout 30s;\n"
        "    }\n\n"
    )
    content = content.replace("    location / {", new_location + "    location / {")
    open("/tmp/nginx-updated.conf", "w").write(content)
    print("Route added, hubspot count:", content.count("hubspot"))
PYEOF

sudo cp /tmp/nginx-updated.conf $FILE
sudo docker exec $NGINX_ID nginx -t && sudo docker exec $NGINX_ID nginx -s reload
echo "Reloaded. Routes:"
grep location $FILE
