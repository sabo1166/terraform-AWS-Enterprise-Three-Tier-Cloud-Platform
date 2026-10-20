#!/bin/bash
# Installs and starts Nginx on Amazon Linux 2023. Safe to re-run.
# Troubleshooting: all output goes to /var/log/user-data.log (also see /var/log/cloud-init-output.log).
set -euo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1

echo "[user-data] start: $(date -u +%FT%TZ)"

# Package install needs outbound internet (NAT Gateway). Retry for transient failures.
for attempt in 1 2 3 4 5; do
  if dnf install -y nginx; then
    break
  fi
  echo "[user-data] dnf install failed (attempt ${attempt}); retrying in 10s"
  sleep 10
  if [ "${attempt}" -eq 5 ]; then
    echo "[user-data] ERROR: could not install nginx - check NAT/route table/security group egress"
    exit 1
  fi
done

# Instance identity via IMDSv2 (IMDSv1 is disabled on this instance).
TOKEN="$(curl -sS -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' || true)"
imds() { curl -sS -H "X-aws-ec2-metadata-token: ${TOKEN}" "http://169.254.169.254/latest/meta-data/$1" || echo unknown; }
INSTANCE_ID="$(imds instance-id)"
AZ="$(imds placement/availability-zone)"

cat > /usr/share/nginx/html/index.html <<EOF
<!doctype html>
<html><head><title>Three-tier demo</title></head>
<body>
<h1>Nginx is running</h1>
<p>Instance: ${INSTANCE_ID}</p>
<p>Availability Zone: ${AZ}</p>
</body></html>
EOF

nginx -t
systemctl enable nginx
systemctl restart nginx

echo "[user-data] done: $(date -u +%FT%TZ)"
