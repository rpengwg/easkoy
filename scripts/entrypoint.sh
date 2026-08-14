#!/bin/sh

set -eu

echo
echo "=================================================="
echo "        Easkoy Railway V4 REALITY Node"
echo "=================================================="

DATA_DIR="/app/data"
CONFIG_DIR="/app/config"

mkdir -p "$DATA_DIR"
mkdir -p "$CONFIG_DIR"


# ==================================================
# UUID
# ==================================================

if [ -f "$DATA_DIR/uuid" ]; then

    NODE_UUID="$(cat "$DATA_DIR/uuid")"

else

    NODE_UUID="${UUID:-$(cat /proc/sys/kernel/random/uuid)}"

    echo "$NODE_UUID" > "$DATA_DIR/uuid"

fi


# ==================================================
# Railway Port
# ==================================================

if [ -n "${RAILWAY_TCP_APPLICATION_PORT:-}" ]; then

    REALITY_LISTEN_PORT="$RAILWAY_TCP_APPLICATION_PORT"

elif [ -n "${PORT:-}" ]; then

    REALITY_LISTEN_PORT="$PORT"

else

    REALITY_LISTEN_PORT="8080"

fi


# ==================================================
# Reality Parameters
# ==================================================

REALITY_SNI="${REALITY_SNI:-www.microsoft.com}"

REALITY_HANDSHAKE_DOMAIN="${REALITY_HANDSHAKE_DOMAIN:-www.microsoft.com}"

REALITY_HANDSHAKE_PORT="${REALITY_HANDSHAKE_PORT:-443}"


# ==================================================
# Generate Reality Key
# ==================================================

if [ -f "$DATA_DIR/private.key" ]; then


    PRIVATE_KEY="$(cat "$DATA_DIR/private.key")"

    PUBLIC_KEY="$(cat "$DATA_DIR/public.key")"


    SHORT_ID="$(cat "$DATA_DIR/short_id")"


else


    KEY_OUTPUT="$(sing-box generate reality-keypair)"

    PRIVATE_KEY="$(echo "$KEY_OUTPUT" | awk -F': ' '/PrivateKey/ {print $2}')"

    PUBLIC_KEY="$(echo "$KEY_OUTPUT" | awk -F': ' '/PublicKey/ {print $2}')"


    SHORT_ID="$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')"


    echo "$PRIVATE_KEY" > "$DATA_DIR/private.key"

    echo "$PUBLIC_KEY" > "$DATA_DIR/public.key"

    echo "$SHORT_ID" > "$DATA_DIR/short_id"


fi



chmod 600 "$DATA_DIR"/*



# ==================================================
# Generate Config
# ==================================================

sed \
-e "s|\${UUID}|$NODE_UUID|g" \
-e "s|\${REALITY_LISTEN_PORT}|$REALITY_LISTEN_PORT|g" \
-e "s|\${REALITY_SNI}|$REALITY_SNI|g" \
-e "s|\${REALITY_HANDSHAKE_DOMAIN}|$REALITY_HANDSHAKE_DOMAIN|g" \
-e "s|\${REALITY_HANDSHAKE_PORT}|$REALITY_HANDSHAKE_PORT|g" \
-e "s|\${PRIVATE_KEY}|$PRIVATE_KEY|g" \
-e "s|\${SHORT_ID}|$SHORT_ID|g" \
"$CONFIG_DIR/config.json.template" \
> "$CONFIG_DIR/config.json"



# ==================================================
# Check Config
# ==================================================

echo
echo "[INFO] Checking sing-box configuration"

sing-box check \
-c "$CONFIG_DIR/config.json"


# ==================================================
# Export
# ==================================================

export UUID="$NODE_UUID"
export PUBLIC_KEY
export SHORT_ID
export REALITY_SNI
export REALITY_LISTEN_PORT



# ==================================================
# Node Information
# ==================================================

/app/output_node.sh



# ==================================================
# Start
# ==================================================

exec supervisord \
-c /etc/supervisor/conf.d/supervisord.conf
