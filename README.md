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

## 二、Koyeb 部署

1.  将项目上传 GitHub。

2.  Koyeb 创建服务：

```{=html}
<!-- -->
```
    Create App
    → Deploy from GitHub
    → 选择 Easkoy

3.  环境变量：

可选：

    SNI=www.microsoft.com

Cloudflared：

    ENABLE_CLOUDFLARED=true
    TUNNEL_TOKEN=你的Token

部署完成后：

进入 Logs 查看节点信息。

## 三、Railway 部署

1.  导入 GitHub 项目。

2.  Railway 自动读取 Dockerfile。

3.  部署完成：

打开：

    Deployments
    → Logs

复制输出的节点参数。

## 四、客户端配置

支持：

-   V2RayN
-   V2RayNG
-   Nekoray
-   Hiddify

参数：

协议：

    VLESS

传输：

    TCP

安全：

    Reality

Flow：

    xtls-rprx-vision

填写：

-   UUID
-   PublicKey
-   ShortID
-   SNI

## 五、Cloudflared 可选模块

Easkoy 默认只运行 sing-box。

如需 Tunnel：

设置：

    ENABLE_CLOUDFLARED=true

并提供：

    TUNNEL_TOKEN

## 六、故障排查

查看日志：

``` bash
docker logs easkoy
```

检查：

-   443端口是否开放
-   UUID是否正确
-   Reality参数是否匹配
-   防火墙规则

## 七、安全建议

-   不公开 UUID
-   定期更新 Reality 密钥
-   不共享完整节点链接
-   使用可靠 SNI
