#!/bin/sh

set -eu

echo
echo "========================================"
echo "          Easkoy REALITY Starting"
echo "========================================"
echo

# ==================================================
# 1. Basic configuration
# ==================================================

# UUID:
# If Railway Variables contains UUID, use it.
# Otherwise generate a new UUID.
if [ -n "${UUID:-}" ]; then
    NODE_UUID="$UUID"
else
    NODE_UUID="$(cat /proc/sys/kernel/random/uuid)"
fi

# --------------------------------------------------
# Reality listening port
# --------------------------------------------------
#
# IMPORTANT:
# Do NOT use REALITY_LISTEN_PORT here.
#
# Railway may automatically provide:
#
# REALITY_LISTEN_PORT=8080
#
# We intentionally ignore that variable.
#
# For the current single-node test, use PORT first.
# Railway TCP Proxy should point to this application port.
#
REALITY_LISTEN_PORT="${PORT:-8080}"

# --------------------------------------------------
# Reality SNI
# --------------------------------------------------

REALITY_SNI="${REALITY_SNI:-www.microsoft.com}"

# ==================================================
# 2. Validate port
# ==================================================

case "$REALITY_LISTEN_PORT" in
    ''|*[!0-9]*)
        echo
        echo "[ERROR] Invalid listening port:"
        echo "REALITY_LISTEN_PORT=$REALITY_LISTEN_PORT"
        echo
        exit 1
        ;;
esac

if [ "$REALITY_LISTEN_PORT" -lt 1 ] || [ "$REALITY_LISTEN_PORT" -gt 65535 ]; then
    echo
    echo "[ERROR] Port out of range:"
    echo "$REALITY_LISTEN_PORT"
    echo
    exit 1
fi

# ==================================================
# 3. Check sing-box
# ==================================================

echo "[INFO] Checking sing-box..."

if ! command -v sing-box >/dev/null 2>&1; then
    echo
    echo "[ERROR] sing-box command not found."
    echo
    exit 1
fi

sing-box version

echo

# ==================================================
# 4. Generate Reality key pair
# ==================================================

echo "[INFO] Generating Reality key pair..."

KEY_OUTPUT="$(sing-box generate reality-keypair 2>&1)" || {
    echo
    echo "[ERROR] Failed to generate Reality key pair."
    echo
    echo "$KEY_OUTPUT"
    echo
    exit 1
}

PRIVATE_KEY="$(echo "$KEY_OUTPUT" | awk '/PrivateKey:/ {print $2}')"
PUBLIC_KEY="$(echo "$KEY_OUTPUT" | awk '/PublicKey:/ {print $2}')"

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo
    echo "[ERROR] Reality key pair generation returned invalid data."
    echo
    echo "$KEY_OUTPUT"
    echo
    exit 1
fi

# ==================================================
# 5. Generate Reality Short ID
# ==================================================

echo "[INFO] Generating Reality ShortID..."

SHORT_ID="$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')"

if [ -z "$SHORT_ID" ]; then
    echo
    echo "[ERROR] Failed to generate Reality ShortID."
    echo
    exit 1
fi

# ==================================================
# 6. Generate sing-box configuration
# ==================================================

echo "[INFO] Generating sing-box configuration..."

CONFIG_TEMPLATE="/app/config/config.json.template"
CONFIG_FILE="/app/config/config.json"

if [ ! -f "$CONFIG_TEMPLATE" ]; then
    echo
    echo "[ERROR] Configuration template not found:"
    echo "$CONFIG_TEMPLATE"
    echo
    exit 1
fi

mkdir -p /app/config

sed \
    -e "s|\${UUID}|$NODE_UUID|g" \
    -e "s|\${REALITY_LISTEN_PORT}|$REALITY_LISTEN_PORT|g" \
    -e "s|\${REALITY_SNI}|$REALITY_SNI|g" \
    -e "s|\${PRIVATE_KEY}|$PRIVATE_KEY|g" \
    -e "s|\${SHORT_ID}|$SHORT_ID|g" \
    "$CONFIG_TEMPLATE" > "$CONFIG_FILE"

# ==================================================
# 7. Display generated configuration information
# ==================================================

echo
echo "========================================"
echo "       Generated REALITY Configuration"
echo "========================================"

echo
echo "Listen:"
echo "0.0.0.0:$REALITY_LISTEN_PORT"

echo
echo "UUID:"
echo "$NODE_UUID"

echo
echo "PublicKey:"
echo "$PUBLIC_KEY"

echo
echo "ShortID:"
echo "$SHORT_ID"

echo
echo "SNI:"
echo "$REALITY_SNI"

echo
echo "Flow:"
echo "xtls-rprx-vision"

echo
echo "Protocol:"
echo "VLESS + TCP + REALITY"

echo
echo "========================================"

# ==================================================
# 8. Validate sing-box configuration
# ==================================================

echo
echo "[INFO] Validating sing-box configuration..."

if ! sing-box check -c "$CONFIG_FILE"; then
    echo
    echo "========================================"
    echo "[ERROR] sing-box configuration INVALID"
    echo "========================================"
    echo
    echo "Configuration file:"
    echo "$CONFIG_FILE"
    echo
    cat "$CONFIG_FILE"
    echo
    exit 1
fi

echo
echo "[INFO] sing-box configuration OK."

# ==================================================
# 9. Railway network information
# ==================================================

echo
echo "========================================"
echo "       Railway Network Information"
echo "========================================"

echo
echo "RAILWAY_PUBLIC_DOMAIN:"
echo "${RAILWAY_PUBLIC_DOMAIN:-NOT_AVAILABLE}"

echo
echo "RAILWAY_TCP_PROXY_DOMAIN:"
echo "${RAILWAY_TCP_PROXY_DOMAIN:-NOT_AVAILABLE}"

echo
echo "RAILWAY_TCP_PROXY_PORT:"
echo "${RAILWAY_TCP_PROXY_PORT:-NOT_AVAILABLE}"

echo
echo "RAILWAY_TCP_APPLICATION_PORT:"
echo "${RAILWAY_TCP_APPLICATION_PORT:-NOT_AVAILABLE}"

echo
echo "PORT:"
echo "${PORT:-NOT_AVAILABLE}"

echo
echo "Effective REALITY listen port:"
echo "$REALITY_LISTEN_PORT"

echo
echo "========================================"

# ==================================================
# 10. Export variables for output_node.sh
# ==================================================

export UUID="$NODE_UUID"
export PUBLIC_KEY
export SHORT_ID
export REALITY_SNI
export REALITY_LISTEN_PORT

# ==================================================
# 11. Output node information
# ==================================================

if [ -f "/app/output_node.sh" ]; then

    echo
    echo "========================================"
    echo "          Easkoy Node Information"
    echo "========================================"

    /app/output_node.sh

else

    echo
    echo "[WARNING] /app/output_node.sh not found."
    echo
fi

# ==================================================
# 12. Start supervisor / sing-box
# ==================================================

echo
echo "========================================"
echo "          Starting sing-box"
echo "========================================"
echo

if [ ! -f "/etc/supervisor/conf.d/supervisord.conf" ]; then
    echo
    echo "[ERROR] Supervisor configuration not found:"
    echo "/etc/supervisor/conf.d/supervisord.conf"
    echo
    exit 1
fi

exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
