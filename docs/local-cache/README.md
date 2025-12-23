# 部署内网缓存

## 简介

本地缓存部署用于在内网环境中加速镜像拉取，减少对外网的依赖。通过设置一个本地镜像仓库，您可以缓存常用的镜像。

## 部署步骤

1. **准备环境**  

确保已安装 Docker 和 Docker Compose。

2. **配置 Docker Compose 文件**  

创建一个 `docker-compose.yml` 文件：

```yaml
services:
  registry:
    image: m.daocloud.io/docker.io/library/registry:3
    restart: unless-stopped
    ports:
    - 8888:8888
    command:
    - /etc/docker/registry/config.yml
    volumes:
    - cache-data:/var/lib/registry
    configs:
    - source: registry-config
      target: /etc/docker/registry/config.yml

configs:
  registry-config:
    content: |
      version: 0.1
      storage:
        delete:
          enabled: true
        filesystem:
          rootdirectory: /var/lib/registry
      http:
        addr: :8888
      proxy:
        remoteurl: https://m.daocloud.io
        ttl: 2160h
volumes:
  cache-data: {}
```

4. **启动服务**  
```bash
docker-compose up -d
```

5. **配置 Docker 客户端**  
在 `/etc/docker/daemon.json` 中添加以下内容：
```json
{
  "insecure-registries": ["<your-registry-ip>:<your-registry-port>"]
}

```
然后重启 Docker 服务：
```bash
systemctl restart docker
```

## 用法

现在您的 `<your-registry-ip>:<your-registry-port>/` 已经是 `m.daocloud.io/` 的本地缓存代理

后续就像 `m.daocloud.io` 加前缀一样, 只需要在原始镜像地址前加上 `<your-registry-ip>:<your-registry-port>/` 即可。

例如，拉取 `docker.io/library/nginx:latest` 镜像，可以使用以下命令：
```bash
docker pull <your-registry-ip>:<your-registry-port>/docker.io/library/nginx:latest
```

