#!/bin/sh
git config --global user.name "$(gh api user --jq '.name // "zsmbot"')" && \
git config --global user.email "$(gh api user --jq '.email // "users+noreply@github.com"')"

# 使用 gh fork, 如果已 fork 则继续
gh repo fork DaoCloud/public-image-mirror --clone=false --remote=true

# 获取你的用户名
MY_GITHUB_USER=$(gh api user --jq '.login')

# 同步 fork 与上游
gh repo sync --force $MY_GITHUB_USER/public-image-mirror

gh repo clone $MY_GITHUB_USER/public-image-mirror -- -o gh

cd public-image-mirror

# *非常重要*：切换为 GH_TOKEN 认证 (替换 remote URL)
git remote set-url gh https://$GH_TOKEN@github.com/$MY_GITHUB_USER/public-image-mirror.git

# 添加 upstream remote
git remote add upstream https://github.com/DaoCloud/public-image-mirror.git 2>/dev/null || true

# 同步本地 main 与上游（避免 PR 包含多余 commits）
git fetch -q gh
git checkout main
git reset --hard gh/main

echo "Environment ready. Local main synchronized with upstream."
