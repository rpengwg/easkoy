FROM alpine:latest


LABEL name="Easkoy"
LABEL version="1.1.1"


ARG SINGBOX_VERSION=1.12.8


RUN apk add --no-cache \
bash \
curl \
wget \
jq \
openssl \
supervisor \
ca-certificates


WORKDIR /app


RUN mkdir -p \
/app/config \
/app/data



RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    wget -O /tmp/sing-box.tar.gz \
    https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz \
    && tar -zxvf /tmp/sing-box.tar.gz -C /tmp \
    && cp /tmp/sing-box-${SINGBOX_VERSION}-linux-${ARCH}/sing-box \
    /usr/local/bin/sing-box \
    && chmod +x /usr/local/bin/sing-box



RUN echo "===== sing-box check =====" \
    && which sing-box \
    && sing-box version



COPY config/ /app/config/

COPY scripts/*.sh /app/


COPY supervisord/supervisord.conf \
/etc/supervisor/conf.d/supervisord.conf


RUN chmod +x /app/*.sh


EXPOSE 443


ENTRYPOINT ["/app/entrypoint.sh"]
