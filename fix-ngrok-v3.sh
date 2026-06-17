#!/bin/bash
# Update ngrok service for v3
sudo sed -i "s|--hostname=|-domain=|g" /etc/systemd/system/ngrok.service
sudo systemctl daemon-reload
sudo systemctl restart ngrok
sleep 6
sudo systemctl status ngrok --no-pager | head -5
echo "---"
curl -s http://127.0.0.1:4040/api/tunnels | python3 -m json.tool 2>/dev/null | grep -E "public_url|proto" || echo "API not ready"
