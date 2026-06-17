#!/bin/bash
sudo systemctl stop aiep-tunnel
sleep 3
sudo systemctl start aiep-tunnel
sleep 10
HOSTNAME=$(curl -s http://127.0.0.1:4042/quicktunnel | python3 -c 'import sys,json;print(json.load(sys.stdin)["hostname"])')
echo "New URL: https://$HOSTNAME"
curl -s -o /dev/null -w '%{http_code}' -X POST "https://$HOSTNAME/api/hubspot/execute/admision-callcenter" -H 'Content-Type: application/json' -d '{"callbackId":"test","object":{"objectId":1,"objectType":"CONTACT","properties":{}},"inputFields":{}}' --max-time 15
