#!/bin/bash
sudo systemctl restart aiep-tunnel 2>/dev/null
sleep 8
HOST=$(curl -s http://127.0.0.1:4042/quicktunnel | python3 -c "import sys,json;print(json.load(sys.stdin)['hostname'])")
echo "URL: $HOST"
curl -s -o /dev/null -w "HTTP %{http_code}" "https://$HOST/" --max-time 10
echo ""
echo "=== POST test ==="
curl -s -o /dev/null -w "HTTP %{http_code}" -X POST "https://$HOST/api/hubspot/execute/admision-callcenter" -H "Content-Type: application/json" -d '{"callbackId":"x","object":{"objectId":1,"objectType":"CONTACT","properties":{}},"inputFields":{}}' --max-time 15
