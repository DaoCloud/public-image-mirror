# 白名单审批

提交 PR 流程 [pr.md](pr.md)

## 审批专属原则

- **必须验证**：不能仅依赖申请人声明
- **不要主动帮申请人"找"证明材料**：没提供 → 要求补充
- **以 GitHub star 为准**：Docker Hub star 仅辅助参考
- **通过的 Issue 不要关闭**：由 PR 合并后自动关闭

## 验证工具

### Docker Hub Badge 验证

```bash
check_dockerhub_badge() {
    local html; html=$(curl -sL "https://hub.docker.com/r/$1")
    echo "$html" | grep -q 'aria-label="Verified Publisher"' && echo "Verified Publisher" && return
    echo "$html" | grep -q 'aria-label="Sponsored OSS"' && echo "Sponsored OSS" && return
    echo "$html" | grep -q 'aria-label="Docker Official Image"' && echo "Official Image"
}
```

### 镜像 和 github 仓库关联验证

```bash
gh search code "<image name>" --repo <owner>/<repo> -L 10
```

## 审批流程

### 1. 获取待审批列表

```bash
gh issue list --repo DaoCloud/public-image-mirror --label "allows image" --state open
```

### 2. 逐个验证

```bash
gh issue view <issue_number> --repo DaoCloud/public-image-mirror
gh api repos/<owner>/<repo> --jq '.stargazers_count'
check_dockerhub_badge "<namespace>/<repo>"
```

### 3. 决策

| 情况 | 动作 |
| --- | --- |
| 符合标准 | ✅ 通过 → 提交 PR |
| 已在白名单 | ⚠️ 回复已存在 |
| 信息缺失 | ⚠️ 要求补充 |
| 不符合标准 | ❌ 驳回 |

## PR 正文模板

```markdown
Fixed #<issue_number>

/auto-cc
```

## Issue 回复模板

### ✅ 通过

```markdown
## 审批结果：通过

**镜像**: *docker.io/<namespace>/<repo>*
**验证通过**: ✅ 开源项目, ✅ GitHub star > 10, ✅ 镜像与源码有关联
已提交 PR: <PR链接>
```

### ✅ 通过（Badge 免除）

```markdown
## 审批结果：通过

**镜像**: *docker.io/<namespace>/<repo>*
**验证通过**: ✅ Docker Hub <badge类型>, ✅ GitHub star > 10
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

**缺少**: ❌ 项目源码地址 / ❌ 镜像关联证明
**请补充**: 提供源码地址及文档链接，再新开 Issue
/close
```

### ❌ 驳回

```markdown
## 审批结果：驳回

**驳回原因**: ❌ <具体原因>
/close
```
