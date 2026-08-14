#!/bin/sh

set -eu

echo
echo "========================================"
echo "       Easkoy VLESS REALITY Starting"
echo "========================================"
echo

# ==================================================
# 1. Basic configuration
# ==================================================

# UUID
# If UUID is provided through Railway Variables,
# use it. Otherwise generate a new UUID.
if [ -n "${UUID:-}" ]; then
    NODE_UUID="$UUID"
else
    NODE_UUID="$(cat /proc/sys/kernel/random/uuid)"
fi

# ==================================================
# 2. Railway TCP Proxy application port
# ==================================================
#
# Current Railway configuration:
#
# TCP Proxy -> Application Port 8080
#
# Therefore this test version listens on 8080.
#
# IMPORTANT:
# We intentionally do NOT use:
#   WS_LISTEN_PORT
#   PORT
#
# We also intentionally ignore any old:
#   REALITY_LISTEN_PORT
#
# variable and use 8080 directly.
#
REALITY_LISTEN_PORT="8080"

# ==================================================
# 3. Reality SNI
# ==================================================

REALITY_SNI="${REALITY_SNI:-www.microsoft.com}"

# ==================================================
# 4. Check sing-box
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
# 5. Generate Reality key pair
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
    echo "[ERROR] Reality key pair generation failed."
    echo
    echo "$KEY_OUTPUT"
    echo
    exit 1
fi

# ==================================================
# 6. Generate Reality ShortID
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
# 7. Configuration paths
# ==================================================

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

# ==================================================
# 8. Generate sing-box configuration
# ==================================================

echo "[INFO] Generating sing-box configuration..."

sed \
    -e "s|\${UUID}|$NODE_UUID|g" \
    -e "s|\${REALITY_LISTEN_PORT}|$REALITY_LISTEN_PORT|g" \
    -e "s|\${REALITY_SNI}|$REALITY_SNI|g" \
    -e "s|\${PRIVATE_KEY}|$PRIVATE_KEY|g" \
    -e "s|\${SHORT_ID}|$SHORT_ID|g" \
    "$CONFIG_TEMPLATE" > "$CONFIG_FILE"

# ==================================================
# 9. Validate configuration
# ==================================================

echo
echo "[INFO] Validating sing-box configuration..."

if ! sing-box check -c "$CONFIG_FILE"; then
    echo
    echo "========================================"
    echo "[ERROR] sing-box configuration INVALID"
    echo "========================================"
    echo
    echo "Configuration:"
    echo "$CONFIG_FILE"
    echo
    cat "$CONFIG_FILE"
    echo
    exit 1
fi

echo "[INFO] sing-box configuration OK."

# ==================================================
# 10. Display node information
# ==================================================

echo
echo "========================================"
echo "       VLESS + TCP + REALITY"
echo "========================================"

echo
echo "Listen Address:"
echo "0.0.0.0"

echo
echo "Listen Port:"
echo "$REALITY_LISTEN_PORT"

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
echo "Network:"
echo "tcp"

echo
echo "Security:"
echo "reality"

echo
echo "========================================"

# ==================================================
# 11. Railway network information
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
echo "Effective REALITY Port:"
echo "$REALITY_LISTEN_PORT"

echo
echo "========================================"

# ==================================================
# 12. Export variables
# ==================================================

export UUID="$NODE_UUID"
export PUBLIC_KEY
export SHORT_ID
export REALITY_SNI
export REALITY_LISTEN_PORT

# ==================================================
# 13. Output node
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
# 14. Start sing-box
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
