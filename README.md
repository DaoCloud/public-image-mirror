# public-image-mirror

## 背景
很多镜像都在国外。比如 gcr 。国内下载很忙，需要加速。

## 目标

* 一个简洁有效的方法能够加速这些包。简洁的名称映射
* 易于添加，添加新的包，不需要去修改代码。
* 稳定可靠

## 快速开始

```
docker run -d -P docker.m.daocloud.io/nginx

```




## 使用方法

支持的镜像仓库 的 *前缀替换* 就可以使用。比如：

k8s.gcr.io/coredns/coredns => k8s-gcr.m.daocloud.io/coredns/coredns

## 替换规则

| 源站     | 替换为 |
| -------  | ------- |
| gcr.io  |  gcr.m.daocloud.io       |
| k8s.gcr.io  |  k8s-gcr.m.daocloud.io      |
| docker.io  |  docker.m.daocloud.io      |
| quay.io  |  quay.m.daocloud.io     |
| ghcr.io  | ghcr.m.daocloud.io   |

## 支持的仓库

[mirror.txt](mirror.txt)

## 增加新的仓库

提 PR , 修改 mirror.txt 即可。例如 [PR#1](https://github.com/DaoCloud/public-image-mirror/pull/1/)

## 如何查看同步情况

TODO


## 安装运行

安装skepo.
```
yum install skopeo --nobest
```


运行同步程序

```
export REGISTRY_PASSWORD=password #镜像仓库密码
python scripts/sync-to-jp.py
```


## 最佳实践
* 通过 加速 安装 kubeadm
* 通过 加速 运行 artifacthub 上的镜像
* 通过 加速 安装 kind

