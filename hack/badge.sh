#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

QUICKLY="${QUICKLY:-}"
cat *"_sync.log" > "sync.log"
sync="$(cat "sync.log" | grep " SYNCHRONIZED: " | wc -l | tr -d ' ' || :)"
unsync="$(cat "sync.log" | grep " NOT-SYNCHRONIZED: " | wc -l | tr -d ' ' || :)"
sum=$(($sync + $unsync))

if [[ "${sum}" -eq 0 ]]; then
    echo "No sync"
    exit 1    
fi

if [[ "${QUICKLY}" == "true" ]]; then
    echo "https://img.shields.io/badge/Sync-${sync}%2F${sum}-blue"
    wget "https://img.shields.io/badge/Sync-${sync}%2F${sum}-blue" -O badge.svg
else
    echo "https://img.shields.io/badge/Deep%20Sync-${sync}%2F${sum}-blue"
    wget "https://img.shields.io/badge/Deep%20Sync-${sync}%2F${sum}-blue" -O badge.svg
fi
