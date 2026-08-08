# Easkoy

Easkoy is a Docker deployment template for sing-box VLESS TCP Reality.

Features:
- Automatic UUID generation
- Automatic Reality key generation
- Automatic VLESS link output
- TCP + Reality + Vision support
- Optional Cloudflared tunnel module

## Quick Deploy

Build:

```bash
docker build -t easkoy .
```

Run:

```bash
docker run -d \
 --name easkoy \
 -p 443:443 \
 easkoy
```

Check node information:

```bash
docker logs easkoy
```

## Environment Variables

`SNI`
- Default: www.microsoft.com

`ENABLE_CLOUDFLARED`
- Default: false

`TUNNEL_TOKEN`
- Required only when Cloudflared is enabled

## Client

Copy the VLESS link from logs and import into V2RayN/V2RayNG.
