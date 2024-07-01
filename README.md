# public-image-mirror

[![Sync](https://github.com/DaoCloud/public-image-mirror/raw/gh-pages/daocloud-sync-badge.svg)](https://github.com/DaoCloud/public-image-mirror/raw/gh-pages/daocloud-sync.log)

Sync: 定期同步列表里的 image tag 的同步率, 只要 tag 存在就是同步的.

**由于近期使用量剧增, 为保证大多数的可用性**

- 白名单 & 限流 & 降级 的公开信息 [#2328](https://github.com/DaoCloud/public-image-mirror/issues/2328)
- 如有疑问请咨询企微群 [#4183](https://github.com/DaoCloud/public-image-mirror/issues/4183)

## 背景 & 目标

很多镜像都在国外。比如 gcr 。国内下载很慢，需要加速。

* 一个简洁有效的方法能够加速这些包。简洁的名称映射
* 易于添加，添加新的包，不需要去修改代码。
* 稳定可靠，更新实时。每天检查同步情况。
* 此项目仅是源镜像仓库 (Registry) 的 Mirror
  * 所有 hash(sha256) 均和源保持一致 (懒加载机制)。
  * 由于缓存的存在, 可能存在 1 小时的延迟。
  * 如超过 1 小时还未更新, 估计是国际带宽挂了。
* 对于 镜像层(blob) 会缓存在第三方对象存储上
  * 当前暂未对内容做任何检测。

## 快速开始

```
docker run -d -P m.daocloud.io/docker.io/library/nginx
```
## 使用方法

**增加前缀** (推荐方式)。比如：

``` log
              docker.io/library/busybox
                 |
                 V
m.daocloud.io/docker.io/library/busybox
```

或者 支持的镜像仓库 的 *前缀替换* 就可以使用。比如：

``` log
           docker.io/library/busybox
             |
             V
docker.m.daocloud.io/library/busybox
```

## 单次单镜像同步

**!!!!!!!!!!!!!!!!!!!!!!!!强烈推荐!!!!!!!!!!!!!!!!!!!!!!!!**

您可以根据 [镜像同步 Issue 模板](https://github.com/DaoCloud/public-image-mirror/issues/new?labels=sync+image&template=sync-image.yml) 创建一个 Issue, 将会有机器人帮您优先主动同步指定的镜像

> 原先已经在下的镜像还是会继续走原来的, 需要重启 docker 再重新拉取才能走已经同步好的缓存过, 所以推荐先单次同步再尝试拉取
> 对于 latest 这种经常内容会发生变更的 tag 变更后会需要重新同步

每个 Issue **带宽**
- 国际带宽 3 * 50 Mbps

## 懒加载

> 仅推荐用于小于 20MiB 的镜像
> 这条通道主要用于保持 image 是最新的, 每次拉取都会检查是否和上游保持同步

如果您看到下没有进度这是由于带宽有限只要有几人在下较大的文件就会阻塞后续的下载, 可以尝试[单次单镜像同步](#单次单镜像同步)

就算没同步也能 **直接拉取**, 初次拉取会比已经同步过的慢.

所有懒加载 **带宽**
- 国际带宽 6 * 30 Mbps

## 定期同步列表

> 不推荐, 由于数量已经比较多了初次提交, 到被同步到需要很长时间

强烈建议使用[单次单镜像同步](#单次单镜像同步)

[mirror.txt](mirror.txt)

如果想要新增, 提 PR 修改即可。例如 [PR#1](https://github.com/DaoCloud/public-image-mirror/pull/1/)， 并请在 PR 提交前排序： `./hack/fmt.sh mirror.txt`

## 支持前缀替换的 Registry (不推荐)

部分工具或库可能会提示未验证的错误, 如 podman, [google/go-containerregistry](https://github.com/google/go-containerregistry) 等, 推荐使用添加前缀的方式.

前缀替换的 Registry 的规则, 这是人工配置的, 有需求提 Issue.

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
kind create cluster --name kind --image m.daocloud.io/docker.io/kindest/node:v1.22.1
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
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io"
  ]
}
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
