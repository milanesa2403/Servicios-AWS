#!/bin/bash
set -euxo pipefail

dnf install -y httpd

TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
md() { curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$1"; }
REGION=$(md placement/region)
ZONA=$(md placement/availability-zone)
INSTANCIA=$(md instance-id)

mkdir -p /var/www/html/api

cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Plataforma de Reclutamiento Minero</title></head>
<body>
  <h1>Plataforma de Reclutamiento Minero</h1>
  <p>Region: $REGION</p>
  <p>Zona: $ZONA</p>
  <p>Instancia: $INSTANCIA</p>
</body>
</html>
HTML

echo "ok" > /var/www/html/api/health
echo "{\"region\": \"$REGION\", \"zona\": \"$ZONA\", \"instancia\": \"$INSTANCIA\"}" > /var/www/html/api/info

cat > /etc/httpd/conf.d/api.conf <<'CONF'
<Directory "/var/www/html/api">
    ForceType text/plain
    Header set Cache-Control "no-store"
</Directory>
CONF

systemctl enable --now httpd
