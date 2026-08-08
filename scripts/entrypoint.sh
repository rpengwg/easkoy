#!/bin/sh

set -e

echo "===== Easkoy Starting ====="

UUID=$(cat /proc/sys/kernel/random/uuid)

SNI=${SNI:-www.microsoft.com}

SHORT_ID=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')

echo "[INFO] UUID generated"

if command -v sing-box >/dev/null 2>&1; then
    KEY=$(sing-box generate reality-keypair)
else
    KEY="PRIVATE_KEY_NOT_GENERATED"
fi

PRIVATE_KEY=$(echo "$KEY" | grep PrivateKey | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEY" | grep PublicKey | awk '{print $2}')

sed \
-e "s|\${UUID}|$UUID|g" \
-e "s|\${SNI}|$SNI|g" \
-e "s|\${SHORT_ID}|$SHORT_ID|g" \
-e "s|\${PRIVATE_KEY}|$PRIVATE_KEY|g" \
/app/config/config.json.template > /app/config/config.json

export UUID SNI SHORT_ID PUBLIC_KEY

/app/output_node.sh

exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
