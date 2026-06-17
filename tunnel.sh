#!/bin/bash
ssh -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=60 \
    -o ExitOnForwardFailure=yes \
    -R 80:localhost:3000 \
    nokey@localhost.run 2>&1 | while read line; do
  echo "$line"
  URL=$(echo "$line" | grep -oP 'https://[a-zA-Z0-9.-]+\.lhr\.life')
  if [ -n "$URL" ]; then
    echo "$URL" > /tmp/aiep-tunnel-url.txt
  fi
done
