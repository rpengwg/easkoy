#!/bin/sh

set -eu

echo
echo "========================================"
echo "     Easkoy VLESS REALITY - Railway"
echo "========================================"
echo

# ==================================================
# 1. Basic configuration
# ==================================================

# UUID
# Railway Variables 中如果设置 UUID，则使用指定 UUID。
# 未设置时自动生成。
if [ -n "${UUID:-}" ]; then
    NODE_UUID="$UUID"
else
    NODE_UUID="$(cat /proc/sys/kernel/random/uuid)"
fi

# ==================================================
# 2. Railway TCP Proxy application port
# ==================================================
#
# Railway TCP Proxy:
#
#   External:
#       RAILWAY_TCP_PROXY_DOMAIN:
#       RAILWAY_TCP_PROXY_PORT:
#
#   Internal:
#       RAILWAY_TCP_APPLICATION_PORT
#
# 优先使用 Railway TCP Proxy 的 Application Port。
#
# 如果 Railway 没有提供该变量：
#
#   1. PORT
#   2. 8080
#
# 依次作为 fallback。
#

if [ -n "${RAILWAY_TCP_APPLICATION_PORT:-}" ]; then

    REALITY_LISTEN_PORT="$RAILWAY_TCP_APPLICATION_PORT"

elif [ -n "${PORT:-}" ]; then

    REALITY_LISTEN_PORT="$PORT"

else

    REALITY_LISTEN_PORT="8080"

fi

echo "[INFO] Effective listen port: $REALITY_LISTEN_PORT"

# ==================================================
# 3. Reality SNI
# ==================================================

REALITY_SNI="${REALITY_SNI:-www.microsoft.com}"

# ==================================================
# 4. Reality handshake
# ==================================================
#
# REALITY server requires a reachable TLS handshake
# destination.
#
# Default:
#
#   www.microsoft.com:443
#
# 可以通过 Railway Variable 修改：
#
#   REALITY_HANDSHAKE_DOMAIN
#   REALITY_HANDSHAKE_PORT
#

REALITY_HANDSHAKE_DOMAIN="${REALITY_HANDSHAKE_DOMAIN:-www.microsoft.com}"
REALITY_HANDSHAKE_PORT="${REALITY_HANDSHAKE_PORT:-443}"

# ==================================================
# 5. Check sing-box
# ==================================================

echo
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
# 6. Generate Reality key pair
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

PRIVATE_KEY="$(echo "$KEY_OUTPUT" | awk -F': ' '/PrivateKey:/ {print $2}' | tr -d '[:space:]')"

PUBLIC_KEY="$(echo "$KEY_OUTPUT" | awk -F': ' '/PublicKey:/ {print $2}' | tr -d '[:space:]')"

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then

    echo
    echo "[ERROR] Reality key pair generation failed."
    echo
    echo "$KEY_OUTPUT"
    echo

    exit 1

fi

echo "[INFO] Reality key pair generated."

# ==================================================
# 7. Generate Reality ShortID
# ==================================================

echo "[INFO] Generating Reality ShortID..."

SHORT_ID="$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')"

if [ -z "$SHORT_ID" ]; then

    echo
    echo "[ERROR] Failed to generate Reality ShortID."
    echo

    exit 1

fi

echo "[INFO] Reality ShortID: $SHORT_ID"

# ==================================================
# 8. Configuration paths
# ==================================================

CONFIG_DIR="/app/config"
CONFIG_TEMPLATE="$CONFIG_DIR/config.json.template"
CONFIG_FILE="$CONFIG_DIR/config.json"

if [ ! -f "$CONFIG_TEMPLATE" ]; then

    echo
    echo "[ERROR] Configuration template not found:"
    echo "$CONFIG_TEMPLATE"
    echo

    exit 1

fi

mkdir -p "$CONFIG_DIR"

# ==================================================
# 9. Generate sing-box configuration
# ==================================================

echo
echo "[INFO] Generating sing-box configuration..."

#
# 注意：
# config.json.template 中使用：
#
# ${UUID}
# ${REALITY_LISTEN_PORT}
# ${REALITY_SNI}
# ${PRIVATE_KEY}
# ${SHORT_ID}
# ${REALITY_HANDSHAKE_DOMAIN}
# ${REALITY_HANDSHAKE_PORT}
#

sed \
    -e "s|\${UUID}|$NODE_UUID|g" \
    -e "s|\${REALITY_LISTEN_PORT}|$REALITY_LISTEN_PORT|g" \
    -e "s|\${REALITY_SNI}|$REALITY_SNI|g" \
    -e "s|\${PRIVATE_KEY}|$PRIVATE_KEY|g" \
    -e "s|\${SHORT_ID}|$SHORT_ID|g" \
    -e "s|\${REALITY_HANDSHAKE_DOMAIN}|$REALITY_HANDSHAKE_DOMAIN|g" \
    -e "s|\${REALITY_HANDSHAKE_PORT}|$REALITY_HANDSHAKE_PORT|g" \
    "$CONFIG_TEMPLATE" > "$CONFIG_FILE"

# ==================================================
# 10. Validate configuration
# ==================================================

echo
echo "[INFO] Validating sing-box configuration..."

if ! sing-box check -c "$CONFIG_FILE"; then

    echo
    echo "========================================"
    echo " [ERROR] sing-box configuration INVALID"
    echo "========================================"
    echo

    echo "Configuration:"
    echo "$CONFIG_FILE"

    echo
    cat "$CONFIG_FILE"
    echo

    exit 1

fi

echo
echo "[INFO] sing-box configuration OK."

# ==================================================
# 11. Railway environment information
# ==================================================

RAILWAY_TCP_DOMAIN="${RAILWAY_TCP_PROXY_DOMAIN:-}"
RAILWAY_TCP_PORT="${RAILWAY_TCP_PROXY_PORT:-}"

# ==================================================
# 12. Display node information
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
echo "REALITY Handshake:"
echo "$REALITY_HANDSHAKE_DOMAIN:$REALITY_HANDSHAKE_PORT"

echo
echo "========================================"

# ==================================================
# 13. Railway Network Information
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
# 14. Export variables
# ==================================================

export UUID="$NODE_UUID"
export PUBLIC_KEY="$PUBLIC_KEY"
export SHORT_ID="$SHORT_ID"
export REALITY_SNI="$REALITY_SNI"
export REALITY_LISTEN_PORT="$REALITY_LISTEN_PORT"
export REALITY_HANDSHAKE_DOMAIN="$REALITY_HANDSHAKE_DOMAIN"
export REALITY_HANDSHAKE_PORT="$REALITY_HANDSHAKE_PORT"

# ==================================================
# 15. Output node information
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
# 16. Final Railway endpoint
# ==================================================

echo
echo "========================================"
echo "          Railway REALITY Endpoint"
echo "========================================"

if [ -n "$RAILWAY_TCP_DOMAIN" ] && [ -n "$RAILWAY_TCP_PORT" ]; then

    echo
    echo "Address:"
    echo "$RAILWAY_TCP_DOMAIN"

    echo
    echo "Port:"
    echo "$RAILWAY_TCP_PORT"

    echo
    echo "Endpoint:"
    echo "$RAILWAY_TCP_DOMAIN:$RAILWAY_TCP_PORT"

else

    echo
    echo "[WARNING] Railway TCP Proxy information unavailable."

    echo
    echo "You must enable:"
    echo "Settings -> Networking -> TCP Proxy"

fi

echo
echo "========================================"

# ==================================================
# 17. Supervisor check
# ==================================================

if [ ! -f "/etc/supervisor/conf.d/supervisord.conf" ]; then

    echo
    echo "[ERROR] Supervisor configuration not found:"
    echo "/etc/supervisor/conf.d/supervisord.conf"
    echo

    exit 1

fi

# ==================================================
# 18. Start
# ==================================================

echo
echo "========================================"
echo "          Starting sing-box"
echo "========================================"
echo

exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
