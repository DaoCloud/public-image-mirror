
FROM m.daocloud.io/ghcr.io/wzshiming/machinespirit:latest

RUN --mount=type=cache,target=/var/cache/apk \
    apk add github-cli jq

# RUN mkdir -p ~/.agents/skills/gh-cli/ && \
#     wget -O ~/.agents/skills/gh-cli/SKILL.md https://files.m.daocloud.io/github.com/github/awesome-copilot/raw/refs/heads/main/skills/gh-cli/SKILL.md

WORKDIR /workdir

COPY .agents/skills/public-image-mirror-approver /root/.agents/skills/public-image-mirror-approver
COPY *.md .
COPY entrypoint.sh .

ENTRYPOINT ["/workdir/entrypoint.sh"]
