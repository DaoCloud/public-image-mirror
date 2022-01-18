#!/usr/bin/env bash

patch_url=$1

file=mirror.txt

cp "${file}" "${file}.bak"

git apply -R <(curl -fsSL "${patch_url}")

list=$(diff --unified "${file}" "${file}.bak" | grep -e '^+\w' | sed 's/^+//')

for image in ${list}; do
    skopeo inspect --raw "docker://${image}" || { echo "Not Found ${image}" ; exit 1; }
done
