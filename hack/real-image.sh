#!/usr/bin/env bash

function guess_image() {
    local image="${1}"

    if [[ -z "${image}" ]]; then
        return
    fi

    if [[ "${image}" =~ ^"docker.io/"* ]]; then
        image="registry-1.${image}"
    fi

    if [[ "${image}" =~ ^"registry-1.docker.io/"[^/]+$ ]]; then
        image="registry-1.docker.io/library/${image#*/}"
    fi

    echo "${image}"
}

guess_image "${1}"
