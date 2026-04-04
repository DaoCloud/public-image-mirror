---
name: public-image-mirror-approver
description: DaoCloud public-image-mirror 白名单审批申请。
---

# public-image-mirror 白名单审批技能

DaoCloud public-image-mirror 白名单审批申请。

## 快速开始

```bash
# 1. 查看待审批的 issue
gh issue list --repo DaoCloud/public-image-mirror --label "allows image" --state open

# 2. 查看详情
gh issue view <issue_number> --repo DaoCloud/public-image-mirror

# 3. 检查白名单（支持通配符）
gh api repos/DaoCloud/public-image-mirror/contents/allows.txt --jq '.download_url' | xargs curl -sL | grep -iE "^docker.io/alpine/"
```

## 审批规则（基于 Issue #2328）

### ✅ 通过标准（全部满足）

1. **开源项目**（有源码，非仅编译产物）
2. **GitHub star > 10**（或同源平台的等效 star 数）
3. **镜像与源码有实际关联**（文档/官方推荐）
4. **无违规内容**（禁止盗版/魔法/科学上网）

### ⚠️ 特殊情况（可免除源码关联）

| 情况 | 处理 |
|------|------|
| Verified Publisher | 可免除源码关联证明 |
| Sponsored OSS | 可免除源码关联证明 |
| Official Image | 可免除源码关联证明 |
| fork 项目 | GitHub star > 10 即可 |
| 整个组织申请 | 需验证该组织下所有镜像 |
| 通配符 `*` / `**` 规则 | 整个命名空间都通过审批 |

### ❌ 驳回原因

| 驳回原因 | 说明 |
|----------|------|
| 仅构建产物无源码 | 没有源代码的发布产物 |
| 非开源项目 | 非正当的开源项目 |
| star ≤ 10 | 项目热度过低 |
| 违规内容 | 涉及魔法/科学上网/盗版等 |

## 白名单通配符规则

| 模式 | 含义 | 示例 |
|------|------|------|
| `*` | 匹配任意字符（不含斜杠） | `docker.io/alpine/*` 匹配 `docker.io/alpine/latest`，但不匹配 `docker.io/alpine/v3/18` |
| `**` | 匹配任意字符（含斜杠） | `docker.io/alpinelinux/**` 匹配 `docker.io/alpinelinux/v3/18` |
| 无通配符 | 精确匹配 | `docker.io/nginx/nginx-unprivileged` 仅匹配此镜像 |

### 白名单匹配示例

```bash
# allows.txt 内容示例
docker.io/alpine/*
docker.io/alpinelinux/**
docker.io/nginx/nginx-unprivileged
ghcr.io/*

# 检查 docker.io/alpine/latest 是否在白名单
# 匹配规则（按优先级）:
# 1. 精确匹配: docker.io/nginx/nginx-unprivileged
# 2. 前缀匹配 + /*: docker.io/alpine/* (不匹配含更多斜杠的)
# 3. 前缀匹配 + /**: docker.io/alpinelinux/** (匹配所有)
# 4. ghcr.io/* (匹配 ghcr.io 下的所有镜像)
```

### 通配符场景处理

| 申请内容 | 白名单已有 | 结果 |
|----------|-----------|------|
| `docker.io/alpine/v3.18` | `docker.io/alpine/*` | ✅ 已存在 |
| `docker.io/alpine/v3.18/x86_64` | `docker.io/alpine/*` | ❌ 不匹配（斜杠） → 需新增 |
| `docker.io/alpine/v3.18/x86_64` | `docker.io/alpinelinux/**` | ✅ 已存在 |
| `docker.io/myorg/myimage` | `docker.io/*` | ✅ 已存在 |
| `ghcr.io/myorg/myimage` | `ghcr.io/*` | ✅ 已存在 |

## 审批流程

### 第一步：获取待审批列表

```bash
gh issue list --repo DaoCloud/public-image-mirror --label "allows image" --state open
```

### 第二步：逐个验证

```bash
# 申请详情
gh issue view <issue_number> --repo DaoCloud/public-image-mirror

# 提取申请的镜像（从 Issue 标题或正文）
IMAGE="docker.io/alpine/v3.18"

# 白名单是否存在（支持通配符匹配）
gh api repos/DaoCloud/public-image-mirror/contents/allows.txt --jq '.download_url' | xargs curl -sL | grep -iE "^$IMAGE$"

# 也可用前缀匹配检查通配符规则
gh api repos/DaoCloud/public-image-mirror/contents/allows.txt --jq '.download_url' | xargs curl -sL | grep -iE "^docker.io/alpine/(\\*|\\*\\*)?$"

# GitHub 项目信息
gh api repos/<owner>/<repo> --jq '.stargazers_count, .description'
```

### 第三步：按 Registry 类型验证来源

根据镜像的 Registry 类型，验证其真实来源：

| Registry | 验证来源 | 检查内容 |
|----------|----------|----------|
| `docker.io` | hub.docker.com | 源码链接、star 数、官方认证 |
| `ghcr.io` | github.com | GitHub 仓库、star 数、package 信息 |
| `gcr.io` | github.com | 官方项目或 Google 关联仓库 |
| `quay.io` | github.com 或项目官网 | 源码仓库、star 数 |
| `registry.k8s.io` | kubernetes/kubernetes | 官方 Kubernetes 镜像 |
| 其他 Registry | 项目官网或源码仓库 | 验证镜像与源码关联 |

#### 各 Registry 验证命令

```bash
# docker.io → 检查 hub.docker.com
curl -s "https://hub.docker.com/v2/repositories/<namespace>/<repo>/" | jq '.star_count, .pull_count, .description'
# 或获取详情
curl -sL "https://hub.docker.com/v2/repositories/<namespace>/<repo>" | jq -r '.full_description' | head -100

# ghcr.io → 检查 GitHub Package
gh api packages/container/<package>/versions --jq '.[].metadata.container.tags'
gh api packages/container/<package> --jq '.repository.name, .visibility'

# 检查镜像标签
curl -s "https://hub.docker.com/v2/repositories/<namespace>/<repo>/tags" | jq '.results[].name'
```

### 第四步：使用 GitHub 源码搜索验证镜像关联（推荐）

当申请人提供了 GitHub 源码地址时，**主动搜索源码仓库**验证镜像关联性，而不仅依赖申请人提供的信息：

```bash
# 从 Issue 中提取镜像地址
IMAGE="docker.io/john119/vlm"
NAMESPACE=$(echo "$IMAGE" | cut -d'/' -f2)
REPO_NAME=$(echo "$IMAGE" | cut -d'/' -f3)

# 假设申请人在 Issue 中提供了源码仓库
SOURCE_REPO="2U1/Qwen-VL-Series-Finetune"

# 方法1: 直接读取 README.md 搜索 Docker 相关内容
gh api repos/$SOURCE_REPO/contents/README.md --jq '.download_url' | xargs curl -sL | grep -iE "(docker pull|docker run|hub.docker.com|$NAMESPACE/$REPO_NAME)"

# 方法2: 检查仓库是否有 Dockerfile 或 DOCKER.md
gh api repos/$SOURCE_REPO/contents --jq '.[] | select(.type == "file" or .type == "dir") | .name' | grep -iE "(dockerfile|docker)"

# 方法3: 使用 GitHub code search 搜索仓库中是否提到该镜像
gh api search/code --method GET -q '.items[] | .path' -F q="repo:$SOURCE_REPO docker pull $NAMESPACE/$REPO_NAME"
```

#### ✅ 关联性验证成功示例

```
# Issue #45196 - john119/vlm 验证过程
gh api repos/2U1/Qwen-VL-Series-Finetune/contents/README.md | xargs curl -sL | grep -i docker

# 输出结果（证明关联）:
# You could find more information about the image here (https://hub.docker.com/repository/docker/john119/vlm/general)
# docker pull john119/vlm
# docker run --gpus all -it ... john119/vlm /bin/bash
```

```
# Issue #45179 - localstack/localstack 验证过程
gh api repos/localstack/localstack/contents --jq '.[] | .name' | grep -i docker

# 输出结果（证明 Official Image）:
# .dockerignore
# DOCKER.md
# Dockerfile
# Dockerfile.s3
# docker-compose-pro.yml
```

#### ⚠️ 关联性验证失败示例

```bash
# 假设仓库中没有提到该镜像
gh api repos/some-random-repo/contents/README.md | xargs curl -sL | grep -iE "(docker pull|myimage)"
# 输出：无结果 → 需要让申请人补充更多证明
```

### 第五步：决策

| 情况 | 决定 |
|------|------|
| 符合标准 | ✅ 通过 → 提交 PR |
| 已在白名单 | ⚠️ 告知已存在 → Issue 回复 |
| 信息缺失 | ⚠️ 要求补充 → Issue 回复 |
| 不符合标准 | ❌ 驳回 → Issue 回复 |

## 提交 PR 流程（非交互式）

> ⚠️ 所有命令设计为非交互式，避免 git/gh 阻塞

### 1. 配置 git

```bash
# 设置 git 用户信息
git config --global user.name "$(gh api user --jq '.name // "zsmbot"')" && \
git config --global user.email "$(gh api user --jq '.email // "users+noreply@github.com"')"
```

### 2. Fork & Clone (使用 GH_TOKEN)

```bash
# 使用 gh fork, 如果已 fork 则继续
gh repo fork DaoCloud/public-image-mirror --clone=false --remote=true

# 获取你的用户名
MY_GITHUB_USER=$(gh api user --jq '.login')

# 克隆到本地（使用 gh clone 自动处理认证）
gh repo clone $MY_GITHUB_USER/public-image-mirror -- -o gh

cd public-image-mirror

# 同步最新代码
gh repo sync DaoCloud/public-image-mirror

# > ⚠️ 非常重要：切换为 GH_TOKEN 认证 (替换 remote URL)
git remote set-url gh https://$GH_TOKEN@github.com/$MY_GITHUB_USER/public-image-mirror.git
```

### 3. 创建分支 & 修改

```bash
git checkout -b allows/<issue_number>
# 编辑 allows.txt 添加: docker.io/<namespace>/<repo>
# 或通配符: docker.io/<namespace>/*  或 docker.io/<namespace>/**
```

### 4. 格式化 & 提交

> ⚠️ 非常重要：修改 allows.txt 后必须运行格式化脚本

```bash
# 格式化 allows.txt（自动排序、去重）
./hack/fmt-image-match.sh allows.txt

# 提交
git add allows.txt && git commit -m "Allow: add <镜像> to allows.txt (Fixed #<issue_number>)"

# 推送到远程
git push -u gh allows/<issue_number> -q
```

### 5. 创建 PR

```bash
# 单 Issue 修复
gh pr create --repo DaoCloud/public-image-mirror \
  --title "Allow: add <镜像> to allows.txt" \
  --body "Fixed #<issue_number>

/auto-cc
"

# 多 Issue 修复（每行一个 Fixed）
gh pr create --repo DaoCloud/public-image-mirror \
  --title "Allow: add <镜像1>, <镜像2> to allows.txt" \
  --body "Fixed #<issue1>
Fixed #<issue2>
Fixed #<issue3>

/auto-cc
"
```

## PR Body 模板

### 基本格式

```
Fixed #<issue_number>

/auto-cc
```

### 多 Issue 修复（每行一个 Fixed）

```
Fixed #<issue1>
Fixed #<issue2>
Fixed #<issue3>

/auto-cc
```

### 带详细 Verification

```
Fixed #<issue1>
Verification:
- Source: <链接>
- Reason: <理由>

Fixed #<issue2>
Verification:
- Source: <链接>
- Reason: <理由>

/auto-cc
```

### ⚠️ 重要规则

- **每行一个 `Fixed #xxx`**，不要用逗号分隔
- `/auto-cc` 用于召唤审批人
- Verification 部分帮助审批人快速验证

### ❌ 错误示例

```
Fixed #45196, #45179, #45168
```

### ✅ 正确示例

```
Fixed #45196
Fixed #45179
Fixed #45168

/auto-cc
```

## Issue 回复模板

### ✅ 通过

```markdown
## 审批结果：通过

**镜像**: `docker.io/<namespace>/<repo>`

**验证通过**:
- ✅ 开源项目，有源码
- ✅ GitHub star > 10
- ✅ 镜像与源码有关联（GitHub 源码搜索验证）

已提交 PR: <PR链接>
```

### ✅ 通过（Official Image/Verified Publisher 免除源码关联）

```markdown
## 审批结果：通过

**镜像**: `docker.io/<namespace>/<repo>`

**验证通过**:
- ✅ 知名开源项目（GitHub star > 10）
- ✅ Official Image / Verified Publisher（免除源码关联）
- ✅ 仓库中有 Dockerfile/DOCKER.md 等官方 Docker 文件

已提交 PR: <PR链接>
```

### ⚠️ 已存在（精确匹配）

```markdown
## 审批结果：已存在

**镜像**: `docker.io/<namespace>/<repo>`

**白名单已存在**: 直接精确匹配

/close
```

### ⚠️ 已存在（通配符覆盖）

```markdown
## 审批结果：已存在

**镜像**: `docker.io/<namespace>/<repo>`

**白名单已有通配符**: `docker.io/<namespace>/*`（或 `**`）

/close
```

### ⚠️ 需补充信息

```markdown
## 审批结果：需补充信息

**缺少**:
- ❌ 项目源码地址
- ❌ 镜像关联证明

**请补充**: 提供源码地址及文档链接, 再新开 Issue

/close
```

### ❌ 驳回

```markdown
## 审批结果：驳回

**驳回原因**:
- 项目 star ≤ 10
- 仅构建产物无源码
- 仅为国内用户服务
- 违规内容（魔法/盗版等）

**建议**: 国内作者可尝试阿里云镜像仓库、华为云镜像仓库等

当前由 AI 自动审批, 如有疑问 @wzshiming

/close
```

## 常用命令速查

### 验证命令

```bash
# 白名单检查
gh api repos/DaoCloud/public-image-mirror/contents/allows.txt --jq '.download_url' | xargs curl -sL | grep -iE "<关键词>"

# 白名单精确匹配
gh api repos/DaoCloud/public-image-mirror/contents/allows.txt --jq '.download_url' | xargs curl -sL | grep -iE "^docker.io/nginx/nginx-unprivileged$"

# 白名单通配符匹配（/* 或 /**）
gh api repos/DaoCloud/public-image-mirror/contents/allows.txt --jq '.download_url' | xargs curl -sL | grep -iE "^docker.io/nginx/"

# GitHub star
gh api repos/<owner>/<repo> --jq '.stargazers_count'

# docker.io → Docker Hub 信息
curl -s "https://hub.docker.com/v2/repositories/<namespace>/<repo>/" | jq '.star_count, .pull_count'
curl -sL "https://hub.docker.com/v2/repositories/<namespace>/<repo>" | jq -r '.full_description' | head -100

# ghcr.io → GitHub Package 信息
gh api packages/container/<package> --jq '.repository.name, .visibility, .updated_at'
gh api packages/container/<package>/versions --jq 'length'

# ghcr.io → 对应 GitHub 仓库
gh api repos/<owner>/<repo> --jq '.stargazers_count, .description'

# quay.io → GitHub 仓库
gh api repos/<owner>/<repo> --jq '.stargazers_count, .description'
```

### GitHub 源码搜索验证命令

```bash
# 读取 README.md 搜索 Docker 相关内容
gh api repos/<owner>/<repo>/contents/README.md --jq '.download_url' | xargs curl -sL | grep -iE "(docker pull|docker run|hub.docker)"

# 检查仓库是否有 Dockerfile、DOCKER.md 等 Docker 相关文件
gh api repos/<owner>/<repo>/contents --jq '.[] | select(.type == "file" or .type == "dir") | .name' | grep -iE "(dockerfile|docker)"

# 使用 GitHub code search 搜索仓库中是否提到特定镜像
gh api search/code --method GET -q '.items[] | .path' -F q="repo:<owner>/<repo> docker pull <namespace>/<repo_name>"
```

### 用户信息

```bash
gh api user                    # 完整 JSON
gh api user --jq '.login'      # 用户名
gh api user --jq '.name'        # 姓名
gh api user --jq '.email'       # 邮箱
```

## 参考链接

- 仓库: https://github.com/DaoCloud/public-image-mirror
- 白名单规则: https://github.com/DaoCloud/public-image-mirror/issues/2328
- PR 示例: https://github.com/DaoCloud/public-image-mirror/pull/23762
