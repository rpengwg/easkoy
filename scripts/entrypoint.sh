#!/bin/sh

set -eu

echo
echo "========================================"
echo "        Easkoy Starting"
echo "========================================"
echo

# --------------------------------------------------
# Basic environment
# --------------------------------------------------

UUID="${UUID:-$(cat /proc/sys/kernel/random/uuid)}"

# Railway HTTP/public networking port.
# This is the port used by the Railway public domain.
WS_LISTEN_PORT="${PORT:-8080}"

# Railway TCP Proxy internal application port.
#
# Railway provides this automatically when TCP Proxy
# is configured.
#
# If it is not available, allow REALITY_LISTEN_PORT
# to be configured manually.
REALITY_LISTEN_PORT="${RAILWAY_TCP_APPLICATION_PORT:-${REALITY_LISTEN_PORT:-443}}"

# Reality SNI / handshake target
REALITY_SNI="${REALITY_SNI:-www.microsoft.com}"

# WebSocket path
WS_PATH="${WS_PATH:-/easkoy-ws}"

# --------------------------------------------------
# Validate ports
# --------------------------------------------------

case "$WS_LISTEN_PORT" in
    ''|*[!0-9]*)
        echo "[ERROR] Invalid WS_LISTEN_PORT: $WS_LISTEN_PORT"
        exit 1
        ;;
esac

case "$REALITY_LISTEN_PORT" in
    ''|*[!0-9]*)
        echo "[ERROR] Invalid REALITY_LISTEN_PORT: $REALITY_LISTEN_PORT"
        exit 1
        ;;
esac

if [ "$WS_LISTEN_PORT" = "$REALITY_LISTEN_PORT" ]; then
    echo
    echo "[ERROR] WS and REALITY cannot use the same internal port."
    echo
    echo "WS_LISTEN_PORT      = $WS_LISTEN_PORT"
    echo "REALITY_LISTEN_PORT = $REALITY_LISTEN_PORT"
    echo
    echo "Set Railway HTTP PORT and TCP Proxy application port"
    echo "to two different ports."
    exit 1
fi

# --------------------------------------------------
# Generate Reality key pair
# --------------------------------------------------

echo "[INFO] Generating Reality key pair..."

if ! command -v sing-box >/dev/null 2>&1; then
    echo "[ERROR] sing-box was not found."
    exit 1
fi

KEY="$(sing-box generate reality-keypair)"

PRIVATE_KEY="$(echo "$KEY" | awk '/PrivateKey:/ {print $2}')"
PUBLIC_KEY="$(echo "$KEY" | awk '/PublicKey:/ {print $2}')"

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "[ERROR] Failed to generate Reality key pair."
    echo
    echo "$KEY"
    exit 1
fi

# --------------------------------------------------
# Generate Reality Short ID
# --------------------------------------------------

SHORT_ID="$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')"

if [ -z "$SHORT_ID" ]; then
    echo "[ERROR] Failed to generate Reality ShortID."
    exit 1
fi

# --------------------------------------------------
# Generate configuration
# --------------------------------------------------

echo "[INFO] Generating sing-box configuration..."

sed \
    -e "s|\${UUID}|$UUID|g" \
    -e "s|\${REALITY_LISTEN_PORT}|$REALITY_LISTEN_PORT|g" \
    -e "s|\${WS_LISTEN_PORT}|$WS_LISTEN_PORT|g" \
    -e "s|\${REALITY_SNI}|$REALITY_SNI|g" \
    -e "s|\${PRIVATE_KEY}|$PRIVATE_KEY|g" \
    -e "s|\${SHORT_ID}|$SHORT_ID|g" \
    -e "s|\${WS_PATH}|$WS_PATH|g" \
    /app/config/config.json.template \
    > /app/config/config.json

# --------------------------------------------------
# Validate configuration
# --------------------------------------------------

echo
echo "[INFO] Checking sing-box configuration..."

if ! sing-box check -c /app/config/config.json; then
    echo
    echo "[ERROR] sing-box configuration validation failed."
    echo
    cat /app/config/config.json
    exit 1
fi

echo "[INFO] sing-box configuration OK."

# --------------------------------------------------
# Railway networking information
# --------------------------------------------------

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
echo "========================================"

# --------------------------------------------------
# Node information
# --------------------------------------------------

export UUID
export PUBLIC_KEY
export SHORT_ID
export REALITY_SNI
export WS_PATH

export REALITY_LISTEN_PORT
export WS_LISTEN_PORT

/app/output_node.sh

echo
echo "[INFO] Starting supervisord..."
echo

exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
