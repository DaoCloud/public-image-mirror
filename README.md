# public-image-mirror

[![Sync](https://github.com/DaoCloud/public-image-mirror/raw/gh-pages/daocloud-sync-badge.svg)](https://github.com/DaoCloud/public-image-mirror/raw/gh-pages/daocloud-sync.log)

Sync: 是 tag 的同步率 只要 tag 存在就是同步的

## 背景
很多镜像都在国外。比如 gcr 。国内下载很慢，需要加速。

## 目标

* 一个简洁有效的方法能够加速这些包。简洁的名称映射
* 易于添加，添加新的包，不需要去修改代码。
* 稳定可靠，更新实时。每天检查同步情况。

## 快速开始

```
docker run -d -P m.daocloud.io/docker.io/library/nginx
```

## 支持的镜像

[mirror.txt](mirror.txt)

如果想要新增, 提 PR 修改即可。例如 [PR#1](https://github.com/DaoCloud/public-image-mirror/pull/1/)， 并请在 PR 提交前排序： `./hack/fmt.sh mirror.txt`

## 使用方法

**增加前缀** (推荐方式)。比如：
```
k8s.gcr.io/coredns/coredns => m.daocloud.io/k8s.gcr.io/coredns/coredns
```

或者 支持的镜像仓库 的 *前缀替换* 就可以使用。比如：

```
k8s.gcr.io/coredns/coredns => k8s-gcr.m.daocloud.io/coredns/coredns
```

### 懒加载

**支持懒加载**, 就算不在同步列表中也能 **直接拉取**, 初次拉取会比已经同步过的慢一些, 并且[每 7 天会清理一次缓存](https://github.com/distribution/distribution/blob/e3509fc1deedaab489dd8829cc438de8f4c77fc3/registry/proxy/proxymanifeststore.go#L15).

如果只是临时使用的就不需要往同步列表里加了.

如果您看到下没有进度这是正常现象, 由于带宽有限只要有几人在下较大的文件就会阻塞后续的下载, 可以稍后中断下载重新再试.

## 提前同步的 Registry

[domain.txt](domain.txt)

用于 github action 从源 registry 提前同步到 m.daocloud.io 下

如果想要新增, 提 PR 修改即可。例如 [PR#28](https://github.com/DaoCloud/public-image-mirror/pull/28),  并请在 PR 提交前排序：`./hack/fmt.sh domain.txt`

## 支持前缀替换的 Registry

## 前缀替换的 Registry 的规则

如有新增, 提 PR 修改下面的表格, 合并后由人工配置

| 源站                    | 替换为                        |
| ----------------------- | ----------------------------- |
| cr.l5d.io               | l5d.m.daocloud.io             |
| docker.elastic.co       | elastic.m.daocloud.io         |
| docker.io               | docker.m.daocloud.io          |
| gcr.io                  | gcr.m.daocloud.io             |
| ghcr.io                 | ghcr.m.daocloud.io            |
| k8s.gcr.io              | k8s-gcr.m.daocloud.io         |
| registry.k8s.io         | k8s.m.daocloud.io             |
| mcr.microsoft.com       | mcr.m.daocloud.io             |
| nvcr.io                 | nvcr.m.daocloud.io            |
| quay.io                 | quay.m.daocloud.io            |
| registry.jujucharms.com | jujucharms.m.daocloud.io      |
| rocks.canonical.com     | rocks-canonical.m.daocloud.io |

## 最佳实践
* 通过 加速 安装 kubeadm
``` bash
kubeadm config images pull --image-repository k8s-gcr.m.daocloud.io
```

* 通过 加速 安装 kind

``` bash
kind create cluster --name kind --image docker.m.daocloud.io/kindest/node:v1.22.1
``` 

* 通过 加速 部署 应用(这里以 Ingress 为例)

``` bash
wget -O image-filter.sh https://github.com/DaoCloud/public-image-mirror/raw/main/hack/image-filter.sh && chmod +x image-filter.sh

wget -O deploy.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/baremetal/deploy.yaml

cat ./deploy.yaml | ./image-filter.sh | kubectl apply -f -
``` 

* Docker 加速

添加到 `/etc/docker/daemon.json`
``` json
  "registry-mirrors": [
    "https://docker.m.daocloud.io"
  ]
```

## [友情链接]加速三剑客

* 镜像加速：https://github.com/DaoCloud/public-image-mirror
* 二进制文件加速：https://github.com/DaoCloud/public-binary-files-mirror
* Helm 加速：https://github.com/DaoCloud/public-helm-charts-mirror


## 贡献者

<a href="https://github.com/DaoCloud/public-image-mirror/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=DaoCloud/public-image-mirror" />
</a>

Made with [contrib.rocks](https://contrib.rocks).


