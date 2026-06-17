#!/bin/bash
# Fix ngrok service with proper authtoken
TOKEN=$(grep authtoken ~/.config/ngrok/ngrok.yml | cut -d: -f2 | tr -d ' ')
sudo sed -i "s|ExecStart=.*|ExecStart=/usr/local/bin/ngrok http --hostname=cornfield-pointer-upcountry.ngrok-free.dev --authtoken=${TOKEN} 3001|" /etc/systemd/system/ngrok.service
sudo systemctl daemon-reload
sudo systemctl restart ngrok
sleep 8
curl -s http://127.0.0.1:4040/api/tunnels | python3 -m json.tool
