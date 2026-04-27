#!/bin/bash
set -euxo pipefail

apt-get update
apt-get install -y nginx

cat > /var/www/html/index.html <<HTML
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Azure Multi-Region HA</title>
  </head>
  <body style="font-family: Arial, sans-serif; margin: 2rem;">
    <h1>Azure Multi-Region HA Demo</h1>
    <p>This instance is serving from: <strong>${region}</strong></p>
    <p>Region role: <strong>${role}</strong></p>
  </body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
