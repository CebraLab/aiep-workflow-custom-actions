#!/bin/bash
# Fix 1: ngrok - prevent systemd from giving up on restarts
echo "=== Fix 1: ngrok infinite restart ==="
sudo mkdir -p /etc/systemd/system/ngrok.service.d
sudo tee /etc/systemd/system/ngrok.service.d/override.conf << 'EOF'
[Unit]
StartLimitIntervalSec=0
StartLimitBurst=0

[Service]
RestartSec=10
Restart=always
EOF
sudo systemctl daemon-reload
sudo systemctl restart ngrok
echo "ngrok override applied"

# Fix 2: nginx - auto-restore /api/hubspot route if missing
echo "=== Fix 2: nginx route persistence ==="
sudo tee /opt/aiep-actions/ensure-nginx-route.sh << 'SCRIPT'
#!/bin/bash
FILE=/home/ec2-user/aiep-integration-hub/nginx.conf
NGINX_ID=$(docker ps --filter name=nginx -q | head -1)

if [ -z "$NGINX_ID" ]; then
  exit 0
fi

if grep -q '/api/hubspot/' $FILE; then
  exit 0
fi

python3 << 'PYEOF'
content = open("/home/ec2-user/aiep-integration-hub/nginx.conf").read()
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
PYEOF

sudo cp /tmp/nginx-updated.conf $FILE
docker exec $NGINX_ID nginx -t 2>/dev/null && docker exec $NGINX_ID nginx -s reload 2>/dev/null
echo "$(date): /api/hubspot/ route restored" >> /tmp/nginx-fix.log
SCRIPT
sudo chmod +x /opt/aiep-actions/ensure-nginx-route.sh

# Create systemd timer to check every minute
sudo tee /etc/systemd/system/ensure-nginx-route.service << 'EOF'
[Unit]
Description=Ensure /api/hubspot route exists in nginx

[Service]
Type=oneshot
User=root
ExecStart=/opt/aiep-actions/ensure-nginx-route.sh
EOF

sudo tee /etc/systemd/system/ensure-nginx-route.timer << 'EOF'
[Unit]
Description=Check nginx route every 60s

[Timer]
OnBootSec=30
OnUnitActiveSec=60
AccuracySec=5

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ensure-nginx-route.timer
echo "nginx watchdog timer enabled"

echo "=== Done ==="
