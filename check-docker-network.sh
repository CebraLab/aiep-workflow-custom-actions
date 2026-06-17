#!/bin/bash
GW=$(sudo docker exec 2e194d16c34b sh -c "ip route | grep default | awk '{print \$3}'")
echo "Docker gateway: $GW"
echo "=== Test host reachability ==="
sudo docker exec 2e194d16c34b sh -c "curl -s -o /dev/null -w '%{http_code}' http://$GW:3000/api/hubspot/execute/admision-callcenter -X POST -H 'Content-Type: application/json' -d '{}' --max-time 5" 2>/dev/null || echo "Cannot reach host:3000"
