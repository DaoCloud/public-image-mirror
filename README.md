# public-image-mirror

[![Sync](https://gist.github.com/wzshiming/6e1f67a5184f93cefc5b2c670a5813e5/raw/daocloud-sync-badge.svg)](https://gist.github.com/wzshiming/6e1f67a5184f93cefc5b2c670a5813e5/raw/daocloud-sync.log)
[![Deep Sync](https://gist.github.com/wzshiming/6e1f67a5184f93cefc5b2c670a5813e5/raw/daocloud-deep-sync-badge.svg)](https://gist.github.com/wzshiming/6e1f67a5184f93cefc5b2c670a5813e5/raw/daocloud-deep-sync.log)

## 背景
很多镜像都在国外。比如 gcr 。国内下载很慢，需要加速。

## 目标

* 一个简洁有效的方法能够加速这些包。简洁的名称映射
* 易于添加，添加新的包，不需要去修改代码。
* 稳定可靠，更新实时。每天检查同步情况。

## 快速开始

```
docker run -d -P docker.m.daocloud.io/nginx
```




## 使用方法

支持的镜像仓库 的 *前缀替换* 就可以使用。比如：

k8s.gcr.io/coredns/coredns => k8s-gcr.m.daocloud.io/coredns/coredns

## 替换规则

| 源站              | 替换为                |
| ----------------- | --------------------- |
| gcr.io            | gcr.m.daocloud.io     |
| k8s.gcr.io        | k8s-gcr.m.daocloud.io |
| docker.io         | docker.m.daocloud.io  |
| quay.io           | quay.m.daocloud.io    |
| ghcr.io           | ghcr.m.daocloud.io    |
| mcr.microsoft.com | mcr.m.daocloud.io     |

## 支持的镜像源

[domain.txt](domain.txt)

如果想要新增, 提 PR 修改即可。例如 [PR#28](https://github.com/DaoCloud/public-image-mirror/pull/28)

## 支持的镜像

[mirror.txt](mirror.txt)

如果想要新增, 提 PR 修改即可。例如 [PR#1](https://github.com/DaoCloud/public-image-mirror/pull/1/)

## 最佳实践
* 通过 加速 安装 kubeadm
``` bash
# 使用 kubeadm 安装的时候指定 --image-repository 参数, 指定安装的镜像前缀
kubeadm config images pull --image-repository k8s-gcr.m.daocloud.io
```

* 通过 加速 安装 kind


``` bash
kind create cluster --name kind  --image docker.m.daocloud.io/kindest/node:v1.22.1
``` 

