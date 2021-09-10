#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

cat ./mirror.txt | while read line; do
  line="${line// /}"
  if [[ "${line}" == "#"* ]] || [[ "${line}" == "" ]]; then
    continue
  fi

  host="${line%%/*}"
  image="${line#*/}"
  workflow=".github/workflows/mirror-${host//./-}-${image//\//-}.yml"

  cat <<EOF >"${workflow}"
name: "Sync ${host}/${image}"
on:
  workflow_dispatch:
  schedule:
    - cron: "0 0 * * *"

jobs:
  sync-image:
    runs-on: ubuntu-latest
    steps:
    - name: Sync
      env:
        CREDS: "\${{ secrets.CREDS }}"
        MIRROR: "\${{ secrets.MIRROR }}"
      run: |
        docker run --rm -it ananace/skopeo \\
          sync --src docker --dest docker --dest-tls-verify=false --dest-creds "\${CREDS}" -f oci \\
          "${host}/${image}" "\${MIRROR}/${image}"

EOF

done
