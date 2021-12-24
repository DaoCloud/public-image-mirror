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

| 源站                    | 替换为                        |
| ----------------------- | ----------------------------- |
| cr.l5d.io               | l5d.m.daocloud.io             |
| docker.elastic.co       | elastic.m.daocloud.io         |
| docker.io               | docker.m.daocloud.io          |
| gcr.io                  | gcr.m.daocloud.io             |
| ghcr.io                 | ghcr.m.daocloud.io            |
| k8s.gcr.io              | k8s-gcr.m.daocloud.io         |
| mcr.microsoft.com       | mcr.m.daocloud.io             |
| nvcr.io                 | nvcr.m.daocloud.io            |
| quay.io                 | quay.m.daocloud.io            |
| registry.jujucharms.com | jujucharms.m.daocloud.io      |
| rocks.canonical.com     | rocks-canonical.m.daocloud.io |

## 支持的镜像源

[domain.txt](domain.txt)

如果想要新增, 提 PR 修改即可。例如 [PR#28](https://github.com/DaoCloud/public-image-mirror/pull/28)

## 支持的镜像

[mirror.txt](mirror.txt)

如果想要新增, 提 PR 修改即可。例如 [PR#1](https://github.com/DaoCloud/public-image-mirror/pull/1/)

## 最佳实践
* 通过 加速 安装 kubeadm
``` bash
kubeadm config images pull --image-repository k8s-gcr.m.daocloud.io
```

* 通过 加速 安装 kind

``` bash
kind create cluster --name kind  --image docker.m.daocloud.io/kindest/node:v1.22.1
``` 

* 通过 加速 部署 应用(这里以 Ingress 为例)

``` bash
wget -o image-filter.sh https://github.com/DaoCloud/public-image-mirror/raw/main/hack/image-filter.sh && chmod +x image-filter.sh

wget -o deploy.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/baremetal/deploy.yaml

cat ./deploy.yaml | ./image-filter.sh | kubectl apply -f -
``` 
