# 提交 PR 指南

## 准备仓库

检查用户是否已经登入, 提示用户 登录 `gh auth login`，并执行以下初始化：
```bash
gh auth status
```

```bash
gh repo fork DaoCloud/public-image-mirror --clone=true
cd public-image-mirror
```

## 编辑 allows.txt

```bash
git checkout -b allows/<分支名>
echo "<镜像地址>" >> allows.txt
./hack/fmt-image-match.sh allows.txt
```

> `git diff` 无输出 → 已被已有规则覆盖，无需提交（无需继续下面的提交步骤）。

## 提交 PR

``` bash
git add allows.txt && git commit -m "<提交信息>"
git push -u origin allows/<image-name-or-issue-number>
gh pr create \
  --repo DaoCloud/public-image-mirror \
  --title "<PR标题>" \
  --body '<PR正文>'
```

## 通配符规则

| 模式 | 含义 | 示例 |
| --- | --- | --- |
| `*` | 匹配任意字符（不含 `/`） | `docker.io/alpine/*` |
| `**` | 匹配任意字符（含 `/`） | `docker.io/alpinelinux/**` |
| 无通配符 | 精确匹配 | `docker.io/nginx/nginx-unprivileged` |

## 白名单审批规则

### ✅ 通过标准（全部满足）

1. 开源项目（有源码，非仅编译产物）
2. GitHub star > 10
3. 镜像与源码有实际关联（文档/官方推荐）
4. 无违规内容（禁止盗版/魔法/科学上网）

### ⚠️ Docker Hub 免除源码关联

Docker Hub Verified Publisher / Sponsored OSS / Official Image
