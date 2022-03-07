#!/usr/bin/env bash

file=$1

patch_url=$2

cp "${file}" "${file}.bak"

git apply -R <(curl -fsSL "${patch_url}") || :

list=$(diff --unified "${file}" "${file}.bak" | grep '^+\w' | sed 's/^+//' || :)

for image in ${list}; do
    echo "Checking image: ${image}"
    skopeo list-tags --retry-times 3 "docker://${image}" || { echo "Not Found ${image}" ; exit 1; }
done
