#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

declare -A DOMAIN_MAP=()

for line in $(cat ./domain.txt); do
    line="${line/ /}"
    if [[ "$line" == "" ]]; then
        continue
    fi
    key="${line%%=*}"
    val="${line##*=}"
    if [[ "${key}" == "" || "${val}" == "" ]]; then
        echo "Error: invalid line: ${line}"
        continue
    fi

    DOMAIN_MAP["${key}"]="${val}"
done

for line in $(cat ./mirror.txt); do
    line="${line/ /}"
    if [[ "$line" == "" ]]; then
        continue
    fi

    domain="${line%%/*}"
    new_image=$(echo "${line}" | sed "s/^${domain}/${DOMAIN_MAP["${domain}"]}/g")
    echo "Diff image ${line} ${new_image}"
    DEBUG=true INCREMENTAL=true ./scripts/diff-image.sh "${line}" "${new_image}" || {
        echo "Error: diff image ${line} ${new_image}"
    }
done
