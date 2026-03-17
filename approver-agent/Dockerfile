
FROM m.daocloud.io/ghcr.io/wzshiming/machinespirit/ms:v0.0.1

RUN --mount=type=cache,target=/var/cache/apk \
    sed -i 's|https://dl-cdn.alpinelinux.org/|https://files.m.daocloud.io/dl-cdn.alpinelinux.org/|g' /etc/apk/repositories && \
    apk add github-cli bash curl git

RUN mkdir -p ~/.agents/skills/gh-cli/ && \
    wget -O ~/.agents/skills/gh-cli/SKILL.md https://files.m.daocloud.io/github.com/github/awesome-copilot/raw/refs/heads/main/skills/gh-cli/SKILL.md

WORKDIR /workdir

COPY .agents .
COPY *.md .
