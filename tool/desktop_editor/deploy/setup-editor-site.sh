#!/bin/bash
# Run as root on the server:  bash setup-editor-site.sh
# Needs in /home/naija/deploy-backups: editor-dist.tgz (the editor build) and the deploy/*.conf files listed below.
# Adds ONE new site (editor.surveyscriber.com); no other site is touched. Rolls back if nginx -t fails.
set -e
SRC=/home/naija/deploy-backups/editor-deploy
HOST=editor.surveyscriber.com
[ -d "$SRC" ] || { echo "missing $SRC"; exit 1; }
getent hosts "$HOST" >/dev/null || { echo "DNS for $HOST does not exist yet: add the A record first"; exit 1; }
mkdir -p /var/www/editor
rm -rf /var/www/editor.new && mkdir /var/www/editor.new && tar xzf "$SRC/editor-dist.tgz" -C /var/www/editor.new --strip-components=1
rm -rf /var/www/editor.old; [ -d /var/www/editor ] && mv /var/www/editor /var/www/editor.old; mv /var/www/editor.new /var/www/editor
chmod -R a+rX /var/www/editor
for f in editor-locations.conf editor-proxy.conf editor-security-headers.conf; do cp "$SRC/$f" /etc/nginx/snippets/$f; done
cp "$SRC/editor-http-shared.conf" /etc/nginx/conf.d/editor-http-shared.conf
cp "$SRC/$HOST.site" /etc/nginx/sites-available/$HOST
ln -sf /etc/nginx/sites-available/$HOST /etc/nginx/sites-enabled/$HOST
if nginx -t; then systemctl reload nginx; echo "nginx reloaded (http only)"; else
  rm -f /etc/nginx/sites-enabled/$HOST /etc/nginx/conf.d/editor-http-shared.conf; echo "nginx -t failed: removed the editor site, nothing else changed"; exit 1; fi
certbot --nginx -d "$HOST" --redirect
nginx -t && systemctl reload nginx
echo "DONE: https://$HOST/"
