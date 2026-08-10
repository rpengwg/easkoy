FROM alpine:latest


LABEL name="Easkoy"

LABEL version="1.1"



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



# 自动安装 sing-box

RUN ARCH=$(uname -m) && \
if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
wget -O /tmp/sing-box.tar.gz \
https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-linux-${ARCH}.tar.gz && \
tar -zxvf /tmp/sing-box.tar.gz -C /tmp && \
mv /tmp/sing-box*/sing-box /usr/local/bin/sing-box && \
chmod +x /usr/local/bin/sing-box



COPY config/config.json.template \
/app/config/



COPY scripts/*.sh \
/app/



COPY supervisord/supervisord.conf \
/etc/supervisor/conf.d/supervisord.conf



RUN chmod +x /app/*.sh



EXPOSE 443



ENTRYPOINT ["/app/entrypoint.sh"]
