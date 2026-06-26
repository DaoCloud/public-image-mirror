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

| 情况                   | 处理                         |
| ---------------------- | ---------------------------- |
| Verified Publisher     | 可免除源码关联证明（需验证） |
| Sponsored OSS          | 可免除源码关联证明（需验证） |
| Official Image         | 可免除源码关联证明（需验证） |
| 整个组织申请           | 需验证该组织下所有镜像       |
| 通配符 `*` / `**` 规则 | 整个命名空间都通过审批       |

### ⚠️ 重要：必须验证

> ⚠️ **教训**：申请人可能提供错误信息，必须通过验证，不能仅依赖申请人声明。

三种 Docker Hub badge 的验证方法（网页匹配 aria-label）：

| Badge 类型 | aria-label 值 | 免除源码关联 |
| ---------- | ------------- | ------------ |
| Verified Publisher | `Verified Publisher` | ✅ |
| Sponsored OSS | `Sponsored OSS` | ✅ |
| Official Image | `Docker Official Image` | ✅ |

```bash
# 验证 Docker Hub 镜像的三个 badge（任一通过即可免除源码关联）
check_dockerhub_badge() {
    local repo="$1"
    local url="https://hub.docker.com/r/$repo"
    local html

    html=$(curl -sL "$url")


    if echo "$html" | grep -q 'aria-label="Verified Publisher"'; then
        echo "Verified Publisher"
    elif echo "$html" | grep -q 'aria-label="Sponsored OSS"'; then
        echo "Sponsored OSS"
    elif echo "$html" | grep -q 'aria-label="Docker Official Image"'; then
        echo "Official Image"
    fi
}

# 使用示例
check_dockerhub_badge "<namespace>/<repo>"
```

### ⚠️ ghcr.io 镜像验证

对于 ghcr.io 镜像，需要验证对应的 GitHub 仓库是否官方使用 ghcr.io 托管镜像：

```bash
# 从 ghcr.io/owner/repo 提取 owner 和 repo
ghcr.io/telepresenceio/telepresence -> owner: telepresenceio, repo: telepresence

# 验证方法1: 检查 GitHub 仓库是否有 Docker 相关文件
gh api repos/<owner>/<repo>/contents --jq '.[].name' | grep -iE "(docker|image)"

# 验证方法2: 检查仓库的 releases 或 packages 是否使用 ghcr.io
gh api repos/<owner>/<repo>/releases --jq '.[].assets[].browser_download_url' 2>/dev/null | grep "ghcr.io"

# 验证方法3: 检查 README 中是否提到 ghcr.io 镜像
curl -sL "https://raw.githubusercontent.com/<owner>/<repo>/main/README.md" | grep -i "ghcr.io"

# 验证方法4: 检查 GitHub Packages
gh api users/<owner>/packages --jq '.[].name' 2>/dev/null
```

**示例**：验证 `ghcr.io/telepresenceio/*`

```bash
# 获取组织下所有仓库
gh api orgs/telepresenceio/repos --jq '.[].full_name'

# 检查主要仓库是否使用 ghcr.io
gh api repos/telepresenceio/telepresence --jq '.stargazers_count'  # star > 10

# 检查是否有 Docker 相关文件
gh api repos/telepresenceio/telepresence/contents --jq '.[].name' | grep -i docker
```

### ⚠️ 整个组织申请验证

申请整个组织时，需要验证该组织下所有镜像都符合要求：

```bash
# 获取该组织的所有仓库
gh api orgs/<org>/repos --jq '.[].full_name'

# 逐个验证每个仓库的 star 和镜像关联
```

### ⚠️ 重要：必须基于申请人提供的信息审批

> ⚠️ **教训**：申请人未提供源码信息时，不能主动去 GitHub 搜索来"弥补"申请材料的缺失。

**不要主动帮申请人"找"证明材料！**

- 申请人提供了源码地址 → 验证关联
- 申请人没提供 → 要求补充，不能自己去找

### ⚠️ 验证失败的处理

三种 badge 验证都失败时，视为普通镜像，**需要源码关联证明**：

| 验证结果 | 处理 |
| -------- | ------ |
| 任意 badge 通过 | 免除源码关联 |
| 全部失败 | 要求补充源码信息 |

### ⚠️ GitHub star vs Docker Hub star

> ⚠️ **教训**：以 GitHub star 为准（源码平台更权威），Docker Hub star 仅作为辅助参考。

- **以 GitHub star 为准**，GitHub 是源码平台更权威
- Docker Hub star 仅作为辅助参考

### ❌ 驳回原因

| 驳回原因             | 说明                           |
| -------------------- | ------------------------------ |
| 申请人未提供源码信息 | 缺少项目源码地址或镜像关联证明 |
| 仅构建产物无源码     | 没有源代码的发布产物           |
| 非开源项目           | 非正当的开源项目               |
| star ≤ 10            | 项目热度过低                   |
| 违规内容             | 涉及魔法/科学上网/盗版等       |

## 白名单通配符规则

| 模式     | 含义                     | 示例                                                          |
| -------- | ------------------------ | ------------------------------------------------------------- |
| `*`      | 匹配任意字符（不含斜杠） | `docker.io/alpine/*` 匹配 `docker.io/alpine/latest`           |
| `**`     | 匹配任意字符（含斜杠）   | `docker.io/alpinelinux/**` 匹配 `docker.io/alpinelinux/v3/18` |
| 无通配符 | 精确匹配                 | `docker.io/nginx/nginx-unprivileged`                          |

## 审批流程

### 第一步：获取待审批列表

```bash
gh issue list --repo DaoCloud/public-image-mirror --label "allows image" --state open
```

### 第二步：逐个验证

```bash
# 申请详情
gh issue view <issue_number> --repo DaoCloud/public-image-mirror

# 检查白名单是否已存在
gh api repos/DaoCloud/public-image-mirror/contents/allows.txt --jq '.download_url' | xargs curl -sL | grep -iE "^docker.io/namespace/repo$"

# GitHub star
gh api repos/<owner>/<repo> --jq '.stargazers_count'

# Docker Hub badge 验证（使用 check_dockerhub_badge 函数）
check_dockerhub_badge "<namespace>/<repo>"

# ghcr.io 镜像额外验证（需要验证 GitHub 仓库是否官方使用 ghcr.io）
# 见上文 "ghcr.io 镜像验证" 部分
```

### 第三步：决策

| 情况       | 决定                      |
| ---------- | ------------------------- |
| 符合标准   | ✅ 通过 → 提交 PR          |
| 已在白名单 | ⚠️ 告知已存在 → Issue 回复 |
| 信息缺失   | ⚠️ 要求补充 → Issue 回复   |
| 不符合标准 | ❌ 驳回 → Issue 回复       |

> ⚠️ **重要**：通过的 Issue 不要关闭！由 PR 合并后自动关联关闭。

## 提交 PR 流程

### 0. 进入工作目录

```bash
cd public-image-mirror
```

### 1. 创建分支并修改

```bash
git checkout -b allows/<issue_numbers>
# 编辑 allows.txt 追加到尾部, 并执行下面的格式化
```

### 2. 格式化并提交

> ⚠️ **教训**：确保 diff 只有新增的行，避免包含旧的 commits。

```bash
# 格式化 allows.txt
./hack/fmt-image-match.sh allows.txt

# 验证 diff 只有新增的行
git diff --stat  # 应该是 "allows.txt | 3 +++"

# 提交
git add allows.txt && git commit -m "Allow: add <镜像1>, <镜像2> to allows.txt (Fixed #<issue1>, #<issue2>)"
```

### 3. 推送并创建 PR

```bash
git push -u gh allows/<issue_numbers> -q

gh pr create --repo DaoCloud/public-image-mirror \
  --title "Allow: add <镜像> to allows.txt" \
  --body "Fixed #<issue1>
Fixed #<issue2>

/auto-cc
"
```

## Issue 回复模板

### ✅ 通过

> ⚠️ **注意**：不要使用 /close，由 PR 合并后自动关闭

```markdown
## 审批结果：通过

**镜像**: *docker.io/<namespace>/<repo>*

**验证通过**:
- ✅ 开源项目，有源码
- ✅ GitHub star > 10
- ✅ 镜像与源码有关联

已提交 PR: <PR链接>
```

### ✅ 通过（Verified Publisher/Sponsored OSS/Official Image）

> ⚠️ **注意**：不要使用 /close，由 PR 合并后自动关闭

```markdown
## 审批结果：通过

**镜像**: *docker.io/<namespace>/<repo>*

**验证通过**:
- ✅ Docker Hub <badge类型>（已验证）
- ✅ GitHub star > 10

已提交 PR: <PR链接>
```

### ✅ 通过（ghcr.io 镜像）

> ⚠️ **注意**：不要使用 /close，由 PR 合并后自动关闭

```markdown
## 审批结果：通过

**镜像**: _ghcr.io/<owner>/*_

**验证通过**:
- ✅ GitHub star > 10
- ✅ 官方使用 ghcr.io 托管镜像（已验证）
- ✅ <owner> 是知名开源项目

已提交 PR: <PR链接>
```

### ⚠️ 已存在

```markdown
## 审批结果：已存在

**镜像**: _docker.io/<namespace>/<repo>_

白名单已存在

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

### ❌ 驳回（Verified Publisher 声明不实）

```markdown
## 审批结果：驳回

**镜像**: _docker.io/<namespace>/<repo>_

**驳回原因**:
- ❌ 申请人声称是 Verified Publisher，但实际验证未通过
- ⚠️ 请提供镜像与源码的关联证明

/close
```

### ❌ 驳回

```markdown
## 审批结果：驳回

**驳回原因**:
- 项目 star ≤ 10 / 违规内容 / 仅构建产物等

/close
```

### ⚠️ 重复

```markdown
与 #<original_issue> 重复，已并入审批

/close
```

## 参考链接

- 仓库: https://github.com/DaoCloud/public-image-mirror
- 白名单规则: https://github.com/DaoCloud/public-image-mirror/issues/2328
- PR 示例: https://github.com/DaoCloud/public-image-mirror/pull/23762
