#!/usr/bin/env bash

function guess_image() {
    local image="${1}"

    image="${image// /}"
    image="${image#\/}"
    image="${image%\/}"

    if [[ -z "${image}" ]]; then
        return
    fi

    if [[ "${image}" == *"registry.hub.docker.com/r/"* ]]; then
        image="docker.io/${image##*registry.hub.docker.com\/r\/}"
    fi
    if [[ "${image}" == *"hub.docker.com/r/"* ]]; then
        image="docker.io/${image##*hub.docker.com\/r\/}"
    fi
    if [[ "${image}" != *"/"* ]]; then
        image="library/${image}"
    fi
    if [[ "${image%%/*}" != *"."* ]]; then
        image="docker.io/${image}"
    fi
    if [[ "${image}" != *":"* ]]; then
        image="${image}:latest"
    fi
    if [[ "${image}" == *"//"* ]] || [[ "${image}" == *" "* ]]; then
        return
    fi

    echo "${image}"
}

guess_image "${1}"
