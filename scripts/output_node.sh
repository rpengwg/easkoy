#!/bin/sh


echo
echo "=================================================="
echo "              Easkoy Node Information"
echo "=================================================="


ADDRESS="${RAILWAY_TCP_PROXY_DOMAIN:-NOT_AVAILABLE}"

PORT="${RAILWAY_TCP_PROXY_PORT:-$REALITY_LISTEN_PORT}"


echo
echo "Address:"
echo "$ADDRESS"


echo
echo "Port:"
echo "$PORT"


echo
echo "UUID:"
echo "$UUID"


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



# ==================================================
# VLESS URI
# ==================================================

if [ "$ADDRESS" != "NOT_AVAILABLE" ]; then


LINK="vless://${UUID}@${ADDRESS}:${PORT}?type=tcp&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=${REALITY_SNI}&sid=${SHORT_ID}&flow=xtls-rprx-vision#Easkoy-Reality"


echo
echo "=================================================="
echo "              VLESS Import Link"
echo "=================================================="


echo
echo "$LINK"


else


echo
echo "[WARNING]"
echo "Railway TCP Proxy not detected."


fi


echo
echo "=================================================="
