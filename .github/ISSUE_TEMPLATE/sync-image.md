---
name: SYNC IMAGE
about: 主动同步指定镜像
title: SYNC IMAGE
labels: ''
assignees: ''

---

SYNC docker.io/library/busybox:latest

<!--
Modify the above by changing `docker.io/library/busybox:latest` to the image you want to synchronize with.
请修改上面的内容，将 `docker.io/library/busybox:latest` 改为你要同步的镜像

NOTE, don't change the title!
注意, 标题不要改哦

Alternatively, you can trigger the synchronization directly with the command
或者可以直接使用命令触发同步
``` bash
gh -R DaoCloud/public-image-mirror issue create \
  --title "SYNC IMAGE" \
  --body "SYNC docker.io/library/busybox:latest"
```
-->
