#!/bin/bash

set -u

echo
echo "=================================================="
echo "                  Easkoy Nodes"
echo "=================================================="

echo
echo "--------------------------------------------------"
echo " VLESS + TCP + REALITY"
echo "--------------------------------------------------"

echo

echo "Address:"
if [ -n "${RAILWAY_TCP_PROXY_DOMAIN:-}" ]; then
    echo "${RAILWAY_TCP_PROXY_DOMAIN}"
else
    echo "NOT_AVAILABLE"
fi

echo

echo "Port:"
if [ -n "${RAILWAY_TCP_PROXY_PORT:-}" ]; then
    echo "${RAILWAY_TCP_PROXY_PORT}"
else
    echo "NOT_AVAILABLE"
fi

echo

echo "Internal Port:"
echo "${REALITY_LISTEN_PORT:-NOT_AVAILABLE}"

echo

echo "UUID:"
echo "${UUID:-NOT_AVAILABLE}"

echo

echo "PublicKey:"
echo "${PUBLIC_KEY:-NOT_AVAILABLE}"

echo

echo "ShortID:"
echo "${SHORT_ID:-NOT_AVAILABLE}"

echo

echo "SNI:"
echo "${REALITY_SNI:-NOT_AVAILABLE}"

echo

echo "Flow:"
echo "xtls-rprx-vision"

echo

echo "Network:"
echo "TCP"

echo

echo "Security:"
echo "REALITY"

echo

echo "--------------------------------------------------"
echo " VLESS + WebSocket + TLS"
echo "--------------------------------------------------"

echo

echo "Address:"
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    echo "${RAILWAY_PUBLIC_DOMAIN}"
else
    echo "NOT_AVAILABLE"
fi

echo

echo "Port:"
echo "443"

echo

echo "UUID:"
echo "${UUID:-NOT_AVAILABLE}"

echo

echo "Path:"
echo "${WS_PATH:-NOT_AVAILABLE}"

echo

echo "Network:"
echo "WebSocket"

echo

echo "TLS:"
echo "Railway HTTPS"

echo

echo "URL:"
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    echo "https://${RAILWAY_PUBLIC_DOMAIN}${WS_PATH:-/easkoy-ws}"
else
    echo "NOT_AVAILABLE"
fi

echo

echo "--------------------------------------------------"

if [ -z "${RAILWAY_TCP_PROXY_DOMAIN:-}" ] || \
   [ -z "${RAILWAY_TCP_PROXY_PORT:-}" ]; then

    echo
    echo "[WARNING] Railway TCP Proxy is not detected."
    echo
    echo "REALITY node cannot be used until TCP Proxy"
    echo "is enabled in Railway."
    echo
fi

if [ -z "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then

    echo
    echo "[WARNING] Railway public domain is not detected."
    echo
    echo "WS + TLS node requires a Railway public domain."
    echo
fi

echo
echo "=================================================="
echo
