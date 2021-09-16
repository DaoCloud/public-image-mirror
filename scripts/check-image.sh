#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

DEBUG="${DEBUG:-}"
INCREMENTAL="${INCREMENTAL:-}"
QUICKLY="${QUICKLY:-}"
PARALLET="${PARALLET:-0}"

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

declare -A EXCLUDED_MAP=()

for line in $(cat not_sync.yaml | yq -j '.not_sync[] | .image_pattern , "=", (.tag_patterns[] | . , "|" ) , "\n"' | sed "s/|$//g"); do
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

    EXCLUDED_MAP["${key}"]="${val}"
done

LOGFILE="./check-image.log"
echo >"${LOGFILE}"

count=0
images="$(cat ./mirror.txt | tr -d ' ' | grep -v -E '^$' | grep -v -E '^#' | shuf)"
images_count=$(echo "${images}" | wc -l | tr -d ' ')
for line in ${images}; do
    line="${line/ /}"
    if [[ "$line" == "" ]]; then
        continue
    fi

    exclude=""
    for key in "${!EXCLUDED_MAP[@]}"; do
        if [[ "${line}" =~ ${key} ]]; then
            exclude+="${EXCLUDED_MAP[$key]}|"
        fi
    done
    exclude="${exclude%|}"

    domain="${line%%/*}"
    new_image=$(echo "${line}" | sed "s/^${domain}/${DOMAIN_MAP["${domain}"]}/g")
    count=$((count + 1))
    echo "Diff ${count}/${images_count} image ${line} ${new_image}"
    DEBUG="${DEBUG}" QUICKLY="${QUICKLY}" INCREMENTAL="${INCREMENTAL}" PARALLET="${PARALLET}" EXCLUDED="${exclude}" ./scripts/diff-image.sh "${line}" "${new_image}" 2>&1 | tee -a "${LOGFILE}" || {
        echo "Error: diff image ${line} ${new_image}"
    }
done

cat "${LOGFILE}" | grep " UNSYNC: " | sort >sync.log
cat "${LOGFILE}" | grep " SYNC: " | sort >>sync.log

sync="$(cat "${LOGFILE}" | grep " SYNC: " | wc -l | tr -d ' ' || :)"
unsync="$(cat "${LOGFILE}" | grep " UNSYNC: " | wc -l | tr -d ' ' || :)"
sum=$(($sync + $unsync))

if [[ "${QUICKLY}" == "true" ]]; then
    echo "https://img.shields.io/badge/Sync-${sync}%2F${sum}-blue"
    wget "https://img.shields.io/badge/Sync-${sync}%2F${sum}-blue" -O badge.svg
else
    echo "https://img.shields.io/badge/Deep%20Sync-${sync}%2F${sum}-blue"
    wget "https://img.shields.io/badge/Deep%20Sync-${sync}%2F${sum}-blue" -O badge.svg
fi
