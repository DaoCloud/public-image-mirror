#!/usr/bin/env bash

file=$1

patch_url=$2

list=""
if [[ "${patch_url}" == "" ]]; then
    list=$(cat "${file}")
else 
    cp "${file}" "${file}.bak"
    git apply -R <(curl -fsSL "${patch_url}") || :
    list=$(diff --unified "${file}" "${file}.bak" | grep '^+\w' | sed 's/^+//' || :)
fi

failed=()
for image in ${list}; do
    image="${image##:*}"
    echo "Checking image: ${image}"
    raw=$(skopeo list-tags --no-creds --tls-verify=false --retry-times 3 "docker://${image}")
    if [[ $? -ne 0 ]]; then
        failed+=("not found ${image}")
        echo "Not found ${image}"
        continue
    fi
    if [[ $(echo "${raw}" | jq '.Tags | length') -eq 0 ]]; then
        failed+=("found ${image} but no tags")
        echo "Found ${image} but no tags"
        echo "${raw}"
        continue
    fi
done

if [[ ${#failed[@]} -ne 0 ]]; then
    echo "Failed images:"
    for image in "${failed[@]}"; do
        echo "  ${image}"
    done
    exit 1
fi
