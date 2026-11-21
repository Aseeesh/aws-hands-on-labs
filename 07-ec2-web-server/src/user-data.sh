#!/bin/bash
# Runs once as root at first boot (EC2 "user data"). Installs nginx and writes a page
# showing which instance served the request (read from instance metadata, IMDSv2).
dnf install -y nginx
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
MD() { curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$1"; }
cat > /usr/share/nginx/html/index.html <<HTML
<!doctype html><html lang="en"><head><meta charset="utf-8"><title>AWS Lab 07 - EC2 Web Server</title>
<style>body{font-family:system-ui,sans-serif;max-width:640px;margin:4rem auto;padding:0 1rem;line-height:1.6}code{background:#eee;padding:2px 6px;border-radius:4px}</style></head>
<body><h1>Hello from Amazon EC2 &#128075;</h1>
<p>Served by <strong>nginx</strong> on a real virtual server.</p>
<ul><li>Instance ID: <code>$(MD instance-id)</code></li><li>Availability Zone: <code>$(MD placement/availability-zone)</code></li><li>Instance type: <code>$(MD instance-type)</code></li></ul>
<p>Part of <a href="https://github.com/Aseeesh/aws-hands-on-labs">aws-hands-on-labs</a> - Lab 07.</p></body></html>
HTML
systemctl enable --now nginx
