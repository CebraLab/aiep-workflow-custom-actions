#!/bin/bash
sudo systemctl restart ngrok
sleep 8
echo "Ngrok: $(sudo systemctl is-active ngrok)"
echo "=== Tunnels ==="
curl -s http://127.0.0.1:4040/api/tunnels | python3 -c "
import sys,json
d=json.load(sys.stdin)
for t in d['tunnels']:
    print(t['public_url'], '->', t['config']['addr'])
"
echo "=== PM2 logs (last 15) ==="
pm2 logs aiep-backend --nostream --lines 15 2>/dev/null | tail -20
