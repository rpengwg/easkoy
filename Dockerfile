FROM alpine:latest

RUN apk add --no-cache bash curl jq supervisor

WORKDIR /app

RUN mkdir -p /app/config

COPY config/config.json.template /app/config/
COPY scripts/entrypoint.sh /app/
COPY scripts/output_node.sh /app/

RUN chmod +x /app/*.sh

# sing-box and cloudflared binaries should be added here
# in production build replace this section with official releases

COPY supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 443

ENTRYPOINT ["/app/entrypoint.sh"]
