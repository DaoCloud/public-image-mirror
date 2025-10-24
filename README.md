# public-image-mirror

源仓库 [Github](https://github.com/DaoCloud/public-image-mirror)  
Mirror 仓库 [Gitee](https://gitee.com/daocloud/public-image-mirror)  

- 白名单 & 限流 的公开信息 [#2328](https://github.com/DaoCloud/public-image-mirror/issues/2328)
- 如有疑问请咨询 [#4183](https://github.com/DaoCloud/public-image-mirror/issues/4183)
- 建议将拉取任务放在闲时 凌晨(北京时间 01-07 点), 其他时间段非常拥挤
- 建议使用明确版本号的 tag, 对于 latest 这种变更后响应旧数据, 并且后台重新同步
- 本服务后端 [OpenCIDN](https://github.com/OpenCIDN)

## 背景 & 目标

很多镜像都在国外。比如 gcr 。国内下载很慢，需要加速。

* 一个简洁有效的方法能够加速这些包。简洁的名称映射
* 易于添加，添加新的包，不需要去修改代码。
* 稳定可靠，更新实时。每天检查同步情况。
* 此项目仅是源镜像仓库 (Registry) 的 Mirror
  * 所有 hash(sha256) 均和源保持一致 (懒加载机制)。
  * 由于缓存的存在, 可能存在 1 小时的延迟。
* 对于 镜像层(blob) 会缓存在第三方对象存储上
  * 当前暂未对内容做任何检测, 计划会添加检测。
  * 不定期会清理一次缓存。

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

## 无缓存

在拉取的时候如果我们没有缓存, 将会在 [同步队列](https://queue.m.daocloud.io/status/) 添加同步缓存的任务.

## 支持前缀替换的 Registry (不推荐)

推荐使用添加前缀的方式.

前缀替换的 Registry 的规则, 这是人工配置的, 有需求提 Issue.

| 源站               | 替换为                | 备注                                           |
| ------------------ | --------------------- | ---------------------------------------------- |
| docker.elastic.co  | elastic.m.daocloud.io |                                                |
| docker.io          | docker.m.daocloud.io  |                                                |
| gcr.io             | gcr.m.daocloud.io     |                                                |
| ghcr.io            | ghcr.m.daocloud.io    |                                                |
| k8s.gcr.io         | k8s-gcr.m.daocloud.io | k8s.gcr.io 已被迁移到 registry.k8s.io          |
| registry.k8s.io    | k8s.m.daocloud.io     |                                                |
| mcr.microsoft.com  | mcr.m.daocloud.io     |                                                |
| nvcr.io            | nvcr.m.daocloud.io    |                                                |
| quay.io            | quay.m.daocloud.io    |                                                |
| registry.ollama.ai | ollama.m.daocloud.io  | 实验内测中，[使用方法](#加速-ollama--deepseek) |

## 最佳实践

### 加速 Kubneretes

#### 加速安装 kubeadm
``` bash
kubeadm config images pull --image-repository k8s-gcr.m.daocloud.io
```

#### 加速安装 kind

``` bash
kind create cluster --name kind --image m.daocloud.io/docker.io/kindest/node:v1.22.1
```

#### 加速所有 Pod

https://github.com/wzshiming/repimage

不修改 yaml, helm 等, 仅使用 Webhook, 自动修改所有新建 Pod 的 image 使用本 mirror

``` bash
kubectl create -f https://files.m.daocloud.io/github.com/wzshiming/repimage/releases/download/latest/repimage.yaml
kubectl rollout status deployment/repimage -n kube-system
```

#### 加速 Containerd

* 参考 Containerd 官方文档: [hosts.md](https://github.com/containerd/containerd/blob/main/docs/hosts.md#registry-host-namespace)
* 如果您使用 kubespray 安装 containerd, 可以配置 [`containerd_registries_mirrors`](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/CRI/containerd.md#containerd-config)

### 加速 Docker

添加到 `/etc/docker/daemon.json`
``` json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io"
  ]
}
```

### 加速 Ollama & DeepSeek

#### 加速安装 Ollama

CPU:
```bash
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama docker.m.daocloud.io/ollama/ollama
```

GPU 版本:
1. 首先安装 Nvidia Container Toolkit
2. 运行以下命令启动 Ollama 容器：

```bash
docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama docker.m.daocloud.io/ollama/ollama
```

更多信息请参考：
* [Ollama Docker 官方文档](https://ollama.com/blog/ollama-is-now-available-as-an-official-docker-image)

#### 加速使用 Deepseek-R1 模型（实验内测中）

如上述步骤，在启动了ollama容器的前提下，还可以通过加速源，加速启动DeepSeek相关的模型服务

注：目前 Ollama 官方源的下载速度已经很快，您也可以直接使用[官方源](https://ollama.com/library/deepseek-r1:1.5b)。

```bash
# 使用加速源
docker exec -it ollama ollama run ollama.m.daocloud.io/library/deepseek-r1:1.5b

# 或直接使用官方源下载模型
# docker exec -it ollama ollama run deepseek-r1:1.5b
```

## [友情链接]加速二剑客

* 镜像加速：https://github.com/DaoCloud/public-image-mirror
* 二进制文件加速：https://github.com/DaoCloud/public-binary-files-mirror

## 贡献者

<a href="https://github.com/DaoCloud/public-image-mirror/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=DaoCloud/public-image-mirror" />
</a>

Made with [contrib.rocks](https://contrib.rocks).
