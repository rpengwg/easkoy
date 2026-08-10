# Easkoy 部署说明

## 项目简介

Easkoy 是基于 sing-box 的 VLESS TCP Reality Docker 部署项目。

主要功能：

-   自动生成 UUID
-   自动生成 Reality 密钥
-   自动输出节点参数
-   支持 Docker 部署
-   支持 Koyeb、Railway、Render、VPS
-   Cloudflared Tunnel 可选启用

## 一、Docker 部署

### 1. 构建镜像

进入项目目录：

``` bash
cd Easkoy
```

执行：

``` bash
docker build -t easkoy .
```

### 2. 启动容器

``` bash
docker run -d \
--name easkoy \
--restart always \
-p 443:443 \
easkoy
```

### 3. 查看节点信息

``` bash
docker logs easkoy
```

日志会输出：

-   UUID
-   PublicKey
-   ShortID
-   SNI

## 七、安全建议

-   不公开 UUID
-   定期更新 Reality 密钥
-   不共享完整节点链接
-   使用可靠 SNI
