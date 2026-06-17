#!/bin/bash
# Replace ngrok service with multi-endpoint config

sudo systemctl stop ngrok

cat > /tmp/ngrok-multi.yml << 'YAML'
version: '3'
agent:
  authtoken: 3Ev0jHgyPlWH4DRpN9d6625IQAV_2Uws4rCFDC4ho22Qe4WiA
endpoints:
  - name: queue
    url: cornfield-pointer-upcountry.ngrok-free.dev
    upstream:
      url: 3001
  - name: aiep
    upstream:
      url: 3000
YAML

sudo tee /etc/systemd/system/ngrok.service << 'UNIT'
[Unit]
Description=ngrok tunnels (queue + AIEP backend)
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/usr/local/bin/ngrok start --all --config /tmp/ngrok-multi.yml --api-addr 0.0.0.0:4040
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl start ngrok
sleep 12
echo "=== TUNNELS ==="
curl -s http://127.0.0.1:4040/api/tunnels | python3 -m json.tool 2>/dev/null | grep -E '"name"|"public_url"|"addr"'
